function view=rmSearchFit_sigmaOnly(view,params,matFileName,sigmaExtend);
% rmSearchFit_sigmaOnly - find minimum for retinotopic model per voxel
%
% model=rmSearchFit(view,params,matFileName,sigmaExtend);
%
% Refine sigma estimate over range originalsigma*sigmaExtend
%
% sigmaExtend defaults to [1./3 3];
%
% 2006/04 SOD: wrote it.
% 2006/12 SOD: further optimizations fminsearch->fmincon

% Programming notes:
% This will probably only work for data in 'Gray'-view.

%-----------------------------------
%--- input handling
%-----------------------------------
if ieNotDefined('view'),   error('Need view struct'); end;
if ieNotDefined('params'),
    % See first if they are stored in the view struct
    params = viewGet(view,'rmParams');
    % if not loaded load them:
    if isempty(params),
        view = rmLoadParameters(view);
        params = viewGet(view,'rmParams');
    end;
end;
if ieNotDefined('sigmaExtend'),   sigmaExtend = [1./3 3]; end;

% get rmFile. This is the model definition that will start as a
% starting point for our search.
try,
    rmFile = viewGet(view,'rmFile');
catch,
    disp(sprintf('[%s]:No file selected',mfilename));
    view = rmSelect(view);
    rmFile = viewGet(view,'rmFile');
end;

% Load previous model, but not params since these are allowed to be
% redefined every time. It is the model that is transferable
% between every scan of the same subject but not the exact
% parameters.
% actually we are going to load it so we can use the "grid" to confine our
% nonlinear minimization.
tmp = load(rmFile);
model = tmp.model;

% lastly we need to define the output file name
if ieNotDefined('matFileName'),
    if ieNotDefined('params.matFileName'),
        params.matFileName = ['retModel-',datestr(now,'yyyymmdd'),'-sFit.mat'];
        % else, use existing params.matFileName
    end;
else,
    params.matFileName = matFileName;
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
                    try,
                        view   = loadROI(view,filename);
                    catch
                        view   = loadROI(view,filename);
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
%--- make trends to fit with the model (dc, linear and sinewaves)
%-----------------------------------
[trends nTrends] = rmMakeTrends(params);


%-----------------------------------
%--- now loop over slices
%--- but initiate stuff first
%-----------------------------------
switch lower(params.wData),
    case {'fig','roi'},
        loopSlices = 1;
    otherwise,
        % ras 07/07: now uses a separate analysis param, instead of stim
        % param:
        loopSlices = 1:params.analysis.nSlices;

end;
numSlices    = length(loopSlices);

%--- parameters for search fit (fminsearch)
% t-threshold above which to do search. This limit's the search
% algorithms to voxels that will have 'good' data.
params.analysis.fmins.tthresh = 4.42; %p=1e-5; 3.3 = p = 1e-3 (uncorrected)

% display iterations?
params.analysis.fmins.Display = 'none';%'none','iter','final'

% maximum iterations:
params.analysis.fmins.MaxIter = 50;

% Precision of output (degrees). That is, stop if the estimate is
% within TolX degrees:
params.analysis.fmins.TolX    = 1e-2; % degrees

% Precision of evaluation function. We define RMS improvement
% relative to the initial raw 'no-fit' data RMS. So, 1 means
% stop if there is less than 1% improvement on the fit:
params.analysis.fmins.TolFun  = 1e-2; % percent


% fminsearch options
searchOptions.TolX    = params.analysis.fmins.TolX;
searchOptions.MaxIter = params.analysis.fmins.MaxIter;
searchOptions.Display = params.analysis.fmins.Display;
searchOptions.tolFun  = params.analysis.fmins.TolFun;
tthresh       = params.analysis.fmins.tthresh;

% for backward compatibility:
if ~exist('params.analysis.relativeGridStep'),
    params.analysis.relativeGridStep = 1;
end;


