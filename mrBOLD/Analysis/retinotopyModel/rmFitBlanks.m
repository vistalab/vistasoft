function view = rmFitBlanks(view,params)
% rmFitBlanks - final fitting stage of (some) retinotopic models
%
% view=rmFitBlanks(view,params);
%
% Add predictors of blanks onsets to existing pRF fit.
%
% Output is saved in structure model, which should be accessed
% through rmSet and rmGet.
%
% 2009/02 SOD & MV: wrote it.

% parameter check
if ~exist('view','var') || isempty(view),   error('Need view struct'); end;
if ~exist('params','var') || isempty(params),
    % See first if they are stored in the view struct
    params = viewGet(view,'rmParams');
    % if not loaded load them:
    if isempty(params),
        view = rmLoadParameters(view);
        params = viewGet(view,'rmParams');
    end;
    % but allow ROI definitions to change
    if view.selectedROI == 0,
        params.wData = 'all';
    else
        params.wData = 'roi';
    end;
end;


% roi check
switch lower(params.wData),
    case {'roi'},

        % if no roi is selected: select one
        if view.selectedROI == 0,
            switch lower(view.viewType),

                case 'inplane',
                    % for inplanes default to gray matter
                    filename = 'gray.mat';
                    try
                        view   = loadROI(view,filename);
                    catch
                        error('[%s]:Cannot load ROI (%s).',mfilename,filename);
                    end;


                otherwise,
                    % otherwise ask
                    filename = getROIfilename(view);
                    view     = loadROI(view,filename);

            end;
        end;
        ROIcoords = view.ROIs(view.selectedROI).coords;

    otherwise,
        ROIcoords = [];
        % do nothing
end;

%-----------------------------------
%--- make blanks predictors
%-----------------------------------
for s = 1:length(params.stim)
    rng = params.stim(s).prescanDuration+1:size(params.stim(s).images_org,2);
    presentedImages  = params.stim(s).images_org(:,rng);
    
    % find blanks: there is no stimulus anywhere (sum=0)
    presentedImages = sum(presentedImages);
    blanksFrames = presentedImages==0;
    blanksOnset  = [0 diff(blanksFrames)];
    blanksOnset  = blanksOnset==1;


    % separate blanks
    ii = find(blanksOnset==1);
    tmp = zeros(sum(blanksOnset),length(blanksOnset));
    for n=1:numel(ii)
        tmp(n,ii(n))=1;
    end
    blanksOnset = tmp';

    % convolve with HRF to get final predications
    blanksOnset = filter(params.analysis.Hrf{s}, 1, blanksOnset);
end

%-----------------------------------
%--- now loop over slices
%--- but initiate stuff first
%-----------------------------------
switch lower(params.wData),
    case {'fig','roi'},
        loopSlices = 1;
    otherwise,
        loopSlices = 1:params.analysis.nSlices;
end;

% get rmFile. This is the model definition that will start as a
% starting point for our search.
try
    rmFile = viewGet(view,'rmFile');
catch
    disp(sprintf('[%s]:No file selected',mfilename));
    view = rmSelect(view);
    rmFile = viewGet(view,'rmFile');
end;

% save rmFile so we know which file was used. we do this by growing the
% variable:
params.matFileName = {rmFile params.matFileName{:}};

% Load previous model, but not params since these are allowed to be
% redefined every time. It is the model that is transferable
% between every scan of the same subject but not the exact
% parameters.
% actually we are going to load it so we can use the "grid" to confine our
% nonlinear minimization.
tmp = load(rmFile);
model = tmp.model;

for n=1:numel(model)
    % extract only the data from that slice
    model = refit_model_with_blanks(model,params,loopSlices,ROIcoords,view,blanksOnset);
end

% save model
output = rmSave(view,model,params,1,'blanksFit');
view   = viewSet(view,'rmFile',output);

return;

%% ------------------------------------------------------------------------
function model = refit_model_with_blanks(model,params,loopSlices,ROIcoords,view,blanksOnset)
% make trends
[trends nt dcid] = rmMakeTrends(params);

% number of blanks
nBlanks = size(blanksOnset,2);

