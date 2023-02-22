function ui = mrViewSelectMesh(ui, n);
% Select a mesh (and its corresponding segmentation) in a mrViewer UI.
%
%  ui = mrViewSelectMesh(ui, [n=dialog]);
%
% This is an accessor function, originally designed to work with the mesh
% panel in the mrViewer GUI. This is as an alternative to the lower-level
% command line call "ui = mrViewSet(ui, 'curmesh', n);" -- this calls that
% code -- and works outside the mesh menu. 
%
% Mainly, I wanted to make using the interface easier while keeping the
% design of the UI data structure conceptually sensible. So, now in the
% mesh panel you can select from all meshes loaded, without having to
% sub-select the segmentation they belong to: easier. But the UI variable
% still has discrete segmentations, with meshes which belong to a given
% segmentation, which better corresponds to the distinct files which exist
% and which is cleaner.
%
% INPUTS:
%	ui: mrViewer ui.
%
%	n: number or name of mesh. For number, this will sort the meshes across
%	all segmentations, and n should be an index into that
%	across-segmentation list. For name, should be the name the mesh ID as a 
%	string -- I know that's unusual, but it seems that mesh ID (the window number 
%	in the mrMesh window) is a better unique identifier for each mesh than the 
%	name, and having it be a string is the only clean way to distinguish
%	indices from mesh ID numbers.
%	[default: put up a dialog with the names and ask the user.]
%
%
% OUTPUTS: ui with the selected mesh set as the current mesh, and the
% segmentation to which that mesh belongs set as the current segmentation
%
% ras, 09/2008.
if notDefined('ui'),	ui = mrViewGet;					end
if ishandle(ui),		ui = get(ui, 'UserData');		end
if notDefined('n'),		n = mrViewSelectMeshDialog(ui);	end

if isempty(n)
	warning('No mesh selected. Doing nothing.')
	return
end

%% get a list of all meshes across segmentations
meshList = mrViewGet(ui, 'MeshList');
if isempty(meshList)
	warning('No meshes loaded.')
	return
end

% find the segmentation # corresponding to each mesh, and the index of each
% mesh within that segmentation
segNum = [];  % for each mesh, the # of the corresponding segmentation
meshNum = [];  % mesh # within the segmentation
for s = 1:length(ui.segmentation)
	for m = 1:length(ui.segmentation(s).mesh)
		id = ui.segmentation(s).mesh{m}.id;
		meshIndex = strmatch( num2str(id), meshList );
		segNum(meshIndex) = s;
		meshNum(meshIndex) = m;
	end
end

%% get the # for the segmentatation, and # for the mesh within that
%% segmentation's meshes
% is n a numeric index, or a mesh name? (If name, convert to index)
if ischar(n)
	n = strmatch(n, meshList);
end

nSeg = segNum(n);
nMesh = meshNum(n);

%% select the segmentation and mesh
ui = mrViewSet(ui, 'SelectedSegmentation', nSeg);
ui = mrViewSet(ui, 'SelectedMeshNum', nMesh);

return
% /-----------------------------------------------------------/ %



% /-----------------------------------------------------------/ %
function [n ok] = mrViewSelectMeshDialog(ui);
%% dialog to get a mesh name from a list of all loaded meshes.
dlg.fieldName = 'selectedMesh';
dlg.style = 'listbox';
dlg.list = mrViewGet(ui, 'MeshList');
dlg.value = 1;
dlg.string = 'Select which surface mesh?';

[resp ok] = generalDialog(dlg, mfilename);
if ~ok
	n = [];
	return
end
n = str2num(resp.fieldName);

return


