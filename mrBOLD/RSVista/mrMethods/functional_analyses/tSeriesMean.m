function tSeries = tSeriesMean(mr,coords,params);
% Compute the mean time series across voxels for a set of
% 4-D mr data. 
%
% tSeries = tSeriesMean(mr,coords,[params]);
%
% Can concatenate across multiple mr objects after applying 
% detrending as specified in the params struct.
%
% mr: mr object(s) -- loaded struct, file path, or cell array.
% coords: 3xN set of coordinate across which to average.
% params: tSeries-related detrending parameters. These may be
%   attached to an mr object in the field mr.params.tSeries.
%   If params are omitted as an argument, looks in the mr object
%   for the params. If it can't find it there, uses default params
%   stored in tSeriesParamsDefault.
%
%
% ras, 10/2005.
if nargin<2, help(mfilename); error('Not enough args.');    end
if notDefined('params')
    if checkfields(mr(1),'params','tSeries') % get from mr object
        params = mr(1).params.tSeries;
    else
        params = tSeriesParamsDefault;
    end
end

% parse input args.
mr = mrParse(mr);
if isstruct(coords) & isfield(coords,'coords')
    % an ROI struct was passed -- get the coords
    coords = coords.coords;
end

% get indices of voxels cooresponding to coords
% (this assumes that, in the case of multiple mr objects,
% they all have the same dimensions.)
coords = round(coords);
ind = sub2ind(mr(1).dims(1:3),coords(1,:),coords(2,:),coords(3,:));

% loop across mr objects ('scans'), detrending and concatenating
% tSeries data.
tSeries = [];
for i = 1:length(mr)
    % get # of frames, voxels in data for this scan.
    nFrames = mr(i).dims(4);
    nVoxels = prod(mr(i).dims(1:3));
    
    % reshape data to tSeries format: time x voxels.
    subdata = reshape(mr(i).data,[nVoxels nFrames])';
    
    % get subset of data
    subdata = subdata(:,ind);
    
    % detrend if specified.
    if params.detrend~=0, subdata = tSeriesDetrend(subdata,params); end
    
    % add to tSeries.
    tSeries = [tSeries; subdata];
end

% average across voxels
tSeries = nanmean(tSeries,2);

return
