function view = rmPlot(view, wplot, modelId,alltimepoints);
% rmPlot - plot retinotopic model voxel results
%
% rmPlot(view, [wplot='all'], [modelId]);
%
% Produce a series of plots illustrating the fit of the currenlt selected
% retinopy model to the first voxel of the currently-selected ROI. 

% 2006/02 SOD: wrote it.

% Programming note: we want the model to be independent of the
% actual scan (parameters).
if notDefined('view'),     error('Need view struct'); end;
if notDefined('wplot'),    wplot = 'all';             end;
if notDefined('modelId'),  modelId = [];              end;
if notDefined('alltimepoints'), alltimepoints = true; end;


% this plot requires an ROI to be defined
if view.selectedROI == 0,
    disp(sprintf('[%s]:No ROI selected.', mfilename));
    return;
end;

% load file with data
rmFile = viewGet(view, 'rmFile');
if isempty(rmFile),
    disp(sprintf('[%s]:No file selected', mfilename));
    return;
end;

% load model
try,  model = viewGet(view, 'rmModel'); catch,  model = []; end;
if isempty(model),    load(viewGet(view, 'rmFile'), 'model');
    view = viewSet(view, 'rmModel', model);
    model = viewGet(view, 'rmModel');
end;

% check if they are loaded
try,
    params = viewGet(view, 'rmParams');
catch,
    params = [];
end;

if alltimepoints,
    if sum([params.stim(:).nUniqueRep])~=numel([params.stim(:).nUniqueRep]),
        params = [];
    end;
end;

if isempty(params),
    params = rmDefineParameters(view);
    
    % reset temporal averaging parameter so that we can see entire time series
    for n=1:length(params.stim),
        params.stim(n).nUniqueRep = 1;
    end;

    % if we remake the stim we should use the hrf that was used in
    % the model
    try,
        params.analysis.wHrf      = rmGet(model{1},'whrf');
        params.analysis.HrfParams = rmGet(model{1},'hrfparams');
        for n=1:numel(params.stim),
            [tmp tmphrf peak] = rfConvolveTC([1 zeros(1,params.stim(n).nFrames-1)],...
                params.stim(n).framePeriod,...
                params.analysis.wHrf,...
                params.analysis.HrfParams);
            params.analysis.Hrf{n} = tmphrf(:);
        end;
        params.analysis.HrfMaxResponse = peak;
    catch,
        % old defaults before they were stored in model file
        params.analysis.wHrf      = 'boynton';
        params.analysis.HrfParams = [1.68 3];
        for n=1:numel(params.stim),
            [tmp tmphrf peak] = rfConvolveTC([1 zeros(1,params.stim(n).nFrames-1)],...
                params.stim(n).framePeriod,...
                params.analysis.wHrf,...
                params.analysis.HrfParams);
            params.analysis.Hrf{n} = tmphrf(:);
        end;
        params.analysis.HrfMaxResponse = peak;
    end;
    params = rmMakeStimulus(params);

    % store params in view struct
    view  = viewSet(view,'rmParams',params);
end;

for n=1:length(model),
    modelNames{n} = rmGet(model{n},'desc');
end;


% get model id
if isempty(modelId),
    % get model names
%     modelId = menu('Select stimulus type: ', modelNames);drawnow;
    modelId = viewGet(view, 'rmModelNum');
end;

% get time series and roi-coords
[tSeries, coords] = gettimeseries(view, params);

% TO DO: FIX ME...
if size(coords, 2) > 1,
    %  disp('[%s]:Warning more than one voxel: using only first one');
    %  tSeries = tSeries(:, 1);
    %  coords  = coords(:, 1);
end;


% make trends
[trends,  ntrends] = rmMakeTrends(params);
trendID = ntrends;

% load rss
rss = getrfprofile(view, model{modelId}, coords, 'rss')

% Now for each model kind make the prediction and pRFs. 
[pred, RF] = rmPredictedTSeries(view, coords, modelId, params);

%maximum response
disp(sprintf('[%s]:Maximum response (1 sec stim) to full stimulution: %.2f and optimal %.2f stimulation',...
    mfilename,...
    sum(RF.*(params.analysis.sampleRate.^2.*params.analysis.HrfMaxResponse)),...
    sum(RF.*(RF>0).*(params.analysis.sampleRate.^2.*params.analysis.HrfMaxResponse))));

% now plot
switch lower(wplot),
    case {'rf'},
        rfPlot(params, RF);

    case {'ts'},
        tsPlot(tSeries, pred, rss, params, modelNames{modelId});

    case {'all'},
        rfPlot(params, RF);
        tsPlot(tSeries, pred, rss, params, modelNames{modelId});
        %  disp(sprintf('[RF]: x, y coordinates: %.4f, %.4f degrees', ...
        %               mean(rfId(4.:)),  mean(rfId(5.:))));
        %  disp(sprintf('[RF]: sigma: %.4f, %.4f degrees', ...
        %               mean(rfId(4.:)),  mean(rfId(5.:))));

    otherwise,
        error(sprintf('[%s]: unknown value of wplot: %s', mfilename,  ...
            wplot));
end;
return;


%--------------------------------------
function betaID = getbetas(view, params, model, coords, trendID);
for n=1:max(trendID),
    try,
        betaID(:,n) = getrfprofile(view, model, coords, ...
            sprintf('bcomp%d', n));
    catch,
        betaID(:,n) = 0;
    end;
end;
betaID,
return;
%--------------------------------------


%--------------------------------------
function [RFs,  pred,  RFs2,  pred2] = getrfsequence(view, params, model, coords);

