function view = rmSearchFit(view, params, doDecimate, varargin)
% rmSearchFit - find minimum for retinotopic model per voxel
%
% model = rmSearchFit(view, params, doDecimate, varargin);
%
% Uses matlab nonlinear optimization to refine results.
% Starting point and limits are provided existing retModel file
% (rmGridFit.m).  Output is saved in a new retModel file.
%
%
% 2006/04 SOD: wrote it.
% 2006/12 SOD: further optimizations fminsearch->fmincon
% 2008/01 SOD: broke off separate pRF models

% Programming notes:
% This will probably only work for data in 'Gray'-view.

warning('off','optim:fmincon:SwitchingToMediumScale');

% we really need the optimization toolbox now:
reserveToolbox('optimization');

%-----------------------------------
%--- input handling
%-----------------------------------
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
    end
    % but allow ROI definitions to change
    if view.selectedROI == 0,
        params.wData = 'all';
    else
        params.wData = 'roi';
    end
end
if ~exist('doDecimate','var') || isempty(doDecimate) || doDecimate<2,
    if optimget(params.analysis.fmins.options,'MaxIter')<=0
        stage = 'fFit';
    else
        stage = 'sFit';
    end
    doDecimate = false;
else
    stage = 'sFit-sm';
end

% additional input handling
if nargin > 3,
    addArg = varargin;
    if numel(addArg) == 1,
        addArg=addArg{1};
    end;
else
    addArg = [];
end;

% parse command line inputs:
desc = [];
for n=1:2:numel(addArg),
    data = addArg{n+1};
    fprintf(1,'[%s]:Resetting %s\n',mfilename,addArg{n});
    switch lower(addArg{n}),
        case {'desc'}
            desc = data;
        otherwise
            error('Unknown additional input');
    end
end
            
% for backward compatibility
if ~isfield(params.analysis.fmins,'options')
    params.analysis.fmins.options = optimset('fmincon');
    params.analysis.fmins.options = optimset(params.analysis.fmins.options,...
        'Display',params.analysis.fmins.Display,...
        'MaxIter',params.analysis.fmins.MaxIter,...
        'TolX',params.analysis.fmins.TolX,...
        'TolFun',params.analysis.fmins.TolFun);
end


            
%-----------------------------------
%--- loading data
%-----------------------------------
% get rmFile. This is the model definition that will start as a
% starting point for our search.
try
    rmFile = viewGet(view,'rmFile');
catch %#ok<CTCH>
    fprintf(1,'[%s]:No file selected',mfilename);
    view = rmSelect(view);
    rmFile = viewGet(view,'rmFile');
end

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
                    catch ME
                        error('[%s]:Cannot load ROI (%s).',mfilename,filename);
                        rethrow(ME)
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
%trends = single(trends);
%t.trends = trends(:,dcid);
%t.dcid   = dcid;

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
if strcmpi('inplane', viewGet(view, 'viewType'))
    loopSlices = 1:params.analysis.nSlices;
end

% give some feedback so we know we are going
vethresh = params.analysis.fmins.vethresh;
if isempty(ROIcoords),
    fprintf(1,'[%s]:Processing voxels with variance explained >= %.2f\n',...
        mfilename,vethresh);
else
    fprintf(1,'[%s]:Processing voxels with variance explained >= %.2f in ROI: %s\n',...
        mfilename,vethresh,view.ROIs(view.selectedROI).name);
end;
drawnow;

