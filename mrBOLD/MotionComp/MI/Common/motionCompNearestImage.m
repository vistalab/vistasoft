function [scan,frame,mn] = motionCompNearestImage(view, scans, frames, meanImage)
 
%    [scan,frame,mn] = motionCompNearestImage(view, [scans], [frames], [meanImage])
% 
% gb 01/22/05
% 
% Finds the image closest to the mean image. Returns the scan and the frame
% of this image and also its Mean Square Error with the mean image
% Default : scans = current scan
%           frames = all frames
%           meanImage = first frame of the first scan

% Initilizes arguments and variables
global dataTYPES

if ieNotDefined('scans')
    scans = viewGet(view,'curScan');
end
if ieNotDefined('frames')
    frames = 1:length(dataTYPES(curType).scanParams(scans(1)).nFrames);
end
if ieNotDefined('meanImage')
    meanImage = motionCompLoadImages(view,scans(1),1);
end


% In order to save memory, it is necessary to search for the image scan after scan. 
%       - If the input 'scans' is a single value, it returns the nearest image
%         for this scan.
%       - If the input 'scans' is an array, it calls it recursively scan
%         after scan and finds the nearest image among the different nearest images

if length(scans) == 1
    
    % If 'scans' is a single value
    % Loads the whole volume
    scan = scans;
    tSeriesAllSlices = motionCompLoadImages(view, scan);
    
    % Computes the Mean Square Error of the difference between the images
    % and the mean image
    MSE = motionCompMSE(tSeriesAllSlices(frames,:,:), meanImage);
    
    % Finds the minimum of this mean square error
    [mn,frame] = min(MSE);
    
    return
else
    
    % If 'scans' is an array
    % Initializes the variable
    results = zeros(length(scans),3);
    
    % Calls itself recursively scan after scan
    for scanIndex = 1:length(scans)
        scanNum = scans(scanIndex);
        
        fprintf('Searching nearest image in scan %d... ',scanNum);
        [results(scanIndex,1),results(scanIndex,2),results(scanIndex,3)] = ...
            motionCompNearestImage(view, scanNum, frames, meanImage);
        fprintf('Done\n');
    end
    
    % Finds the closest image among the images found in each scan
    [mn, baseScanIndex] = min(results(:,3));
    scan = results(baseScanIndex,1);
    frame = results(baseScanIndex,2);
    return
end