% give some feedback so we know we are going
if isempty(ROIcoords),
    fprintf(1,'[%s]:Processing voxels with |t| >= %.2f\n',...
        mfilename,tthresh);
else,
    fprintf(1,'[%s]:Processing voxels with |t| >= %.2f in ROI: %s\n',...
        mfilename,tthresh,view.ROIs(view.selectedROI).name);
end;

% go loop over slices
for slice=loopSlices,

    %-----------------------------------
    % Place datasets behind each other. This is a rather crude way of
    % stimultaneously fitting both. Due to this we cannot
    % prewhiten (we could zeropadd/let the trends deal with this/not care).
    %-----------------------------------
    % we get all the data -
    p2 = params;
    p2.wData = 'all';
    [data, p2] = rmLoadData(view,p2,slice);
    %  [data, params] = rmLoadData(view,params,slice);


    %-----------------------------------
    % now we extract only the data from that slice and put it in a
    % temporary structure that will be modified throughout.
    %-----------------------------------
    s = extractSlice(model,slice);
    % We take the predefined model and remake the params. They can
    % give problems if the 'betas' are different. This may be because
    % there is different amount of detrending and/or different amount
    % of data-sets were used. Anyway, we need to make sure that the
    % amount of 'betas' are set to the current conditions.
    % This means we may have to add more trends to the data:
    if nTrends+1 > size(s{1}.b,1),
        sz = size(s{1}.b,1);
        s{1}.b(sz+1:nTrends+1,:) = 0;
        % or we may have to remove some betas from the model data-set:
    elseif nTrends+1 < size(s{1}.b,1),
        s{1}.b = s{1}.b(1:nTrends+1,:);
    end;
    % sometimes the fit return negative values.


    % amount of models
    nModels  = numel(s);
    % and which ones we are processing (positive only)
    idModels = 1:2:nModels;
    % amount of negative fit
    nNegFit  = 0;

    % for double gaussian model if it exists
    if nModels>2,
        if nTrends+2 > size(s{3}.b,1),
            sz = size(s{3}.b,1);
            s{3}.b(sz+1:nTrends+2,:) = 0;
            % or we may have to remove some betas from the model data-set:
        elseif nTrends+2 < size(s{3}.b,1),
            s{3}.b = s{3}.b(1:nTrends+2,:);
        end;
    end;

    % premake contrasts:
    C{1} = zeros(1,nTrends+1);
    C{1}(1) = 1;
    C{2} = zeros(4,nTrends+2);
    C{2}(:,1:2) = [1 1;1 0;0 1;1 -1];

    %-----------------------------------
    % Now find voxels (|voxel|>tthresh AND in ROI) that will be processed
    %-----------------------------------
    if isempty(ROIcoords),
        wProcess = find(abs(s{1}.t)>=tthresh);
    else,
        %wProcess  = zeros(1,size(ROIcoords,2));
        allcoords = viewGet(view,'coords');
        [tmp, wProcess] = intersectCols(allcoords,ROIcoords);
        wProcess = wProcess(find(s{1}.t(wProcess)>=tthresh));
    end;

    %-----------------------------------
    % Go for each voxel
    %-----------------------------------
    progress = 0;tic;
    for ii = 1:numel(wProcess),

        % progress monitor (10 dots)
        if floor(ii./numel(wProcess)*10)>progress,
            % print out estimated time left
            if slice==1 && progress==0,
                esttime = toc.*10.*numSlices;
                if floor(esttime./3600)>0,
                    fprintf(1,'[%s]:Estimated processing time: %d voxels: %d hours.\n',...
                        mfilename,numel(wProcess),ceil(esttime./3600));
                else,
                    fprintf(1,'[%s]:Estimated processing time: %d voxels: %d minutes.\n',...
                        mfilename,numel(wProcess),ceil(esttime./60));
                end;
                fprintf(1,'[%s]:Nonlinear optimization (x,y,sigma):',mfilename);
            end;
            fprintf(1,'.');drawnow;
            progress = progress + 1;
        end;

        % volume index
        vi = wProcess(ii);

        % raw rss value
        rawrss     = norm(data(:,vi)).^2;

        % start point from original fit
        xy          = [s{1}.x(vi);...
            s{1}.y(vi)];
        startParams = [s{1}.s(vi)];


        % tight search region [lowerbound upperbound]
        % gridSigmas==startParams(3), somehow this fails sometimes so we'll
        % look for the closest one.
        bndParams      = startParams*sigmaExtend;

        % actual fitting routine
        outParams = ...
            fmincon(@(x) rmModelSearchFit_oneGaussianSigmaOnly(x,data(:,vi),trends,...
            params.analysis.X,...
            params.analysis.Y,...
            params.analysis.allstimimages,...
            rawrss,xy),...
            startParams,[],[],[],[],bndParams(1),bndParams(2),...
            [],searchOptions);

        % compute t
        pred = rfMakePrediction(params,[outParams(1) outParams(1) 0 ...
            xy(1) xy(2)]);
        [t, tmp, rss, b] = rmGLM(data(:,vi),[pred trends],C{1});

        if b(1)>0,
            % store results only if the first beta is positive, somehow fmincon
            % outputs negative fits. If the fit is negative keep old (grid) fit.
            s{1}.s(vi)    = outParams(1);
            s{1}.t(vi)    = t;
            s{1}.rss(vi)  = rss;
            s{1}.rawrss(vi) = rawrss;
            s{1}.b(:,vi)  = b;
        else,
            %disp('Negative beta!?! - ignoring fit');
            nNegFit = nNegFit + 1;
        end

        %--- now for double Gaussian model:
        if numel(s)>2,
            % start point from grid fit
            startParams = [s{3}.x(vi); ...
                s{3}.y(vi); ...
                s{3}.s(vi);...
                s{3}.s2(vi)];

            % tight search region [lowerbound upperbound]
            bndParams   = [-1 1; -1 1; ...
                0.01 params.analysis.sigmaRatioMaxVal;...
                0.1  params.analysis.sigmaRatioInfVal];
            bndParams(1:2,1:2) = startParams(1:2)*[1 1] + ...
                [-1 1;-1 1].*(params.analysis.relativeGridStep.*startParams(3));


            % actual fitting routine
            outParams = ...
                fmincon(@(x) rmModelSearchFit_twoGaussians(x,data(:,vi),trends,...
                params.analysis.X,...
                params.analysis.Y,...
                params.analysis.allstimimages,...
                rawrss),...
                startParams,[],[],[],[],bndParams(:,1),bndParams(:,2),...
                [],searchOptions);
            % compute t
            pred = rfMakePrediction(params,[outParams(3) outParams(3) 0 ...
                outParams(1) outParams(2); ...
                outParams(4) outParams(4) 0 ...
                outParams(1) outParams(2)]);
            [t, tmp, rss, b] = rmGLM(data(:,vi),[pred trends],C{2});

            if b(1)>0 && b(1)+b(2)>0,
                % store results only if the first beta is positive, somehow fmincon
                % outputs negative fits. If the fit is negative keep old (grid) fit.
                s{3}.x(vi)    = outParams(1);
                s{3}.y(vi)    = outParams(2);
                s{3}.s(vi)    = outParams(3);
                s{3}.s2(vi)   = outParams(4);
                s{3}.t(vi)    = t;
                s{3}.rss(vi)  = rss;
                s{3}.b(:,vi)  = b;
            end;
        end;
    end;


    %-----------------------------------
    % now we put back the temporary data from that slice
    %-----------------------------------
    model = putSlice(model,s,slice);

    % end time monitor
    et  = toc;
    if floor(et/3600)>0,
        fprintf(1,'Done [%d hours].\n',ceil(et/3600));
    else,
        fprintf(1,'Done [%d minutes].\n',ceil(et/60));
    end;
    fprintf(1,'[%s]:Removed negative fits: %d (%.1f%%).\n',...
        mfilename,nNegFit,nNegFit./numel(wProcess).*100);
    drawnow;
