function dtiSaveMesh(handles)
%
%   dtiSaveMesh(handles)
%
%Author: Wandell
%Purpose:
%   Save the current dti mrMesh structure along with the data required to
%   display the current view.  We plan to adjust mrmViewer so that it
%   displays these meshes, just as it displays the mrVista meshes. 
%
%   This routine and the mrmViewer are not yet complete.
%

%   Programming notes.  
%   Should we write a dtiLoadMesh, too?  That might not be necessary
%   because, well, we should always be able to display from the current
%   data and ....
%

if ieNotDefined('handles'), error('dtiFiberUI handles required.'); end

% Figure out the file
persistent meshPath;
if(isempty(meshPath)) imPath = fullfile(handles.defaultPath, 'slice'); end
[f, p] = uiputfile({'*.mat';'*.*'}, ['Save current mesh...'], meshPath);
if(isnumeric(f)), disp('dtiSaveMesh cancelled.'); return; end
fname = fullfile(p, f);
meshPath = fname;

mrMesh = dtiGet(handles,'mrmesh');

%  Other variables need to be pulled out of the data, too.  These variables
%  need to be stored in the data file so that the subsequent mrmViewer can
%  display them with the dtiMrMesh3AxisImage call.
save(fname,'mrMesh');

return;