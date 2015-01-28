function roi = dtiRoiClean(roi, smoothKernel, flags)
% 
% roi = dtiRoiClean(roi, smoothKernel, flags)
%
% Cleans up a dti ROI. Flags is a cellarray of strings specifying various
% flags. The presence of a flag turns that option on, the absence turns it
% off. If nargin<3, the user will be prompted. Flags include:
%   * 'removeSatellites'
%   * 'fillHoles'
%   * 'dilate'
%
% smoothKernel defines the size of the convolution kernel (in voxels). Set
% to 0 for no smoothing. Can be a 1x3 (eg. [6,6,4] or a scalar for a
% symmetric kernel. Defaults to [3,3,3].
%
%
% Example: 
%    roi    = dtiRoiClean(roi);
%    roi    = dtiRoiClean(roi,3,['fillholes', 'dilate', 'removesat']);
%
% (c) 2012  Stanford VISTA team.

if(nargin<2)
    smoothKernel = 3;
    removeSatellites = 1;
    fillHoles = 1;
    dilate = 0;
    baseName = [roi.name '_cleaned'];
    resp = inputdlg({'smoothing kernel (0 for none):',...
        'remove satellites (0|1):','fill holes (0|1):','dilate (0|1):','Cleaned ROI name:'}, ...
    ['Clean ROI ' roi.name], 1, {num2str(smoothKernel), ...
        num2str(removeSatellites), num2str(fillHoles), num2str(dilate), baseName});
    if(isempty(resp)), disp('user cancelled.'); return; end
    smoothKernel     = str2num(resp{1});
    removeSatellites = str2num(resp{2});
    fillHoles        = str2num(resp{3});
    dilate           = str2num(resp{4});
    roi.name         = resp{5};
else
    fillHoles        = 0;
    removeSatellites = 0;
    dilate           = 0;
    if(nargin>2)
        flags = lower(flags);
        if(sum(strcmp(flags,'fillholes'))>0),  fillHoles        = 1; end
        if(sum(strcmp(flags,'removesat'))>0), removeSatellites = 1; end
        if(sum(strcmp(flags,'dilate'))>0),    dilate           = 1; end
    end
end

%% Get the ROI coordinates and the bounding box.
coords = roi.coords;
%bb = dtiGet(0, 'defaultBoundingBox');
bb = [floor(min(coords))-10; ceil(max(coords))+10];
roiMask = zeros(diff(bb)+1);
% Remove coords outside the bounding box
badCoords = coords(:,1)<=bb(1,1) | coords(:,1)>=bb(2,1) ...
       | coords(:,2)<=bb(1,2) | coords(:,2)>=bb(2,2) ...
       | coords(:,3)<=bb(1,3) | coords(:,3)>=bb(2,3);
coords(badCoords,:) = [];
% Convert from acpc space to matlab image space
%coords = mrAnatXformCoords(inv(dtiGet(handles, 'acpcXform')), coords);
coords(:,1) = coords(:,1) - bb(1,1) + 1;
coords(:,2) = coords(:,2) - bb(1,2) + 1;
coords(:,3) = coords(:,3) - bb(1,3) + 1;
coords = round(coords);

%% Build an image out of the ROI coordinates.
% Hereafter we can work with the image processing tools.
roiMask(sub2ind(size(roiMask), coords(:,1), coords(:,2), coords(:,3))) = 1;
roiMask = imclose(roiMask,strel('disk',2));
clear coords;

%% Fill holes in the ROI
if(fillHoles), roiMask = imfill(roiMask,'holes'); end

%% Smooth the edges of the ROI
roiMask = dtiSmooth3(roiMask, smoothKernel);

%% Dilate the ROI
if(dilate~=0)
    if(dilate>0),  roiMask = roiMask>0.005;
    else           roiMask = roiMask>0.9; end
    if(fillHoles), roiMask = imfill(roiMask,'holes'); end
else
    roiMask = roiMask>0.5;
end

%% Remove satellites of the ROI
% FIXME! dtiCleanImageMask removes satalites AND fills holes. We should
% split these functions.
if(removeSatellites), roiMask = dtiCleanImageMask(roiMask, 0)>0.5; end

%% Re-build the ROI coordinates from the image of the ROI
[coords(:,1), coords(:,2), coords(:,3)] = ind2sub(size(roiMask), find(roiMask));
coords(:,1) = coords(:,1) + bb(1,1) - 1;
coords(:,2) = coords(:,2) + bb(1,2) - 1;
coords(:,3) = coords(:,3) + bb(1,3) - 1;
%coords = mrAnatXformCoords(dtiGet(handles, 'acpcXform'), coords);

%% Save out the ROI
roi.coords = coords;
return;