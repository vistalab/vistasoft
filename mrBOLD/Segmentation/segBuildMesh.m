function seg = segBuildMesh(seg, savePath, varargin);
%
% Build a new mesh structure for a mrVista2 segmentation object.
%
% seg = segBuildMesh(seg, [savePath=dialog], [options]);
%
% INPUTS:
%
% seg: segmentation structure (see segCreate).
%
% savePath: optional path to save the mesh; if entered as 'dialog', will
% pop up a user dialog to choose the save location.
% 
% Optional input arguments:
%   'visualize', [val]: set visualize flag to 1 or 0 [default 1]. If 1, 
%                       will open up the new mesh in mrMesh.
%   'numGrayLayers', [val]: set the # of gray layers to grow. [Default 0]
%   'meshName', [name]: set the name of the meah. [Default: same name as
%                       segmentation, plus a number if there are already
%                       other meshes attached]
%
%
% 
% OUTPUTS:
%
% seg: modified segmentation with a new mesh structure attached to the
% seg.mesh{} field.
%
% ras, 10/2006.
if notDefined('savePath'), savePath = ''; end
   
%% params / defaults
visualize = 1;
numGrayLayers = 0;
meshName = seg.name;
if ~isempty(seg.mesh), meshName = [meshName num2str(length(seg.mesh)+1)]; end

%% parse options
for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'visualize', visualize = varargin{i+1};
        case {'numgraylayers' 'nlayers'}, numGrayLayers = varargin{i+1};
        case {'name' 'meshname'}, meshName = varargin{i+1};
    end
end

%% get the WM classification
C = segGet(seg, 'classification');

% Create a volume which designates the white matter locations
wm = uint8( zeros(C.header.xsize, C.header.ysize, C.header.zsize) );
xx = C.header.voi(1):C.header.voi(2);
yy = C.header.voi(3):C.header.voi(4);
zz = C.header.voi(5):C.header.voi(6);
wm(xx,yy,zz) = wm(xx,yy,zz) | (C.data == C.type.white);

% add gray layers if specified
if numGrayLayers > 0
    [nodes edges C] = mrgGrowGray(C, numGrayLayers);
    wm = uint8( (C.data(xx,yy,zz) == C.type.white) | ...
                (C.data(xx,yy,zz) == C.type.gray) );    
end

%% build the new mesh
[newMesh tenseMesh] = mrmBuild(wm, seg.voxelSize, 1, visualize);

%% attach the 'tense' (unsmoothed) mesh to the new mesh as the
%% 'initVertices' field (very useful to hold on to)
initVertices = meshGet(tenseMesh, 'vertices');
newMesh = meshSet(newMesh, 'initialvertices', initVertices);
if isempty(seg.nodes) | isempty(seg.edges)
    [seg.nodes seg.edges] = segGet(seg, 'gray');
end
v2g = mrmMapVerticesToGray(initVertices, seg.nodes, seg.voxelSize, seg.edges);

newMesh = meshSet(newMesh, 'vertexGrayMap', v2g);
newMesh = meshSet(newMesh, 'name', meshName);
newMesh = meshSet(newMesh, 'nGrayLayers', numGrayLayers);

%% attach new mesh to segmentation
seg.mesh{end+1} = newMesh;

% set the new mesh as the selected one
seg.settings.mesh = length(seg.mesh);

%% save if selected
if ~isempty(savePath)
    if isequal(lower(savePath), 'dialog')
        savePath = mrSelectDataFile('stayput', 'w', '*.mat',...
                                    'Save Mesh File As...');
        if isempty(savePath)
            disp('Not Saving Mesh')
            return
        end
    end
    
    try
        mrmWriteMeshFile(newMesh, savePath);
    catch
        msg = sprintf(['Couldn''t save file %s. Not erroring, but you ' ...
                       'should try saving again.'], savePath);
        myWarnDlg(msg);
    end
end


return
