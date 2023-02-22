function [meanImage] = motionCompComputeMean(view, scans, frames)
 
%    meanImage = motionCompComputeMean(view, [scans], [frames])
% 
% gb 01/22/05
% 
% Computes mean image across frames for all scans
% Default : scans = current scan
%           frames = all frames

% Initilizes arguments and variables
global dataTYPES
curType = viewGet(view,'curdatatype');

if ieNotDefined('scans')
    scans = viewGet(view,'curScan');
end
if ieNotDefined('frames')
    frames = 1:(dataTYPES(curType).scanParams(scans(1)).nFrames);
end

nVoxels = sliceDims(view,scans(1));
nSlices = numberSlices(view,scans(1));


% In order to save memory, it is necessary to compute the mean scan after scan. 
%       - If the input 'scans' is a single value, it returns the mean image
%         across this scan.
%       - If the input 'scans' is an array, it calls it recursively scan
%         after scan and computes the mean of the different mean images

if length(scans) == 1
    
    % If 'scans' is a single value
    % Loads the whole volume
    scan = scans;
    tSeriesAllSlices = motionCompLoadImages(view, scan);    
    
    % Computes the mean image across frames for this scan
    meanImage = mean(tSeriesAllSlices(frames,:,:,:),1);
    
    return
    
else
    
    % If 'scans' is an array
    % Initializes the variable
    meanImages = zeros([length(scans) nVoxels nSlices]);

    % Calls itself recursively scan after scan
    for scanIndex = 1:length(scans)
        scanNum = scans(scanIndex);
        
        fprintf('Computing mean for scan %d... ',scanNum);
        [meanImages(scanIndex,:,:,:)] = motionCompComputeMean(view, scanNum, frames);
        fprintf('Done\n');
    end
    
    % Computes the mean of the mean images
    meanImage = mean(meanImages,1);
    
    return
end