end;

%-----------------------------------
% save
%-----------------------------------
for n=1:length(model),
    model{n} = rmSet(model{n},'coords',[]);
end;
output = rmSave(view,model,params,1);
view   = viewSet(view,'rmFile',output);

% that's it
return;
%-----------------------------------

%-----------------------------------
function tmp = extractSlice(model,slice);
% some code to extract slice from model struct and place it
% into temporary struct
f = {'x','y','s','rss','t','b','rawrss'};

% loop over models
for n=1:length(model),

    if n==1 || n==2 || n==5, % retinotopy and full field
        f = {'x','y','s','rss','t','rawrss'};
    else,
        if n==3 || n==4,
            f = {'x','y','s','s2','rss','rawrss'};
        else,
            f = {'x','y','s','rss','rawrss'};
        end;
        % put all t values in one matrix
        ts         = {'tall','trm','tf','trmf'};
        tmp{n}.t   = zeros(length(ts),size(val,2));
        for fn = 1:length(ts),
            val            = rmGet(model{n},ts{fn});
            tmp{n}.t(fn,:) = val(slice,:);
        end;
    end;

    % for all models
    tmp{n}.desc = rmGet(model{n},'desc');
    tmp{n}.df   = rmGet(model{n},'dfglm');
    for fn = 1:length(f),
        val    = rmGet(model{n},f{fn});
        if ~isempty(val),
            tmp{n}.(f{fn}) = val(slice,:);
        end;
    end;

    % put all beta values in one matrix
    val      = rmGet(model{n},'b');
    tmp{n}.b = zeros(size(val,3),size(val,2));
    for fn = 1:size(val,3),
        tmp{n}.b(fn,:) = val(slice,:,fn);
    end;
