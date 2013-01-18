function tSeries = tSeriesDetrend(tSeries,params,varargin);
% Detrend time series data, and convert to percent signal,
% according to specified parameters.
%
% tSeries = tSeriesDetrend(tSeries,[params],[spatialGrad or stim]);
%
% tSeries: 2-D matrix of data, format time x voxels.
%
% params: uses tSeriesParamsDefault if omitted.
%
% spatialGrad: used only in the case that inhomoCorrect is set to
% 3 (divide by external data -- usually robust estimate of spatial
% gradient). Should be an mr object or path to an mr file.
% Alternately, if inhomoCorrect = 2 (divide by null condition),
% the third argument should be a STIM struct or a path to a .par file
% (see stimLoad, stimFormatDescription).
%
% Since in using mrVista 1.0 I've found detrending to be
% highly correlated to converting to percent signal, (and since
% the most commonly used method of boxcar smoothing automatically
% sets the tSeries to mean zero anyway), this function actually
% does both steps. If it becomes necessary down the line to
% dissociate the two, this can be broken up later.
%
% Also does temporal normalization if selected -- this is where each
% time frame is set to have the same mean.
%
% ras, 10/2005. Uses code from mrVista 1.0 percentTSeries,
% detrendTSeries, and doTemporalNormalization.
if nargin<1, help(mfilename); error('Not enough args.');    end
if notDefined('params'), params = tSeriesParamsDefault;     end
if ~isa(tSeries,'double'), tSeries = double(tSeries);       end

[nFrames, nVoxels] = size(tSeries);


% % (1) perform temporal normalization if selected
% if params.temporalNormalization==1
%     mu = mean(tSeries,2); % Mean of each frame
%     fprintf('Normalized tSeries to first frame (mean val=%.05f)\n',mu(1));
%     tSeries = (tSeries./repmat(mu,1,nVoxels))*mu(1);
% end

% (2) convert to percent signal
switch params.inhomoCorrect
    case 0,      return; % 0 do nothing

    case 1,      % 1 divide by the mean, independently at each voxel
        dc = mean(tSeries);
        tSeries = tSeries./(ones(nFrames,1)*dc);

    case 2,      % 2 divide by null condition
        % not yet implemented
        warning(['Inhomogeneity correction by null condition '...
            'not yet implemented.']);

    case 3,     % 3 divide by anything you like;
        % e.g., robust estimate of spatial gradient
        if ~exist('spatialGrad','var'),
            help(mfilename);
            msg = ['The selected inhomoCorrect option requres an '...
                'additional argument.'];
            error(msg);
        end
        spatialGrad = mrParse(spatialGrad);
        dc = spatialGrad.data(1:size(tSeries,2))';
        tSeries = tSeries./(ones(nFrames,1)*dc);

    otherwise, error('Invalid inhomogeneity correction parameter.');
end

% (3) detrend
switch params.detrend
    case 0, return; % 0: Don't Detrend

    case 1,        % 1: Detrend w/ multiple boxcar smoothing
        tSeries = boxcarSmooth(tSeries,params.detrendFrames);

    case 2,         % 2: Linear Trend Removal
        nFrames = size(tSeries,1);
        model = [(1:nFrames); ones(1,nFrames)]';
        wgts = model\tSeries;
        fit = model*wgts;
        tSeries = tSeries - fit;

    case 3,         % 3: Quartic Trend Removal
        nFrames = size(tSeries,1);
        model = [(1:nFrames).*(1:nFrames); (1:nFrames); ones(1,nFrames)]';
        wgts = model\tSeries;
        fit = model*wgts;
        tSeries = tSeries - fit;

    otherwise, error('Invalid detrending parameter.');
end



% (4) subtract the mean if selected
if ~isfield(params,'subtractMean') | params.subtractMean==1,
    nFrames = size(tSeries,1);
    tSeries = tSeries - ones(nFrames,1)*mean(tSeries);
    tSeries = 100*tSeries; % convert to percent signal change
end

return