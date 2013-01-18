function view = rmRecomputeFit(view,params)
% rmRecomputeFit - recompute variance explained and beta 
% 
% view = rmRecomputeFit(view,params)
%
% Recompute fit to adjust for variance explained and beta values that may
% be off because they were (1) interpolated (2) not included in further
% fits.
%
% 2008/02 SOD: wrote it.


if ~exist('view','var') || isempty(view),   
    error('Need view struct'); 
end;
if ~exist('params','var') || isempty(params),
    % See first if they are stored in the view struct
    params = viewGet(view,'rmParams');
    % if not loaded load them:
    if isempty(params),
        view = rmLoadParameters(view);
        params = viewGet(view,'rmParams');
    end;
end;


% get rmFile. This is the model definition
try
    rmFile = viewGet(view,'rmFile');
catch %#ok<CTCH>
    fprintf('[%s]:No file selected',mfilename);
    view = rmSelect(view);
    rmFile = viewGet(view,'rmFile');
end;
% save rmFile so we know which file was used. we do this by growing the
% variable:
params.matFileName = {rmFile params.matFileName{:}};
tmp = load(rmFile);
model = tmp.model;


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
                    catch %#ok<CTCH>
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
%--- make trends to fit with the model (dc, linear and sinewaves)
%-----------------------------------
[trends, nTrends, dcid] = rmMakeTrends(params);


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


% go loop over slices
for slice=loopSlices,

    %-----------------------------------
    % now we extract only the data from that slice and put it in a
    % temporary structure that will be modified throughout.
    %-----------------------------------
    s = rmSliceGet(model,slice);
    
    % We take the predefined model and remake the params. They can
    % give problems if the 'betas' are different. This may be because
    % there is different amount of detrending and/or different amount
    % of data-sets were used. Anyway, we need to make sure that the
    % amount of 'betas' are set to the current conditions.
    % This means we may have to add more trends to the data:
    for n=1:numel(params.analysis.pRFmodel)
        switch lower(params.analysis.pRFmodel{n}),
            case {'onegaussian','one gaussian','default'}
                if nTrends+1 > size(s{n}.b,1),
                    sz = size(s{n}.b,1);
                    s{n}.b(sz+1:nTrends+1,:) = 0;
                    % or we may have to remove some betas from the model data-set:
                elseif nTrends+1 < size(s{n}.b,1),
                    s{n}.b = s{n}.b(1:nTrends+1,:);
                end;

            case {'twogaussiansdog','dog','difference of gaussians',...
                    'twogaussiansposonly','two gaussians','two prfs'}
                if nTrends+2 > size(s{n}.b,1),
                    sz = size(s{n}.b,1);
                    s{n}.b(sz+1:nTrends+2,:) = 0;
                elseif nTrends+2 < size(s{n}.b,1),
                    s{n}.b = s{n}.b(1:nTrends+2,:);
                end;

            otherwise
                fprintf('Unknown pRF model: %s: IGNORED!',params.analysis.pRFmodel{n});
        end
    end
    
    % The fitting uses fmincon which can only use type double (not single)
    % so convert model struct to double
    for n=1:numel(s),
        f=fieldnames(s{n});
        for n2=1:numel(f),
            if isnumeric(s{n}.(f{n2}))
                s{n}.(f{n2}) = double(s{n}.(f{n2}));
            end
        end
    end
    
    %-----------------------------------
    % Find voxels (voxel>vethresh AND in ROI) that will be
    % processed. 
    %-----------------------------------
    warning('off','MATLAB:divideByZero');
    varexp   = 1-s{1}.rss./s{1}.rawrss;
    warning('off','MATLAB:divideByZero');
    if isempty(ROIcoords),
        wProcess = find(varexp>=vethresh);
    else
        allcoords = viewGet(view,'coords');
        [tmp, wProcess] = intersectCols(allcoords,ROIcoords);
        wProcess = wProcess(varexp(wProcess)>=vethresh);
    end;

    %-----------------------------------
    % Place datasets behind each other. This is a rather crude way of
    % stimultaneously fitting both. Due to this we cannot
    % prewhiten (we could zeropadd/let the trends deal with this/not care).
    %-----------------------------------
    data     = rmLoadData(view,params,slice);
    data     = single(data);
    % detrend
    trendBetas = pinv(single(trends))*data;
    data       = data - trends*trendBetas;
    
    % put in number of data points. Right now this is the same as
    % size(data,1)
    for mm = 1:numel(model),
        model{mm} = rmSet(model{mm},'npoints',size(data,1));
    end;
   

    % store rawrss: this may be different from the one already there because
    % of the coarse-to-fine approach (i.e. smoothing). Please note that this
    % rawrss is the rss of the raw timeseries with the trends removed (i.e.
    % high-pass filtered.
    for n=1:numel(s),
        s{n}.rawrss(wProcess) = sum(double(data).^2);
    end;

 
    
    %-----------------------------------
    % Go for each voxel
    %-----------------------------------
    for n=1:numel(params.analysis.pRFmodel)
        switch lower(params.analysis.pRFmodel{n}),
            case {'onegaussian','one gaussian','default'}
                denom = -2.*(s{n}.s.^2);
                t = trends(:,dcid);
                for ii = 1:size(data,2),
                    vData=data(:,ii);
                    % make RF, prediction and get rss,b
                    Xv = params.analysis.X-s{n}.x0(ii);
                    Yv = params.analysis.Y-s{n}.y0(ii);
                    rf = exp( (Yv.*Yv + Xv.*Xv) ./ denom(ii) );
                    X  = [params.analysis.allstimimages*rf t];
                    b  = pinv(X)*vData;
                    b(1)  = max(b(1),0);  
                    rss  = norm(vData-X*b).^2;
                    % store
                    s{n}.rss(ii)  = rss;
                    s{n}.b([1 dcid+1],ii)  = b;
                end

            case {'twogaussiansdog','dog','difference of gaussians'}
                s{n}=rmSearchFit_twoGaussiansDoG(s{n},data,params,wProcess);

            case {'twogaussiansposonly','two gaussians','two prfs'}
                s{n}=rmSearchFit_twoGaussiansPosOnly(s{n},data,params,wProcess);

            otherwise
                fprintf('Unknown pRF model: %s: IGNORED!',params.analysis.pRFmodel{n});
        end
    end


    %-----------------------------------
    % now put back the trends to the fits
    %-----------------------------------
    for mm=1:numel(s),
        nB = size(s{mm}.b,1)-nTrends+1;
        s{mm}.b(nB:end,:) = s{mm}.b(nB:end,:)+trendBetas;
    end

    %-----------------------------------
    % now we put back the temporary data from that slice
    %-----------------------------------
    model = rmSliceSet(model,s,slice);
end;

%-----------------------------------
% save
%-----------------------------------
for n=1:numel(model),
    model{n} = rmSet(model{n},'coords',[]);
end;
output = rmSave(view,model,params,1,'recomp');
view   = viewSet(view,'rmFile',output);

% that's it
return;
%-----------------------------------


