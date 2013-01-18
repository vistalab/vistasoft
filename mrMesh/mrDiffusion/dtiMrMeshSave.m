function dtiMrMeshSave(handles)
% Save the dti mesh structure and data required for mrmViewer.
%
%   dtiMrMeshSave(handles)
%
% The mrmViewer code should be:
%
%   load Test
%   msh = dtiGet(handles,'mrMesh'); 
%   msh.id = 101;   % Set up a number for the window
%   mrmSet(msh,'refresh');
%   msh = dtiInitMrMeshWindow(msh);
%   dtiMrMeshAddROIs(handles,msh);
%   dtiMrMeshAddFGs(handles,msh);
%   dtiMrMeshAddImages(handles,msh,origin,xIm,yIm,zIm);
%
% %Author: Wandell
% (c) Stanford VISTA Team

%   Programming notes.  
%   Should we write a dtiLoadMesh, too?  That is not necessary, really,
%   because we should always be able to display from the current
%   data and ....
%

if notDefined('handles'), error('dtiFiberUI handles required.'); end

% Figure out the file
persistent meshPath;
if(isempty(meshPath)), meshPath = fullfile(handles.defaultPath, 'slice'); end
[f, p] = uiputfile({'*.mat';'*.*'}, 'Save current mesh...', meshPath);
if(isnumeric(f)), disp('dtiSaveMesh cancelled.'); return; end
fname = fullfile(p, f);
meshPath = fname;

% Get all of the potential images
anat = dtiGet(handles,'currentanatomydata');
curPosition  = dtiGet(handles,'curposition');
curXform = dtiGet(handles,'curacpcxform');
zIm = dtiGetSlice(curXform, anat, 3, curPosition(3));
yIm = dtiGetSlice(curXform, anat, 2, curPosition(2));
xIm = dtiGetSlice(curXform, anat, 1, curPosition(1));

% Empty out the images not needed for display
[xIm,yIm,zIm] = dtiMrMeshSelectImages(handles,xIm,yIm,zIm); %#ok<NASGU>
origin = dtiGet(handles,'origin'); %#ok<NASGU>

% Make the data size manageable by getting rid of the big variables
handles = rmfield(handles,'dt6');
%handles = rmfield(handles,'vec');
handles = rmfield(handles,'bg');

if isfield(handles,'t1NormParams')
    handles = rmfield(handles,'t1NormParams');
end
handles = rmfield(handles,'brainMask'); %#ok<NASGU>

% Save the file for mrmViewer
save(fname,'handles','origin','xIm','yIm','zIm');

return;