% get RF parameters
rfId(:,1) = getrfprofile(view, model, coords, 'sigmamajor');
rfId(:,2) = getrfprofile(view, model, coords, 'sigmaminor');
rfId(:,3) = getrfprofile(view, model, coords, 'sigmatheta');
rfId(:,4) = getrfprofile(view, model, coords, 'x0');
rfId(:,5) = getrfprofile(view, model, coords, 'y0');

for n=1:size(coords, 2), 
    RFs(:, n)   = rfGaussian2d(params.analysis.X, params.analysis.Y, ...
        rfId(1), rfId(2), rfId(3), rfId(4), rfId(5));
    pred(:, n)  = rfMakePrediction(params, rfId);
end;
s1 = mean(rfId(:, 1));

if nargout > 2,
    rfId(:, 1) = getrfprofile(view, model, coords, 'sigma2major');
    rfId(:, 2) = getrfprofile(view, model, coords, 'sigma2minor');
    rfId(:, 3) = getrfprofile(view, model, coords, 'sigma2theta');
    rfId(:, 4) = getrfprofile(view, model, coords, 'x0');
    rfId(:, 5) = getrfprofile(view, model, coords, 'y0');

    disp(sprintf('[%s]: x, y, s1(M), s2(M) = %.4f,  %.4f,  %.4f,  %.4f (deg)', ...
        mfilename, ...
        mean(rfId(:, 4)), mean(rfId(:, 5)), s1, mean(rfId(:, 1))))
    for n=1:size(coords, 2),
        RFs2(:, n)   = rfGaussian2d(params.analysis.X, params.analysis.Y, ...
            rfId(1), rfId(2), rfId(3), rfId(4), rfId(5));
        pred2(:, n)  = rfMakePrediction(params, rfId);
    end;
else,
    disp(sprintf('[%s]: x, y, s(M) = %.4f,  %.4f,  %.4f', ...
        mfilename, ...
        mean(rfId(:, 4)), mean(rfId(:, 5)), mean(rfId(:, 1))))
end;
return;
%--------------------------------------



%--------------------------------------
function [stim] = getonoffsequence(params);
% make stim on/off sequence
stim = [];
for ii = 1:length(params.stim),
    stim = [stim; params.stim(ii).stimOnOffSeq];
end;
return
%--------------------------------------



%--------------------------------------
function [ts,  coords] = gettimeseries(view, params);
params.wData = 'roi';
% TO DO: fix so we can average tSeries and fits...
if size(view.ROIs(view.selectedROI).coords, 2) > 1,
    disp(sprintf('[%s]:WARNING:plotting only first coordinate', mfilename));
    view.ROIs(view.selectedROI).coords = view.ROIs(view.selectedROI).coords(:, 1);
end;
[tSeries,  params] = rmLoadData(view, params);
ts     = mean(tSeries, 2);
coords = rmGet(params,'coords');
switch lower(view.viewType),
    case 'inplane'
        rsFactor = upSampleFactor(view, 1);
        if length(rsFactor)==1
            coords(1:2,:) = round(coords(1:2,:)/rsFactor(1));
        else
            coords(1,:) = round(coords(1,:)/rsFactor(1));
            coords(2,:) = round(coords(2,:)/rsFactor(2));
        end;
        coords = unique(coords', 'rows')';

    case {'volume' 'gray'}
        coordsInd    = zeros(1, size(coords, 2));
        allcoords    = viewGet(view, 'coords');
        % loop because intersect orders the output
        for n=1:size(coords, 2);
            [tmp,  coordsInd(n)] = intersectCols(allcoords, coords(:, n));
        end;
        coords = coordsInd;

    otherwise
        error(sprintf('[%s]:unknown viewType %s', ...
            mfilename, viewGet(view, 'viewType')));
end;
return;
%--------------------------------------


%--------------------------------------
function rfp = getrfprofile(view, model, coords, param);
tmp = rmGet(model, param);
rfp = zeros(size(coords, 2), 1);
switch lower(view.viewType),
    case 'inplane'
        for n=1:length(rfp),
            rfp(n) = tmp(coords(1, n), coords(2, n), coords(3, n));
        end;

    case 'gray'
        rfp = tmp(coords);
end;
return;
%--------------------------------------



%--------------------------------------
function tsPlot(ts, fit, rss, params, modelName);
figure;
x=[1:length(ts)].*params.stim(1).framePeriod;
nscans = length(params.stim);
sepx = [1:nscans-1].*max(x)./nscans;
sepx = cumsum([params.stim(:).nFrames].*params.stim(1).framePeriod);

subplot(2, 1, 1);
plot(x, ts, 'bo:');hold on;
plot(x, fit(:, 1), 'r');
if size(fit, 2) > 1,
    plot(x, fit(:, 2), 'g--');
end;
h = axis;
axis([min(x) max(x) h(3) h(4)]);
for n=1:length(sepx),
    plot([1 1].*sepx(n), [h(3) h(4)], 'k:');
end;
title(sprintf('Model: %s', modelName));
xlabel('time (sec)');
ylabel('% BOLD signal change');

subplot(2, 1, 2);
plot(x, ts-fit(:, 1), 'b');hold on;
plot(x, fit(:, 1), 'r');
title(sprintf('Residuals (RSS: %f)', mean(rss)));
xlabel('time (sec)');
ylabel('% BOLD signal change');

% print out percent variance (R^2) explained:
r2 = (1 - (sum((ts-fit(:, 1)).^2)  ./sum(ts.^2))).*100;
disp(sprintf('[%s]:Variance explained (r^2): %.2f%%.', ...
    mfilename, r2));

tsdata.x    = x;
tsdata.fit  = fit;
tsdata.raw  = ts;
tsdata.sepx = sepx;
set(gcf, 'userdata', tsdata);
return;
%--------------------------------------
