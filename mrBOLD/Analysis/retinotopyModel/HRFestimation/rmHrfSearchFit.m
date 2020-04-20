function [view,params] = rmHrfSearchFit(view,params)
% rmHrfSearchFit - optimize model fit by adjusting HRF parameters (not RM
% parameters).
% 
% [view params] = rmHrfSearchFit(view,params)
%
% params contain the new HRF, the model file not yet (because it is still
% estimated with the old hrf.

% 2009/02 SOD: wrote it.
% 2009/10 SOD & WZ: updated. Split off model specific predictions so that
% the fit works for different models.

% Warning: only works for two gamma model but always gives best fit too -
% more df - and if fifth parameter appoaches 0 this function becomes a one
% gamma function very similar to the Boynton one.
% 


% we really need the optimization toolbox now:
reserveToolbox('optimization');
warning('off','optim:fmincon:SwitchingToMediumScale');

try
    rmFile = viewGet(view,'rmFile');
catch %#ok<CTCH>
    fprintf(1,'[%s]:No file selected',mfilename);
    view = rmSelect(view);
    rmFile = viewGet(view,'rmFile');
end;
tmp = load(rmFile);

% input check
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

% some defaults
if isfield(params.analysis,'hrfmins')
    thresh = params.analysis.hrfmins.thresh;
    searchOptions = params.analysis.hrfmins.opt;
    doplot = params.analysis.hrfmins.plot;
    range  = params.analysis.hrfmins.range;
    maxHrfDuration = params.analysis.hrfmins.maxHrfDuration;
    gridsample = params.analysis.hrfmins.gridsample;
else
    % some defaults
    searchOptions.TolX    = 1e-6;
    searchOptions.MaxIter = 200;
    searchOptions.Display = 'final';
    searchOptions.tolFun  = 1e-6;
    thresh.ve = 0.1;
    thresh.ecc = [0 params.analysis.fieldSize];
    thresh.sigma = [params.analysis.minRF params.analysis.maxRF];
    doplot = true;
    range  = 2;
    maxHrfDuration = 30;
    gridsample = 9;
end


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
deleteme = load(rmFile);
model = deleteme.model;
clear deleteme

% load all data
params.wData = 'all';


%-----------------------------------
%--- (re)make allstimimages variable without HRF convolution
%-----------------------------------

tmp_param = params.stim;
for n=1:numel(tmp_param),
    tmp_param(n).images = tmp_param(n).images_org;

    tmp_param(n).images = tmp_param(n).images_org;
    % now scale amplitude according to the sample rate:
    tmp_param(n).images = tmp_param(n).images'.*(params.analysis.sampleRate.^2);
            
    % limit to actual MR recording.
    tmp_param(n).images = tmp_param(n).images(tmp_param(n).prescanDuration+1:end,:);
    
    % and time averaging
    tmp_param(n).images = rmAverageTime(tmp_param(n).images, ...
                                  tmp_param(n).nUniqueRep)';
end;

% matrix with all the different stimulus images.
allstimimages = [tmp_param(:).images]';
    
%-----------------------------------
%--- make trends to fit with the model (dc, linear and sinewaves)
%-----------------------------------
[trends, ntrends, dcid]  = rmMakeTrends(params);

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


%-----------------------------------
% go loop over slices and collect data, x, y, and sigma, only for voxels
% above a certain variance explained threshold 
%-----------------------------------

% for n=1:numel(model)
%         if isempty(desc)
%             desc = lower(rmGet(model{n},'desc'));
tmp.data = [];
for slice=loopSlices,
    % now we extract only the data from that slice
    s = rmSliceGet(model,slice);
    
    
    % Find voxels (in ROI)
    if view.selectedROI ~= 0,
        fprintf('[%s]:Limit to ROI (%s).\n',mfilename,view.ROIs(view.selectedROI).name);
        ROIcoords = view.ROIs(view.selectedROI).coords;
        [junk, tmpii] = intersectCols(view.coords,ROIcoords);
        wProcess = false(size(s{1}.x0));
        wProcess(tmpii) = true;
    else
        wProcess = true(size(s{1}.x0));
    end
    
    % thresholds
    warning('off','MATLAB:divideByZero');
    varexp   = 1-s{1}.rss./s{1}.rawrss;
    [junk ecc] = cart2pol(s{1}.x0, s{1}.y0);
    warning('on','MATLAB:divideByZero');
    wProcess = wProcess & ...
        varexp>=thresh.ve & ...
        ecc>=thresh.ecc(1) & ecc<=thresh.ecc(2) & ...
        s{1}.s>=thresh.sigma(1) & s{1}.s<=thresh.sigma(2);
    
    tmp.wProcess{slice} = wProcess;
    tmp.varexp{slice}   = varexp;
    
    % if no voxel in the slice is valid, move on to the next slice
    if all(wProcess==0), continue; end
    
    % get data, limit, detrend, and store
    data     = rmLoadData(view,params,slice);
    data     = data(:,wProcess);
    trendBetas = pinv(single(trends))*data;
    data       = data - trends*trendBetas;
    tmp.data   = [tmp.data data];
    
    % set baseline to dc-component estimated by mean-luminance blocks
    if params.analysis.dc.datadriven
        desc = lower(rmGet(model{1},'desc'));
        switch desc,
            case {'2d prf fit (x,y,sigma, positive only)'}
                dcBetas = s{1}.b(2,wProcess);
        
            case {'double 2d prf fit (x,y,sigma,sigma2, center=positive)',...
                    'difference 2d prf fit (x,y,sigma,sigma2, center=positive)'}
                dcBetas = s{1}.b(3,wProcess);
        
            otherwise
                fprintf('[%s]:Unknown (or unincorporated) pRF model: %s: IGNORED!\n',mfilename,desc);
        end
        tmp.data = tmp.data - trends(:,dcid)*dcBetas;
    end
end
data = tmp.data;

% somehow this can happen.... fix me...
data(~isfinite(data))=1;

% aggregate across slices
wProcess = tmp.wProcess; 
varexp   = tmp.varexp;
if numel(wProcess) == 1, wProcess = wProcess{1}; end
if numel(varexp) == 1, varexp = varexp{1}; end

%-----------------------------------
% make predictions for each voxel using allstimimages _without_ hrf. This
% step depends on your pRF model.
%-----------------------------------
if numel(model)>1
    fprintf(1,'WARNING:DOES NOT WORK FOR MULTIPLE pRF MODELS IN ONE MODEL FILE'); 
    fprintf(1,'WARNING:USING ONLY FIRST MODEL'); 
end   



desc = lower(rmGet(model{1},'desc'));
switch desc
    case {'2d prf fit (x,y,sigma, positive only)'}
        tmp.prediction = rmHrfSearchFit_oneGaussian(model, params, loopSlices, wProcess,varexp,allstimimages);
        
    case {'double 2d prf fit (x,y,sigma,sigma2, center=positive)',...
            'difference 2d prf fit (x,y,sigma,sigma2, center=positive)'}
        tmp.prediction = rmHrfSearchFit_twoGaussian(model, params, loopSlices, wProcess,varexp,allstimimages);
    case {'2d nonlinear prf fit (x,y,sigma,exponent, positive only)'}
        tmp.prediction = rmHrfSearchFit_oneGaussianCSS(model, params, loopSlices, wProcess,varexp,allstimimages);
    otherwise
        fprintf('[%s]:Unknown (or unincorporated) pRF model: %s: IGNORED!\n',mfilename,desc);
end




%-----------------------------------
% Split up scans with different stimuli, convolution with the HRF will blur
% the end and beginning of scans (not what we want).
%-----------------------------------
prediction = cell(numel(tmp_param),1);
counter = 0;
startNum = 1;
for n=1:numel(tmp_param)
    sz = size(tmp_param(n).images,2);
    counter = counter + sz;
    prediction{n} = tmp.prediction(startNum:counter,:);
    startNum = startNum + sz;
end


%-----------------------------------
% search call
%-----------------------------------
hrfParams.hrfStart   = params.stim(1).hrfParams{2};
hrfParams.tr         = params.stim(1).framePeriod;
hrfParams.range      = range;
hrfParams.maxHrfDuration = maxHrfDuration;
hrfParams.searchOptions = searchOptions;
hrfParams.gridsample = gridsample;

outParams = hrfModelSearchFit(data,prediction,hrfParams,params);


%-----------------------------------
% plotting of estimated and default HRF
%-----------------------------------
if doplot
    sr = 0.1;
    x = 0:sr:30;
    t = zeros(size(x)); t(1)=1;
    d = rfConvolveTC(t,sr,'t',hrfParams.hrfStart);
    e = rfConvolveTC(t,sr,'t',outParams);
    bg = rfConvolveTC(t,sr,'b');
    tg = rfConvolveTC(t,sr,'t');
    
    figure;hold on;
    plot(x,d./max(d(:)),'b');
    plot(x,e./max(e(:)),'r');
    plot(x,bg./max(bg(:)),'k--');
    plot(x,tg./max(tg(:)),'k--');
    set(gca,'YTick',-1:.25:1,'XTick',0:5:30);
    grid on;
    ylabel('BOLD signal change (au)');
    xlabel('Time (sec)');
    legend('Default (input to pRF model)','Estimated (from pRF model)','Default (one gamma)','Default (two gammas)');
    title('Normalized HRF');
    drawnow;
end


%-----------------------------------
% save
%-----------------------------------
% store new hrf
params = hrfSet(params,'hrfType','two gammas');
params = hrfSet(params,'hrfParams',outParams);
params = hrfSet(params,'hrf');

% recompute stimulus predictions (convolved with HRF)
params = rmMakeStimulus(params);

% save
output = rmSave(view,model,params,1,'hrfFit');
view   = viewSet(view,'rmFile',output);
view   = viewSet(view,'rmParams',params);

% that's it
return;
%-----------------------------------