% warning - FIX ME
if numel(model)>1,
    fprintf(1,'\n[%s]:WARNING:Overwriting models!\n\n',mfilename);
end

% duplicate model 1, and don't touch model 1 later!
model{2} = model{1};

% rename
switch lower(rmGet(model{2},'desc'))
    case {'2d prf fit (x,y,sigma, positive only)'}
        model{2} = rmSet(model{2},'desc','2D pRF fit with blank predictor (x,y,sigma, positive only)');
    
    otherwise
        error('Unknown model (%s)',lower(rmGet(model{2},'desc')));
end

% go loop over slices
for slice=loopSlices,
        
    % load data and detrend
    p2 = params; p2.wData = 'all';
    data = rmLoadData(view,p2,slice,false);
    trendBetas       = pinv(trends)*data;
    data             = data - trends*trendBetas;
    rawrss           = single(sum(data.^2));

    % t-values in map
    tmaps = zeros(4,size(data,2));
    
    % Find voxels in ROI that will be processed.
    if isempty(ROIcoords),
        wProcess = 1:size(data,2);
    else
        allcoords = viewGet(view,'coords');
        [tmp, wProcess] = intersectCols(allcoords,ROIcoords);
    end;

    % extract model data
    s = rmSliceGet(model,slice);

    % dc trends
    dc = trends(:,dcid);

    % store new rawrss and reset betas
    s{2}.rawrss = rawrss;
    s{2}.b = zeros(nt+1+nBlanks,size(data,2));

    % dc indices
    tmpdcid = dcid + 1;
    
    %blanks indices
    blanksid = nt+2:nt+1+nBlanks;
    
    % betas
    s{2}.b(2:nt+1,:) = trendBetas;

    % we work with s{2}
    denom1 = -2.*(max(s{2}.s,0.0001).^2);
    fprintf(1,'[%s]:Recomputing...',mfilename);
    %nData   = size(data,1);
    drawnow;tic;
    for ii=wProcess(:)',
        % pRF 1 (original)
        Xv = params.analysis.X-s{2}.x0(ii);
        Yv = params.analysis.Y-s{2}.y0(ii);
        pRF1 = exp( (Yv.*Yv + Xv.*Xv) ./ denom1(ii) );
        pred1 = params.analysis.allstimimages*pRF1;

        % pRF 1 fit  + blanks
        X    = [pred1 dc blanksOnset];
        pinvX = pinv(X);
        b    = pinvX*data(:,ii);
        b(1) = max(b(1),0);

        % compute residuals
        residuals = data(:,ii)-X*b;

        % compute t-val
        C = zeros(nBlanks,size(X,2));
        C(:,end-nBlanks+1:end) = eye(nBlanks);
        RSS  = sum((data(:,ii) - X*b).^2);
        MRSS = RSS./(numel(data(:,ii)) - rank(X));
        SE  = sqrt(diag(C*(pinvX*pinvX')*C')*MRSS);
        tval   = C*b./SE;
        
        % put in structure
        tmaps(:,ii) = tval(:);
        

        % store single pRF fit
        s{2}.rss(ii) = sum(residuals.^2);
        s{2}.b([1 tmpdcid blanksid],ii) = s{2}.b([1 tmpdcid blanksid],ii) + b;

    end;
    fprintf(1, 'Done[%d min].\t(%s)\n', round(toc/60), datestr(now));
    drawnow;
    
    % save tmaps
    for ii=1:4
        pathStr = sprintf('%s-tBlank%d.mat',params.matFileName{1}(1:end-4),ii);
        map{1} = tmaps(ii,:);
        mapUnits = 't';
        [p mapName]=fileparts(pathStr);
        save(pathStr, 'map', 'mapName', 'mapUnits');
        
        pathStr = sprintf('%s-pBlank%d.mat',params.matFileName{1}(1:end-4),ii);
        map{1} = t2p(tmaps(ii,:),[],size(data,1)-1,'log10p');
        mapUnits = '-log10(p)';
        [p mapName]=fileparts(pathStr);
        ssave(pathStr, 'map', 'mapName', 'mapUnits');
    end
    % store
    model = rmSliceSet(model,s,slice);
end

return
%% ------------------------------------------------------------------------



