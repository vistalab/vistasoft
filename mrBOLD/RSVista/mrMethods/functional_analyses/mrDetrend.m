function mr = mrDetrend(mr,params);
% Detrend a time series MR object (4D data), convert to percent
% signal, and return the mr object.
%
%  mr = mrDetrend(mr,[params]);
%
% params: signal-processing parameters for tSeries. If omitted,
% there are two possibilities: first, checks if the mr object
% itself has signal processing parameters specified, and uses
% those if it does. Otherwise, uses default params specified in
% tSeriesParamsDefault.
%
% Note that after detrending, data are stored as doubles.
%
% ras, 07/25/05.
if notDefined('mr'), mr = mrLoad;                           end

if notDefined('params')
    if checkfields(mr(1),'params','tSeries')
        params = mr(1).params.tSeries;
    else
        params = tSeriesParamsDefault;   	
    end
end

if size(mr.data,4) <= 1,
    warning('mrDetrend called for data without a time dimension.');
    return
end

% if struct array is passed, detrend iteratively:
if length(mr)>1,
    for i = 1:length(mr), mr(i) = mrDetrend(mr(i),params); return; end
end

% convert data to tSeries format (time by voxels):
nVoxels = prod(mr.dims(1:3)); nFrames = mr.dims(4);
mr.data = reshape(permute(mr.data,[4 1 2 3]),[nFrames nVoxels]);

% detrend
mr.data = tSeriesDetrend(mr.data,params);

% convert back to 4D volume
mr.data = reshape(mr.data',mr.dims);

return
