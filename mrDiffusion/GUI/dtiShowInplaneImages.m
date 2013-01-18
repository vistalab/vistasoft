function handles = dtiShowInplaneImages(handles,xSliceAxes,xSliceRgb,ySliceAxes,ySliceRgb,zSliceAxes,zSliceRgb)
%   Display the images in the main Matlab mrDiffusion (dtiFiberUI) window.
%
%   dtiShowInplaneImages(handles,xSliceAxes,xSliceRgb, ...
%      ySliceAxes,ySliceRgb,zSliceAxes,zSliceRgb)
%
% See also: dtiGetCurSlices
%
% HISTORY:
%  Authors: Dougherty, Wandell
%  2006.11.09 RFD: we now save and reset the axis limits, in case the use
%  has zoomed in on an axis.
%
% Stanford VISTA Team

% Axial slice.  The z-dimension is the inferior/superior
axes(handles.z_cut);
% We don't want to reset the axis limit when the figure is first
% initialized, so we do a simple test for that initial condition.
if(isempty(get(handles.z_cut,'Children')))
    handles.z_cut_img = image(zSliceAxes(1,:), zSliceAxes(2,:), zSliceRgb);
    axis(handles.z_cut, 'equal', 'tight', 'xy');
else
    a = axis(handles.z_cut);
    handles.z_cut_img = image(zSliceAxes(1,:), zSliceAxes(2,:), zSliceRgb);
    axis(handles.z_cut, 'equal', 'tight', 'xy', a);
end
ylabel('Y (mm)'); xlabel('X (mm)');

% Coronal slice.
axes(handles.y_cut);
ySliceRgb = permute(ySliceRgb,[2,1,3]);
if(isempty(get(handles.y_cut,'Children')))
    handles.y_cut_img = image(ySliceAxes(1,:), ySliceAxes(2,:), ySliceRgb);
    axis(handles.y_cut, 'equal', 'tight', 'xy');
else
    a = axis(handles.y_cut);
    handles.y_cut_img = image(ySliceAxes(1,:), ySliceAxes(2,:), ySliceRgb);
    axis(handles.y_cut, 'equal', 'tight', 'xy', a);
end
ylabel('Z (mm)'); xlabel('X (mm)');

% Sagittal slice.
% We want the x-cut (sagittal view) to have the nose to the left
axes(handles.x_cut);
xSliceRgb = permute(xSliceRgb,[2,1,3]);
if(isempty(get(handles.x_cut,'Children')))
    handles.x_cut_img = image(xSliceAxes(1,:), xSliceAxes(2,:), xSliceRgb);
    axis(handles.x_cut, 'equal', 'tight', 'xy');
else
    a = axis(handles.x_cut); 
    handles.x_cut_img = image(xSliceAxes(1,:), xSliceAxes(2,:), xSliceRgb);
    axis(handles.x_cut, 'equal', 'tight', 'xy', a);
end
ylabel('Z (mm)'); xlabel('Y (mm)');

return;