% go loop over slices
for slice=loopSlices,


    %-----------------------------------
    % now we extract only the data from that slice and put it in a
    % temporary structure that will be modified throughout.
    %-----------------------------------
    s = rmSliceGet(model,slice);
    
    
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
    warning('on','MATLAB:divideByZero');
    if isempty(ROIcoords),
        wProcess = find(varexp>=vethresh);
    else
        allcoords = viewGet(view,'coords', slice);
        if strcmpi('inplane', viewGet(view, 'viewType'))
            allcoordsFunctional = ip2functionalCoords(view, allcoords);
            ROIcoordsFunctional = ip2functionalCoords(view, ROIcoords);
            [tmp, wProcess] = intersectCols(allcoordsFunctional,ROIcoordsFunctional);
        else
            [tmp, wProcess] = intersectCols(allcoords,ROIcoords);
        end
        wProcess = wProcess(varexp(wProcess)>=vethresh);
    end;

    % if no voxel in the slice is valid, move on to the next slice
    if isempty(wProcess), continue; end
    
    % Reset the 'detrend' betas.
    % We take the predefined model and remake the params. They can
    % give problems if the 'betas' are different. This may be because
    % there is different amount of detrending and/or different amount
    % of data-sets were used. Anyway, we need to make sure that the
    % amount of 'betas' are set to the current conditions.
    % This means we may have to add more trends to the data:
    for n=1:numel(model)
        if isempty(desc)
            desc = lower(rmGet(model{n},'desc'));
        end
        switch desc,
            case {'2d prf fit (x,y,sigma, positive only)','2',...
                  'difference 2d prf fit fixed (x,y,sigma,sigma2, center=positive)','d',...
                  'difference 2d prf fit beta fixed (x,y,sigma,sigma2, center=positive)','d',...
                  'oval 2d prf fit (x,y,sigma_major,sigma_minor,theta)', 'o',...
                  'radial oval 2d prf fit (x,y,sigma_major,sigma_minor)', 'r',...
                  'unsigned 2d prf fit (x,y,sigma)','u',...
                  'mirrored 2d prf fit (2*(x,y,sigma, positive only))','m',...
			      'shifted 2d prf fit (2*(x,y,sigma, positive only))',...
                  '1d prf fit (x,sigma, positive only)' ...  
                  '2d nonlinear prf fit (x,y,sigma,exponent, positive only)', ...
                  }
                    s{n}.b(2:nTrends+1,wProcess) = 0;

            case {'double 2d prf fit (x,y,sigma,sigma2, center=positive)','d',...
                  'difference 2d prf fit (x,y,sigma,sigma2, center=positive)','d',...
                  'two independent 2d prf fit (2*(x,y,sigma, positive only))','t',...
                  'sequential 2d prf fit (2*(x,y,sigma, positive only))','s',...
                  'release two prf ties',...
                  'difference 1d prf fit (x,sigma, sigma2, center=positive)'}
                    s{n}.b(3:nTrends+2,wProcess) = 0;

            otherwise
                fprintf('Unknown pRF model: %s: IGNORED!',desc);
        end
    end
    
    %-----------------------------------
    % Place datasets behind each other. This is a rather crude way of
    % stimultaneously fitting both. Due to this we cannot
    % prewhiten (we could zeropadd/let the trends deal with this/not care).
    %-----------------------------------
    % we get all the data
    p2 = params; p2.wData = 'all'; coarse   = false;
    data     = rmLoadData(view,p2,slice,coarse);
    
    % check to see that all t-series data contain finite numbers
    tmp      = sum(data(:,wProcess));
    ok       = ~isnan(tmp);
    wProcess = wProcess(ok); clear tmp ok;
    
    % limit to voxels that will be processed
    data     = data(:,wProcess);
    % detrend
    trendBetas = pinv(single(trends))*data;
    data       = data - trends*trendBetas;
    
    if params.analysis.dc.datadriven
        [data, trendBetas] = rmEstimateDC(data,trendBetas,params,trends,dcid);
    end
    
    % decimate? Note that decimated trends are stored in a new variable,
    % sliceTrends, because if we loop across multiple slices, we do not
    % want trends to be re-decimated in each loop
    data        = rmDecimate(data, doDecimate);
    sliceTrends = rmDecimate(trends, doDecimate);
    
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
    
    % decimate predictions?
    %   If we have a nonlinear model, then we cannot pre-convolve the
    %   stimulus with the hRF. Instead we make predictions with the
    %   unconvolved images and then convolve with the hRF afterwards
    if ~checkfields(params, 'analysis', 'nonlinear') || ~params.analysis.nonlinear
        %�for a lineaer model, use the pre-convolved stimulus images
        original_allstimimages = params.analysis.allstimimages;
        params.analysis.allstimimages = rmDecimate(params.analysis.allstimimages,...
            doDecimate);
    else
        % for a nonlinear model, use the unconvolved images
        params.analysis.allstimimages_unconvolved = rmDecimate(...
            params.analysis.allstimimages_unconvolved, doDecimate);
        
        % scans stores the scan number for each time point. we need to keep
        % track of the scan number to ensure that hRF convolution does operate
        % across scans
        scans = rmDecimate(params.analysis.scan_number, doDecimate);
        params.analysis.scans = round(scans);
    end
    
    
    %%
    
    
    
    %-----------------------------------
    % Go for each voxel
    %-----------------------------------
    for n=1:numel(model)
        % if dc is estimated from the data, remove it from the trends
        if params.analysis.dc.datadriven
            t.trends = [];
            t.dcid   = [];
        else
            t.trends = sliceTrends(:,dcid);
            t.dcid   = dcid;
        end
        if isempty(desc)
            desc = lower(rmGet(model{n},'desc'));
        end
        switch desc,
            case {'2d prf fit (x,y,sigma, positive only)','2'}
                % different submodel options
                if isfield(params.analysis,'xlim') && params.analysis.xlim~=0
                    s{n}=rmSearchFit_oneGaussianXlim(s{n},data,params,wProcess,t);
                else
                    if isfield(params.analysis.fmins,'refine') && strcmpi(params.analysis.fmins.refine,'sigma');
                        s{n}=rmSearchFit_oneGaussianSigmaOnly(s{n},data,params,wProcess,t);
                    else
                        % default
                        s{n}=rmSearchFit_oneGaussian(s{n},data,params,wProcess,t);
                    end
                end
                
            case {'1d prf fit (x,sigma, positive only)'}
                % different submodel options
                s{n}=rmSearchFit_1DGaussian(s{n},data,params,wProcess,t);
                
            case {'oval 2d prf fit (x,y,sigma_major,sigma_minor,theta)', 'o'}
                s{n}=rmSearchFit_oneOvalGaussian(s{n},data,params,wProcess,t);
                
            case {'radial oval 2D pRF fit (x,y,sigma_major,sigma_minor)', 'r'}
                s{n}=rmSearchFit_oneOvalGaussianNoTheta(s{n},data,params,wProcess,t);
                
            case {'unsigned 2d prf fit (x,y,sigma)','u'}
                s{n}=rmSearchFit_oneGaussianUnsigned(s{n},data,params,wProcess,t);
                
            case {'sequential 2d prf fit (2*(x,y,sigma, positive only))','s'}
                % compute residuals
                params.analysis.allstimimages = original_allstimimages;
                [residuals s{n}] = rmComputeResiduals(view,params,s{n},slice,[false doDecimate>1]);
                params.analysis.allstimimages = ...
                    rmDecimate(params.analysis.allstimimages,doDecimate);
                % fit residuals
                t.dcid = t.dcid + 1;
                s{n}=rmSearchFit_oneGaussian(s{n},residuals,params,wProcess,t);
                trendBetas = zeros(size(trendBetas));

            case {'double 2d prf fit (x,y,sigma,sigma2, center=positive)'}
                s{n}=rmSearchFit_twoGaussiansToG(s{n},data,params,wProcess,t);

            case {'difference 2d prf fit (x,y,sigma,sigma2, center=positive)'}
                if isfield(params.analysis.fmins,'refine') && strcmpi(params.analysis.fmins.refine,'sigma');
                    s{n}=rmSearchFit_twoGaussiansDoGSigmasOnly(s{n},data,params,wProcess,t);
                else
                    s{n}=rmSearchFit_twoGaussiansDoG(s{n},data,params,wProcess,t);
                end

            case {'difference 2d prf fit fixed (x,y,sigma,sigma2, center=positive)'}
                s{n}=rmSearchFit_twoGaussianDoGfixed(s{n},data,params,wProcess,t);
                
            case {'difference 2d prf fit beta fixed (x,y,sigma,sigma2, center=positive)'}
                s{n}=rmSearchFit_twoGaussianDoGBetaFixed(s{n},data,params,wProcess,t);

            case {'two independent 2d prf fit (2*(x,y,sigma, positive only))','t'}
                s{n}=rmSearchFit_twoGaussiansPosOnly(s{n},data,params,wProcess,t);
                
            case {'mirrored 2d prf fit (2*(x,y,sigma, positive only))','m'}
                s{n}=rmSearchFit_twoGaussiansMirror(s{n},data,params,wProcess,t,params.analysis.mirror);
																	   
			case {'shifted 2d prf fit (2*(x,y,sigma, positive only))','m'}
				s{n}=rmSearchFit_shiftedGaussians(s{n},data,params,wProcess,t,params.analysis.pRFshift);
																	   
            case {'release two prf ties'}
                s{n}=rmSearchFit_twoGaussiansPosOnly(s{n},data,params,wProcess,t);
                
            case {'addgaussian','add one gaussian'}
                [residuals, s{n}] = rmComputeResiduals(view,params,s{n},slice,[false params.analysis.coarseDecimate>1]);
                t.dcid = t.dcid + 1;
                s{n}=rmSearchFit_oneGaussian(s{n},residuals,params,wProcess,t);
                trendBetas = zeros(size(trendBetas));

            case {'css' 'onegaussiannonlinear', 'onegaussianexponent', ...
                    '2d nonlinear prf fit (x,y,sigma,exponent, positive only)'}
                s{n}=rmSearchFit_oneGaussianNonlinear(s{n},data,params,wProcess,t);

            otherwise
                fprintf('[%s]:Unknown pRF model: %s: IGNORED!\n',mfilename,desc);
        end
    end


    %-----------------------------------
    % now put back the trends to the fits
    %-----------------------------------
    for mm=1:numel(s),
        nB = size(s{mm}.b,1)-nTrends+1;
        s{mm}.b(nB:end,wProcess) = s{mm}.b(nB:end,wProcess)+trendBetas;
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
output = rmSave(view,model,params,1,stage);
view   = viewSet(view,'rmFile',output);

% that's it
return;
%-----------------------------------
