function settings = meshMatchSettings(src, tgt, varargin);
% Adjust the view settings on one or more target meshes to match that on
% the source mesh.
%
%   settings = meshMatchSettings([sourceMesh=current mesh], [targetMeshes], [gray/volume view]);
%
% INPUTS:
%	sourceMesh: mesh whose view settings you want to replicate on other
%	meshes. You can provide a mesh structure, the number of a mesh in the
%	current gray view, or the number of the mesh window as a character (e.g.,
%	use '1' for a mesh window named 'mrMesh 1', but use 1 for the
%	first mesh in the view). [Default: selected mesh in gray view].
%
%	targetMeshes: specification of one or more meshes whose view settings
%	will match that of the source mesh. Can be specified in the same way as
%	sourceMesh. If you want to specify multiple target meshes, you can
%	specify them as a cell array (or, in the case of numeric mesh indexes,
%	a numeric array, or a struct array in the case of full mesh strucures). 
%	[Default: prompt user to select meshes].
%
%	[gray/volume view]: a gray or volume view structure which has the
%	relevant meshes loaded. This isn't needed if you're providing the full
%	mesh structures as inputs. [Default: use selected gray view]
%	
% RETURNS:
%	settings: settings structure from the source mesh.
% 
% SEE ALSO: meshSettings, meshStoreSettings, meshRetrieveSettings.
%
% ras, 08/2009.

% I allow several target meshes to be input as varargin (allowing me to type the
% IDs as strings): the view G is always the last of these, if it's specified.
if ~isempty(varargin)
	if isstruct(varargin{end})
		G = varargin{end};
	else
		G = [];
	end
	tgt = [{tgt} varargin];
end

if notDefined('G')
	% don't call getSelectedGray if both src and target are provided as
	% structures -- we don't want to force this code to depend on the
	% mrVista data structure if we don't need to.
	if ( isstruct(src) | (iscell(src) & isstruct(src{1})) ) & ...
		( isstruct(tgt) | (iscell(tgt) & isstruct(tgt{1})) ) 	
		G = [];
	else
		G = getSelectedGray;				
	end
end

if notDefined('src'),	    
	src = G.mesh{G.meshNum3d};			
end

% parse the source mesh structure
if ~isstruct(src)
	src = parseMeshStructure(src, G);
end

% get the source mesh settings
settings = meshSettings(src);

if notDefined('tgt'),
	% user dialog
	dlg.fieldName = 'whichMeshes';
	dlg.style = 'listbox';
	dlg.string = sprintf(['Apply Mesh Settings from Mesh %i to which ' ...
						  'other meshes?'], src.id);
	for n = 1:length(G.mesh)
		dlg.list{n} = [num2str(G.mesh{n}.id) '. ' G.mesh{n}.name];
	end
	dlg.value = 1;
	
	[resp ok] = generalDialog(dlg, mfilename);
	if ~ok, fprintf('[%s]: User aborted.\n', mfilename); return; end
	
	for n = 1:length(resp.whichMeshes)
		tgt(n) = cellfind(dlg.list, resp.whichMeshes{n});
	end
end			

% parse the target mesh specification
if ~ischar(tgt) & length(tgt) > 1
	% iteratively apply to several meshes
	for n = 1:length(tgt)
		if iscell(tgt)
			currTarget = parseMeshStructure(tgt{n}, G);
		else
			currTarget = parseMeshStructure(tgt(n), G);
		end
		meshApplySettings(currTarget, settings);
	end
	
else
	tgt = parseMeshStructure(tgt, G);
	meshApplySettings(tgt, settings);
	
end

return
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function msh = parseMeshStructure(msh, G);
% given a mesh specification (which could be one of many things) and a view
% with meshes, return a mesh structure.
if isstruct(msh), 
	% we're good...
	return;
end

if iscell(msh)
	for n = 1:length(msh)
		msh(n) = parseMeshStructure(msh{n}, G);
	end
	return
end

if ischar(msh)
	% id of mesh window ... find it in this view:
	targetID = str2num(msh);
	for n = 1:length(G.mesh)
		ids(n) = G.mesh{n}.id;
	end
	msh = find(ids==targetID);
	if isempty(msh)
		error('Couldn''t find mesh id %i in view.', targetID);
	end
	
	% now it's numeric, so it should go through the indexing code below...
end 

if isnumeric(msh)
	% numeric index into G's meshes
	whichMeshes = msh;  clear msh
	for n = 1:length(whichMeshes)
		msh(n) = G.mesh{whichMeshes(n)};
	end
end

if isempty(msh)
	error('Empty mesh specification.')
end

return