function dtiMrMeshScreenSave(handles,fname)
%
%  dtiMrMeshScreenSave(handles,fname)
%
%Author: Wandell, Dougherty
%Purpose:
%   Save whatever is in the dti mrMesh window to a file
%

rgb = mrmGet(handles.mrMesh,'screenshot')/255;
imwrite(rgb, fname);
disp(['Screenshot saved to ' fname '.']);

return;