function [xIm,yIm,zIm] = dtiMrMeshSelectImages(handles,xIm,yIm,zIm)
% Read radio buttons to determine slices are selected for display
%
%  [xIm,yIm,zIm] = dtiMrMeshSelectImages(handles,xIm,yIm,zIm);
%
% If the radio button is not selected, then set the image to null so that
% it will not be displayed.
%
% Stanford VISTA Team

if ~get(handles.rbSagittal,'Value'), xIm = []; end
if ~get(handles.rbCoronal,'Value'),  yIm = []; end
if ~get(handles.rbAxial,'Value'),    zIm = []; end

return;