function motionCompVisualizeMotion(view,scan,clip)
%
%   gb 02/28/02
%
%   motionCompVisualizeMotion(view,scan,clip)
%
% Plots consecutive frame difference on a 3D volume using the function
% motionCompPlot3Difference for all the consecutive. Press enter to go to
% the next frames. 
%
% Works only in Matlab 7
%

if ieNotDefined('scan')
    scan = viewGet(view,'curScan');
end

if ieNotDefined('clip')
    clip = 200;
end

global dataTYPES;

tSeriesAllSlices = motionCompLoadImages(view,scan);

nFrames = size(tSeriesAllSlices,1);
curType = viewGet(view,'currentDataType');
nVoxels = dataTYPES(curType).scanParams(scan).cropSize;
nSlices = size(tSeriesAllSlices,3);

tSeriesAllSlices = reshape(tSeriesAllSlices,[nFrames nVoxels nSlices]);

figure
f = gcf;

i = 1;
while (i <= 77) & (i > 0)
    motionCompPlot3Difference(squeeze(tSeriesAllSlices(i,:,:,:)),squeeze(tSeriesAllSlices(i + 1,:,:,:)),clip);
    text(1,nVoxels(2)-10,25,num2str(i));
    pause
    k = get(f,'CurrentCharacter');
    if k == 27
        close(f)
        return
    elseif k == char(28)
        i = i - 1;
    else
        i = i + 1;
    end
end
