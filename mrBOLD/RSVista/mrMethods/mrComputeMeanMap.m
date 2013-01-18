function mr = mrComputeMeanMap(mr,savePath);
% Compute the mean image in an fMRI time series.
%
% mr = mrComputeMeanMap(tSeries,[savePath]);
%
% tSeries is an mr object containing tSeries data, mr is
% an mr object w/ the mean map.
%
% If savePath is provided, the mean image will be saved in 
% that directory under the name 'Mean Map'.
%
% ras, 10/2005.
if notDefined('mr'), mr = mrLoad; end

if iscell(mr),
    % run a corAnal on each mr object
    for i = 1:length(mr)
        [ph{i}, co{i}, amp{i}] = mrComputeCorAnal(mr{i},params);
    end
    return
end

% load any paths specified as strings
if ischar(mr), mr = mrLoad(mr);     end

% check to make sure this is actually a time series -- the 4th dim > 1
if size(mr.data,4) <= 1
    error('Non-time-series mr data specified.')
end

% reshape into tSeries format: time points x voxels
nVoxels = prod(mr.dims(1:3));
nFrames = size(mr.data,4);
mr.data = permute(mr.data,[4 1 2 3]);
mr.data = reshape(mr.data,[nFrames nVoxels]);

% take the mean across time, shape into mean map
mr.name = sprintf('Mean of %s',mr.name);
mr.data = nanmean(mr.data);
mr.data = reshape(mr.data,mr.dims(1:3));
mr.dims(4) = 1; % remove 4th dimension
mr.voxelSize(4) = 1;
mr.extent(4) = 1;
mr.path = fullfile(fileparts(mr.path),'Mean Map');

if exist('savePath','var') & exist(savePath,'dir')
    mrSave(mr,fullfile(savePath,'Mean Map'));
elseif exist('savePath','var') & exist(savePath,'file')
    mrSave(mr,savePath);
end

return