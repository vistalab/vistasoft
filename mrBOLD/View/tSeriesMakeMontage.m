function view = tSeriesMakeMontage(view, scan, slices, frames)

%    view = tSeriesMakeMontage(view, [scan], [slices], [frames])
%
% gb 10/19/05
%
% Makes a movie of all slices at the same time within a scan. May have some
% memory issues in matlab 6.5 (R13)

% Initializes arguments and variables

global dataTYPES;
curType = viewGet(view,'curdatatype');

if ieNotDefined('scan')
    scan = viewGet(view,'curscan');
end

if ieNotDefined('slices')
    slices = dataTYPES(curType).scanParams(scan).slices;
end

if ieNotDefined('frames')
    frames = 1:dataTYPES(curType).scanParams(scan).nFrames;
end

% Loads the time series
for sliceIndex = 1:length(slices)
    curSlice = slices(sliceIndex);
    tSeriesAllSlices(:,:,sliceIndex) = loadtSeries(view,scan,curSlice);
end

% Initializes the variable m containing the movie
m_dims = size(makeMontage(reshape(squeeze(tSeriesAllSlices(1,:,:)),...
    [dataTYPES(curType).scanParams(scan).cropSize length(slices)])));
m = zeros(m_dims(1),m_dims(2),length(frames));

% Reshapes the time Series
for frameIndex = 1:length(frames)
    curFrame = frames(frameIndex);
    tSeries = reshape(squeeze(tSeriesAllSlices(curFrame,:,:)),...
        [dataTYPES(curType).scanParams(scan).cropSize length(slices)]);
    m(:,:,curFrame) = makeMontage(tSeries);
end

% Makes the movie from m
M = tSeriesMovie(view,scan,'',m);
