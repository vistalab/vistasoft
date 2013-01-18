function fname = dtiMrMeshScreenShot(handles,fname)
%
%  fname = dtiMrMeshScreenShot(handles,fname)
%
%Author: Wandell, Dougherty
%Purpose:
%   Write out the current view in mrMesh
%

persistent pathname;
% Numeric can occur after the user cancels
if isempty(pathname) | isnumeric(pathname), pathname = pwd; end

if ieNotDefined('fname')
    fileFilter = fullfile(pathname,'*.png');
    [filename, pathname] = uiputfile(fileFilter, 'Pick a file name.');
    if ~filename, fname = []; return; 
    else fname = fullfile(pathname,filename);
    end
end

[p,n,e] = fileparts(fname);
if ~strcmp(e,'.png'), e = '.png'; end
fname = fullfile(p,[n,e]);

% Hmmm.  Always hide the cursor here?  Maybe the user wants the cursor?
mrmSet(handles.mrMesh, 'cursoroff');

dtiMrMeshScreenSave(handles,fname);

return;
