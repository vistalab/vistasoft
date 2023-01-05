function tSeriesAllSlices = motionCompLoadImages(view, scan, frames)

%   images = motionCompLoadImages(view, [scan], [frames])
% 
% gb 01/17/05
% 
% Loads the whole volume from scan and frames specified by the user
% Default : scan = current scan
%           frames = all frames of current scan
%

% Initializes arguments and variables
global dataTYPES

if notDefined('scan')
    scan = viewGet(view,'curScan');
end

nSlices = numberSlices(view,scan);
nFrames = numberFrames(view,scan);
nVoxels = sliceDims(view,scan);

if ieNotDefined('frames')
    frames = 1:nFrames;
end

tSeriesAllSlices = zeros(nFrames,prod(nVoxels),nSlices);

% For each slice, loads the time series into the variable tSeriesAllSlices
for curSlice = 1:nSlices
    tSeriesAllSlices(:,:,curSlice) = loadtSeries(view,scan,curSlice);
end

% Reshape it to have a 4D array: [frames sliceDimX sliceDimY slices]
tSeriesAllSlices = reshape(tSeriesAllSlices,[nFrames nVoxels nSlices]);
tSeriesAllSlices = tSeriesAllSlices(frames,:,:,:);
