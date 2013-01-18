function [vw ROI] = roiDilate(vw, ROI, radius, name, color)
%
% Dilate an ROI by convolving the ROI coordinates in 3D with a sphere of
% specified radius
%
% [vw ROI] = roiDilate([vw=getCurView], [ROI=selectedROI], ...
%   [radius=user dialog, [name='dilatedROI'], [color='w'])
%
%   INPUTS:
%       vw:  mrVista view struct. must be gray view. 
%                   [default = getCurView]
%       ROI: index to ROI in current view, or ROI struct
%                   [default = selectedROI]
%       radius: radius of sphere to convolve with ROI, in mm.
%                   [default = query user with dialog]
%       name:   str to name new ROI
%                   [default = 'dilatedROI']
%       color:  color of new ROI (triplet in [0 1] or single color
%                   character such as 'w' 'r' 'g' etc. Somewhere Matlab
%                   defines these. [default = 'w']
%   OUTPUTS
%       vw: new view struct, with ROI added
%       ROI: struct of dilated ROI
%
%  Example (1). Use default parameters
%   roiDilate
%  Example (2). Specify parameters
%   [vw myNewROI] = roiDilate(vw, 1, 3, 'myNewROI', 'g');
%
% Works only in gray view.
%
% JW, 1/2012
%% Check inputs

% View struct - must be gray view
if notDefined('vw'),  vw = getCurView; end
if ~strcmpi(viewGet(vw, 'view type'), 'gray')
    error('[%s]: Gray view required.', mfilename);
end

% Radius of sphere in mm. Perhaps we should add a default of radius = 1
% voxel instead of a dialog? 
if notDefined('radius'), 
%     radius =str2double(inputdlg('How large a dilation of your ROI (radius of sphere in mm)?'));
    radius = 1;
else
    radius = round(radius);
end

% Name and color of new ROI. In principle we could also allow comments.
if notDefined('name'),  name  = 'dilatedROI'; end
if notDefined('color'), color = 'w';          end

% ROI. can be integer index into vw.ROIs or the ROI struct
if notDefined('ROI'), 
    [ROI, radius, name, color, ok] = roiDilateGUI(vw);
end

if ischar(color),       color = color(1);     end

%% Convert the ROI coords from 3xn array to binary 3D image

% Anatomy size in voxels (not mm)
sz      = viewGet(vw, 'anat size');

% Get some parameters about the ROI of interest
vw      = viewSet(vw, 'selected ROI', ROI);
coords  = viewGet(vw, 'ROI coords');
roiName = viewGet(vw, 'ROI name');

x    = coords(1,:);
y    = coords(2,:);
z    = coords(3,:);
inds = sub2ind(sz, x, y, z);% convert ROI coorindates (3xn) into binary 3D image 

im       = false(sz);
im(inds) = 1;


%% Convolve ROI image with sphere
% create a sphere which we will use to dilate the ROI
[a, b, c] = meshgrid(-radius:radius, -radius:radius,-radius:radius);
convel = a.^2+b.^2+c.^2 <= radius^2;

% ----------------------------------------------------------
% this is the main step (dilation), which might be very slow
dilatedIm = convn(double(im), convel, 'same') >= 1; % ------
% -----------------------------------------------------------


%% Convert back to 3xn coordinates and add to view struct

% now convert the dilated ROI from a 3D binary image to a set of 3xn
% coordinates
dilatedInds = find(dilatedIm);

[x y z] = ind2sub(sz, dilatedInds);

dilatedCoords = [x'; y'; z'];

% add some comments. (perhaps this should be an optional input to this
% function?)
comments = sprintf('ROI created by dilating ROI "%s" with sphere of radius %f mm, %s', roiName, radius, datestr(now, 'yyyy.mm.dd HH:MM:SS'));

% finally, add the new ROI to the current view struct, and return the view
% and the new ROI
vw = newROI(vw, name, [], color, dilatedCoords, comments);
ROI = viewGet(vw, 'ROI struct');

return


% /-------------------------------------------------------------/ %
function [ROI, radius, name, color, ok] = roiDilateGUI(vw)

colorList = {'blue' 'red' 'green' 'yellow' 'magenta' 'cyan' ...
			 'white' 'kblack' 'user'};

colorChar = char(colorList)';
if ~isempty(vw.ROIs)
    for iROI = 1:length(vw.ROIs); roiNameList{iROI} = vw.ROIs(iROI).name; end;
    defROINum = vw.selectedROI;
%     defColorNum = findstr(vw.ROIs(defROINum).color, colorChar);
else % if no ROI -- pop up empty.
    roiNameList = {''};
    defROINum = 1; defColorNum = 1;
end

c=1;
dlg(c).string = 'Target ROI:';
dlg(c).fieldName = 'ROI';
dlg(c).list = roiNameList;
dlg(c).style = 'popupmenu';
dlg(c).value = max(defROINum,1); % default: combine selectedROI with the one before it on list.

c=2;
dlg(c).string = 'Dilation (mm):';
dlg(c).fieldName = 'radius';
dlg(c).style = 'number';
dlg(c).value = '1';

c=3;
dlg(c).string = 'Name of dilated ROI:';
dlg(c).fieldName = 'name';
dlg(c).style = 'edit';
dlg(c).value = strcat(roiNameList(max(defROINum,1)),'_1mm-dilated');

c=4;
dlg(c).string = 'Color of dilated ROI:';
dlg(c).fieldName = 'color';
dlg(c).list = colorList;
dlg(c).style = 'popupmenu';
dlg(c).value = 1;

[resp, ok] = generalDialog(dlg, 'ROI dilation');
ROI = resp.ROI;
voxsize = viewGet(vw, 'voxsize');
radius = round(resp.radius / voxsize(1));
name = resp.name{1};
color = resp.color;

return;