end;

return;
%-----------------------------------

%-----------------------------------
function model = putSlice(model,tmp,slice);
% some code to put slice info into model struct

% loop over models
for n=1:length(model),
    if n<=2, % retinotopy only
        ftmp = {'x','y','s','rss','t','rawrss'};
        fput = {'x','y','s','rss','trm','rawrss'};
        model{n}       = rmSet(model{n},'dfcorr',tmp{n}.df-3); % for x,y,s
    elseif n==5, % full field only
        ftmp = {'x','y','s','rss','t','rawrss'};
        fput = {'x','y','s','rss','tf','rawrss'};
        model{n}       = rmSet(model{n},'dfcorr',tmp{n}.df);
    else, % both
        if n==3 || n==4,
            ftmp = {'x','y','s','s2','rss','rawrss'};
            model{n}       = rmSet(model{n},'dfcorr',tmp{n}.df-4); % for x,y,s,s2
        else,
            ftmp = {'x','y','s','rss','rawrss'};
            model{n}       = rmSet(model{n},'dfcorr',tmp{n}.df-3); % for x,y,s
        end;
        fput = ftmp;

        % distribute t values
        ts  = {'tall','trm','tf','trmf'};
        for fn = 1:4,
            val           = rmGet(model{n},ts{fn});
            val(slice,:)  = tmp{n}.t(fn,:);
            model{n}      = rmSet(model{n},ts{fn},val);
        end;
    end;

    % now get values from model and put in new slice values
    for fn = 1:length(ftmp),
        val             = rmGet(model{n},fput{fn});
        if ~isempty(val),
            val(slice,:)  = tmp{n}.(ftmp{fn});
            model{n}      = rmSet(model{n},fput{fn},val);
        end;
    end;
    model{n}       = rmSet(model{n},'dfglm',tmp{n}.df);

    % distribute beta values
    val      = rmGet(model{n},'b');
    for fn = 1:size(tmp{n}.b,1),
        val(slice,:,fn) = tmp{n}.b(fn,:);
    end;
    model{n} = rmSet(model{n},'b',val);

end;
return;
%-----------------------------------
