function image = motionCompMeanImage(view, scans, frames)

%    function image = motionCompMeanImage(view, [scans], [frames])
% 
% gb 01/22/05
% 
% Finds the image closest to the mean image across frames for all scans
% Default : scans = current scan
%           frames = all frames

% Initilizes arguments and variables

global dataTYPES
curType = viewGet(view, 'curdatatype');

if ieNotDefined('scans')
    scans = 1:length(dataTYPES(curType).scanParams);
end
if ieNotDefined('frames')
    frames = 1:length(dataTYPES(curType).scanParams(scans(1)).nFrames);
end

% Computes the mean image
meanImage = motionCompComputeMean(view,scans,frames);

% Finds the image closest to the mean image
[scan,frame,mn] = motionCompNearestImage(view, scans, frames, meanImage);

% Loads this image
frame = frames(frame);
image = motionCompLoadImages(view,scan,frame);