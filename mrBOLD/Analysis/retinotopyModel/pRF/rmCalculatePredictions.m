function [vw, tgtScan, tgtDt] = rmCalculatePredictions(vw, useDialog, varargin)
% Applies a pRF model to a stimulus and saves time series as a new scan
%
%   [vw tgtScan tgtDt] = rmCalculatePredictions([vw], [useDialog], [varargin])
%
% This code uses the current pRF in the view. It calculates the response to
% the stimuli specified by the stimulus parameters which can either be
% input as an argument or the ones that are currently loaded in the view's.
%
% If the stimulus parameters are omitted, the stimuli used to fit the pRF
% model are used.
%
% INPUTS
%
% vw: mrVista view structure
%    [Default = getCurView]
%
% useDialog: flag to call dialog window to set parameters
%
% Options can be specified in pairs of 'Name', [value], ...
% Options are:
%	'stimParams' :
%       Stimulus parameters. Default is the set of currently loaded
%       stimulus parameters (verify with 'File > Retinotopy Model >
%       Stimulus Information)
%
%   'rModel' :
%       Retinotopy model.  Default is the currently loaded model (rm).
%
%   'dtName':
%       Name of dataTYPE to store simulated data.
%           [Default = 'Simulated']
%   'step':
%       step size for doing the fitting.  This determines how fast the
%       fitting occurs, at the expense of memory. For larger step sizes,
%       the fitting may take place faster, but is more likely to run out of
%       memory.
%           [Default = 2000]
%
%   'allTimePoints'
%       true: make the predicted time series for all time points
%       false: make the predicted time series for a single cycle only
%           (The number of cycles for each scan are specified by
%           P.stim.nUniqueRep.)
%               [Default = 1, save all time points]
%
%	'useBetas'
%       true:  normalize each pRF to stored betas, in an attempt to
%              predict time series in something like units of percent
%              signal change,
%       false: normalize each pRF to have unit volume
%           [Default = 0,  normalize to unit volume.]
%
%       The reasoning for normalizing is this: the pRF fitting stage
%       produces a scaling coefficient (beta) for each voxel. This reflects
%       approximately the scaling needed to convert the raw prediction
%       (which reflects the overlap between a given pRF and a stimulus) to
%       the units of the fitted data (usually % signal change). Although
%       this value may not prove to be a general scaling coefficient for
%       all stimuli, it reflects the best knowledge of the model for
%       scaling things.
%
%       Note: The betas are sensitive to the stimulus grid used in model
%       fitting. If a different grid is used in predicting the signals, the
%       betas may be inaccurate, sometimes producing runaway values (off by
%       many orders or magnitude). Normalizing to unit volume loses
%       information but is safer: it guarantees that the predicted response
%       to a full-field, uniform stimulus will produce the same percent
%       signal in every voxel.
%
%	'saveResidual': if 1, saves the residual time series from the fit in an
%		additional data type, named [dtName '_Residual'].
%			[Default = 0, don't save residual]
%
%   'detrend': if 1, will detrendFlag the predictions (remove the mean and a
%               linear trend). [default 1]
%
%   OUTPUTS:
%
%   The modified view is returned in vw.
%
%   The integers of the newly created scan and dataType are returned in
%   tgtScan and tgtDt.
%
%
% Examples:
%  Use the model and stimuli in the current view to create the prediction
%  of perfect (noise-free) data, for this model and stimulus
%
%   vw = getCurView;
%   stimParams = viewGet(vw,'rmParams');
%   rModel = viewGet(vw,'rModel');
%   [vw tgtScan tgtDt] = rmCalculatePredictions(vw, 0, 'P', stimParams,'rModel',rModel)
%
%  Use the model  in the current view but a different stimulus for the
%  prediction
%
%   vw         = getCurView;
%   rmEditStimulusParameters(vw);  % Edit up the stimulus
%   stimParams = viewGet(vw,'rmParams');
%   rModel     = viewGet(vw,'rModel');
%   [vw tgtScan tgtDt] = rmCalculatePredictions(vw, 0, 'P',stimParams,'rModel',rModel)
%
% ras, 06/19/2008.
% jw, 09/2008: added dialog box, changed normalization calculation, various
% minor updates

%% grab global variables
mrGlobals;  % we'll need this for updating data types below

%% Check inputs

% parse the options
for ii = 1:2:length(varargin)
    switch lower(varargin{ii})
        case 'varthresh',                        varthresh = varargin{ii+1};
        case 'rmodel',                           model = varargin{ii+1};
        case {'p','stimparams'},                 P = varargin{ii+1};
        case 'alltimepoints',                    allTimePoints = varargin{ii+1};
        case 'usebetas',                         useBetas = varargin{ii+1};
        case 'step',                             step = varargin{ii+1};
        case {'dtname', 'dt', 'datatype'},       dtName = varargin{ii+1};
        case {'normtomeansignal', 'normtomean'}, normToMeanSignal = varargin{ii+1};
        case {'add100','savepercent'},           savePercent = varargin{ii+1};
        case {'saveresidual' 'saveresiduals'},   saveResiduals = 1;
        case {'detrend' 'detrendflag'},       detrendFlag = varargin{ii+1};
        otherwise
            % Unspeakable hack, but leaving until later
            eval( sprintf('%s = %s', varargin{ii}, num2str(varargin{ii+1})) );
    end
end

if notDefined('vw'),            vw = getCurView;	end
if notDefined('useDialog'),     useDialog = 1;      end

if notDefined('P'),             P = viewGet(vw, 'rmparams');	end
if notDefined('dtName'),        dtName = 'Simulated';			end
if notDefined('allTimePoints'),	allTimePoints = 1;			end
if notDefined('saveResiduals'), saveResiduals = 0;			end

if useDialog
    % get parameters from a dialog
    [resp, ok] = rmSavePredictionsParams;
    if ~ok, return; end

    % Return the variables from the box
    dtName        	 = resp.dtName;
    allTimePoints    = resp.allTimePoints;
    step             = resp.step;
    useBetas         = resp.useBetas;
    normToMeanSignal = resp.normToMeanSignal;
    varthresh        = resp.varthresh;
    savePercent      = resp.savePercent;
    detrendFlag      = resp.detrendFlag;
    saveResiduals    = resp.saveResiduals;
end

%% verify that we have necessary fields and data
% is there a pRF model
if notDefined('model')
    try
        model = viewGet(vw, 'rmmodel');
        model = model{vw.rm.modelNum};
    catch
        error('No pRF model loaded. Load a pRF model.')
    end
end

% Get the descriptive string for the model
modelName = rmGet(model, 'desc');

% are the stimulus params kosher?
if ~checkfields(P, 'analysis', 'allstimimages')
    error(['Need a retinotopy-model format params structure. ' ...
        'See rmMakeStimulus. '])
end

% analysis parameters
% we do the prediction step in batches of 10000 at a time, to prevent hitting
% the maximum variable size limit set in MATLAB.
if notDefined('step'), step  = 2000; end

% a flag to multiply the predictions by the mean functional image. The
% reasoning here is that the predictions may be percent signal modulation
% of a mean signal, but we want to include in our predictions a sense of
% where the mean image is small.
if notDefined('normToMeanSignal'), normToMeanSignal = 0; end

% flag to scale pRFs according to the beta coefficients saved in the model.
% false: pRFs are scaled to have a uniform volume. The volume is scaled to
%           the stimulus grid sampling rate. Thus a full field stimulus of
%           maximal intensity will cause a 1% signal change.
% true: pRFs are scaled to stored betas.
if notDefined('useBetas'), useBetas = 1; end

% we may not want to make predictions for voxels for which the variance
% explained by the model is too low. Thus we set a threshold.
if notDefined('varthresh'), varthresh = 0.1; end

% We can save the t-series as a percent modulation (savePercent = true), or
% we can save the t-series as a signal (savePercent = false). In the latter
% case, it plots correctly using the normal mrVista tools.  With
% savePercent = true, the saved value is a percent modulation. The plots then take
% a percent of a percent and the numbers plot oddly - though there may be
% other applications where it is preferable to save the percent modulation.
% We default to saving as a signal, not a percent.
if notDefined('savePercent'), savePercent = 0;		end

% do we detrendFlag the predictions (remove the mean?)
if notDefined('detrendFlag'), detrendFlag = 1;              end

% saving the residuals requires certain sets of parameters, or else the
% predictions will not have the same range of units as the data, and
% therefore the residuals will contain substantial signals.
if saveResiduals==1
    if allTimePoints==0
        error(['Sorry, saving the residuals from a single cycle ' ...
            'is not yet implemented.'])
    end

    if normToMeanSignal==0 || detrendFlag==0
        fprintf('[%s]: Setting detrendFlag to 1 and normToMean to 1.', ...
            mfilename);
        fprintf(' These settings are needed to save residuals.\n');
        detrendFlag = 1;
        normToMeanSignal = 0;
    end
end

% we'll need to remember the source data types, to get accurate
% descriptions in the output data type:
srcDt = vw.curDataType;


%% recompute the parameters
% this ensures we have the right # of time points in the stimulus
P = rmRecomputeParams(vw, P, allTimePoints);

%% break up the stimulus images by scan
% although the retinotopy model loads all the stimulus images together and
% does one big fitting, we'll want to break up the predictions according to
% the scan -- so each scan in the simulated output corresponds to a scan in
% the input data.
nScans = length(P.stim);
startFrame = 1;
for scan = 1:nScans
    nImages(scan) = (P.stim(scan).nFrames / P.stim(scan).nUniqueRep);
    rng = startFrame:startFrame + nImages(scan) - 1;

    stimuli{scan} = P.analysis.allstimimages(rng,:);

    startFrame = startFrame + nImages(scan);
end

%% main loop: across scans
tic
for scan = 1:nScans
    % select the source data type (it will get set to the target dt below)
    vw = viewSet(vw, 'currentDataTYPE',  srcDt);

    % initialize empty time series (this way we know if it's a memory
    % bottleneck)
    nVoxels = prod(viewGet(vw, 'sliceDims', scan));
    nSlices = viewGet(vw, 'numSlices');
    tSeries = zeros(nImages(scan), nVoxels, nSlices);

    % get the mean image if needed
    if normToMeanSignal==1
        vw = loadMeanMap(vw);
    end

    %% Make predictions
    % loop across slices within this scan
    for slice = 1:nSlices
        % get the pRF params for each voxel in this slice
        sigmaMajor = model.sigma.major(:,:,slice);
        sigmaMinor = model.sigma.minor(:,:,slice);
        x0 = model.x0(:,:,slice);
        y0 = model.y0(:,:,slice);

        % jw add
        varexp = rmGet(model, 'varexplained');

        % get the betas
        % (take only the main scaling factor; the other betas are for
        % trend terms, which we're not simulating here)
        if isequal(vw.viewType, 'Inplane')
            beta = model.beta(:,:,slice,1);
        else
            beta = model.beta(:,:,1);
        end

        h_wait = mrvWaitbar(0, sprintf('Making pRF predictions, scan %i', scan));

        nVoxels = length(x0(:));
        for v = 1:step:nVoxels
            I = v:v+step-1;  % indices of voxels to compute for this cycle
            I = I(I<nVoxels);  % restrict to num voxels

            % create the pRFs
            pRFs = rfGaussian2d(P.analysis.X, P.analysis.Y, ...
                sigmaMajor(I), sigmaMinor(I), 0, x0(I), y0(I));


            if useBetas
                % scale the pRFs by the fitted betas
                pRFs = repmat(beta(I), [size(pRFs, 1) 1]) .* pRFs;
            else
                % normalize the pRF to have unit volume
                %   note: we can normalize to unit volume discreetly (by
                %       summing the points on the pRF), or analytically, by
                %       dividing each pRF by (2*pi*sigma^2). analytic
                %       normalization may be safer since it is possible
                %       that only a small part of the pRF will intersect
                %       the grid, in which case discrete normalization will
                %       be very innacurate.

                %pRFs = pRFs ./ repmat( sum(pRFs, 1), [size(pRFs, 1) 1] );
                pRFs = pRFs ./ repmat(sigmaMajor(I).^2, [size(pRFs, 1) 1]) ;
                pRFs = pRFs ./ (2*pi);


                % then scale by 1/sampling rate
                pRFs = pRFs ./ (P.analysis.sampleRate.^2);
                %   note: we do this because the stimulus is normally scaled by
                %       the sampling rate when it is made. that scaling is
                %       useful when the pRF will be scaled by the betas.
                %       but if the pRFs are scaled to unit volume, then the
                %       stimulus should be scaled to unit intensity, in
                %       order for a full-field unit stimulus to elicit 1%
                %       signal change. thus:
                %       output = (stim*samplerate^2) * pRF/samplerate^2

            end
            
            % convolve the pRFs with the stimulus specification
            tSeries(:,I,slice) = stimuli{scan} * pRFs;
            
            % If it's a nonlinear model, we need a different calculation
            if contains(modelName, {'css' '2D nonlinear pRF fit (x,y,sigma,exponent, positive only)'})
                
                pRFs = rfGaussian2d(P.analysis.X, P.analysis.Y, ...
                sigmaMajor(I), sigmaMinor(I), 0, x0(I), y0(I));

                % we-do the prediction with stimulus that has not been convolved
                % with the hrf, and then add in the exponent, and then convolve                               
                exponent = model.exponent(:,:,slice);
                               
                % make neural predictions for each RF
                pred = (P.analysis.allstimimages_unconvolved * pRFs).^exponent(I);
                                               
                % reconvolve with hRF
                these_time_points = P.analysis.scan_number == scan;
                hrf = P.analysis.Hrf{scan};
                pred(these_time_points,:) = filter(hrf, 1, pred(these_time_points,:));
                
                % scale prediction by gain (beta weight)
                pred(these_time_points,:) =  bsxfun(@times, pred(these_time_points,:), beta(I));
                
                tSeries(these_time_points,I,slice) = pred;
                            
            end
            
            if savePercent==1
                % jw: convert from percent signal to modulation about 100
                % (allows for correct outcomes when other functions try to
                % extract % sinal)
                tSeries(:,I,slice) = tSeries(:,I,slice) + 100;
            else
                % that heuristic is not always useful, and can make certain
                % uses of the predictions way off
                
            end
                        
            if normToMeanSignal==1
                % scale modulation around mean map instead of 100
                meanImg = vw.map{scan}(:,:,slice);
                meanImg = repmat( meanImg(I), [nImages(scan) 1] );
                tSeries(:,I,slice) = tSeries(:,I,slice) .* meanImg / 100;
            end

            ok = varexp(I) >= varthresh;
            tSeries(:,I(~ok), slice) = NaN;

            mrvWaitbar(v/nVoxels, h_wait);
        end
        close(h_wait);
    end

    %% detrendFlag all the time series if needed
    if detrendFlag==1
        for slice = 1:numSlices(vw)
            tSeries(:,:,slice) = convertToPercent(tSeries(:,:,slice)) ./ 100;
        end
    end

    %% Save the predictions in a new dataTYPE

    % if there are more scans in the target data type than the
    % source data type, then we copy parameters from the highest scan number
    % in the source data type
    thescan = min(scan, viewGet(vw, 'nScans'));

    % initialize the new scan
    % If dtName already exists, it is added. Otherwise a new dataType slot
    % is created with the dtName.
    [vw, tgtScan, tgtDt] = initScan(vw, dtName, [], {srcDt thescan});

    % update the dataTYPES fields to reflect this scan
    % (tacit assumption: the model reflects 1:nScans in this data type)

    % update description
    srcDescription = P.stim(scan).stimType;
    description    = sprintf('pRF Prediction: %s', srcDescription);
    if allTimePoints==0
        description = strcat(description,' (Single Cycle)');
    end
    dataTYPES(tgtDt) = dtSet(dataTYPES(tgtDt),'annotation',description,scan);

    % update nImages
    dataTYPES(tgtDt) = dtSet(dataTYPES(tgtDt),'nFrames',nImages(scan),scan);

    % update nCycles
    if allTimePoints==0
        dataTYPES(tgtDt).blockedAnalysisParams(tgtScan).nCycles = 1;
    end

    % update stim params (note that we save only the stimulus fields
    % specificed in rmCreateStim to avoid saving very large strucs)
    %     sParams = rmCreateStim(vw,P.stim(scan));
    %     dataTYPES(tgtDt) = dtSet(dataTYPES(tgtDt), 'retinotopyModelParams',sParams, scan);

    % the simulations are saved in units of % signal -- we don't want to
    % detrend / multiply these values when loading in the future:
    turnOffDetrending(vw, tgtDt);

    % update the session
    saveSession;

    %------------------------------------------------------------------
    % Write out the time series
    %------------------------------------------------------------------
    vw = viewSet(vw, 'currentDataTYPE',  tgtDt);
    savetSeries(tSeries, vw, tgtScan); %This is alright since tSeries 
    % already contains all the slices

    %% also save residuals in a separate data type if requested
    if saveResiduals==1
        % initialize the new scan
        [vw, resScan, resDt] = initScan(vw, [dtName '_Residual'], [], {srcDt scan});

        % save the time series
        residualFull = [];
        dimNum = 0;
        for slice = 1:numSlices(vw)
            % load the time series from the original data
            vw.curDataType = srcDt;
            dataTSeries = loadtSeries(vw, scan, slice);

            if detrendFlag==1
                dataTSeries = convertToPercent(dataTSeries);
            end

            % scale the predictions to match the data
            trends = rmMakeTrends(P, 0);
            tSeries(:,:,slice) = scalePredictionToData(tSeries(:,:,slice), ...
                dataTSeries, trends(:,1));

            % re-save the scaled predictions (if this works well, I will
            % clean up this code, removing a lot of the flags, and always
            % do this regardless of whether we save residuals)
            vw.curDataType = tgtDt;

            % compute the residual: difference between data and prediction
            residual = dataTSeries - tSeries(:,:,slice);

            % save
            % TODO: Move this function to using viewGet
            vw.curDataType = resDt;
            residualFull = cat(dimNum + 1, residualFull, residual); %Combine together
            residualFull(slice) = residual;
        end
        savetSeries(tSeries, vw, tgtScan); %Already sends all the slices
        
        if dimNum == 3
            residualFull = reshape(residualFull,[1,2,4,3]);
        end %if
        
        savetSeries(residualFull, vw, resScan);

        % update dataTYPES
        % 		dataTYPES(resDt) = dtSet(dataTYPES(resDt), 'retinotopyModelParams', ...
        % 								P.stim(scan), scan);
        turnOffDetrending(vw, resDt);
        saveSession;
    end

    if prefsVerboseCheck==1
        fprintf('Saved predicted time series in %s scan %i.\n', dtName, tgtScan);
    end
end

fprintf('[%s]: Done. Total time %i min %2.0f sec.\n', mfilename, ...
    floor(toc/60), mod(toc, 60));


return


% ------
function ts = convertToPercent(ts)
% convert a set of time series to percent, following the steps in
% percentTSeries. (Divide by the mean, and convert to % signal
% change about the mean.)
ts = ts ./ repmat(mean(ts), [size(ts, 1) 1]);
ts = 100 .* (ts - 1);
ts = detrendTSeries(ts, -1);
return


% ------
function pred = scalePredictionToData(pred, data, trends)
% given a predicted time series, an observed time series, and a set of
% trends, scale the predictions to match the data. This tries to
% re-capitulate the scaling that is done to predicted time series in
% rmPlotGUI. (See rmPlotGUI_makePrediction, for the case where the
% recompute flag is 1.)
%
% The initial implementation of this is very slow -- it basically applies a
% GLM to each voxel in a long loop.

h_wait = mrvWaitbar(0, 'Scaling predictions to observed data...');

nVoxels = size(pred, 2);

for v = 1:nVoxels
    if any( isnan(pred(:,v)) | isinf(pred(:,v)) | isnan(pred(:,v)) | isinf(pred(:,v)) ) || ...
            length(unique(pred(:,v)))==1
        continue
    end

    beta = pinv([pred(:,v) trends]) * data(:,v);
    beta(1) = max(beta(1), 0); % enforce positive scaling

    vox_pred = [pred(:,v) trends] * beta;
    pred(:,v) = vox_pred(:,1);

    mrvWaitbar(v/nVoxels, h_wait);
end

close(h_wait);

return


% ------
function [resp, ok] = rmSavePredictionsParams
% Brings up a dialog for the user to set stimulus parameters
%
%  called by rmCalculatePredictions
%
%
% Example:
%
%
dlg(1).fieldName = 'dtName';
dlg(end).style = 'edit';
dlg(end).string = 'Data type to store predictions:';
dlg(end).value = 'Simulated';

dlg(end+1).fieldName = 'allTimePoints';
dlg(end).style = 'number';
dlg(end).string = 'Store all time points (1)? or store a single cycle (0)?';
dlg(end).value = 1;

dlg(end+1).fieldName = 'varthresh';
dlg(end).style = 'number';
dlg(end).string = 'Theshold voxels by variance explained';
dlg(end).value = 0.1;

dlg(end+1).fieldName = 'step';
dlg(end).style = 'number';
dlg(end).string = 'Num voxels to simulate at a time';
dlg(end).value = '1000';

dlg(end+1).fieldName = 'normToMeanSignal';
dlg(end).style = 'checkbox';
dlg(end).string = 'Scale tSeries to mean?';
dlg(end).value = 0;

dlg(end+1).fieldName = 'useBetas';
dlg(end).style = 'checkbox';
dlg(end).string = 'Scale pRFs by model betas (y) or to unit volume (n)?';
dlg(end).value = 0;

dlg(end+1).fieldName = 'savePercent';
dlg(end).style = 'checkbox';
dlg(end).string = 'Save as modulation about 100 (y) or 0 (n)?';
dlg(end).value = 1;

dlg(end+1).fieldName = 'detrendFlag';
dlg(end).style = 'checkbox';
dlg(end).string = 'Detrend predictions (removing mean)?';
dlg(end).value = 0;


dlg(end+1).fieldName = 'saveResiduals';
dlg(end).style = 'checkbox';
dlg(end).string = 'Save data residuals in a separate data type?';
dlg(end).value = 0;


[resp, ok] = generalDialog(dlg, mfilename);
if ~ok
    disp('User Aborted.')
    return;
end


return



