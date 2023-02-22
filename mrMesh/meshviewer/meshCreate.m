function msh = meshCreate(mshType)
% mrMesh creation routine
%   
%   msh = meshCreate(mshType);
%
% We only create a vistaMesh type.  In the future we may design additional
% mesh structures.  See notes below about the properties of the msh fields.
%
% See also:  meshSet/Get  and mrmSet/Get
%
% Example:
%    msh = meshCreate;
%    msh = meshCreate('vista mesh');
%
% Stanford VISTA team

if ieNotDefined('mshType'), mshType = 'vistaMesh'; end

mshType = mrvParamFormat(mshType);

switch lower(mshType)
    case 'vistamesh'
        msh = vistaMeshCreate;
    otherwise
        error('Unknown mesh type %s\n',mshType);
end

return;


%------------------------------
function msh = vistaMeshCreate
%Default settings for a mrVista mesh
%
%   msh = vistaMeshCreate;
%
%  * The triangles are triplets of vertices.
%  * The vertices are numbered from [0,n-1], consistent with C numbering,
%  but not Matlab numbering.  This is necessary to work with mrMeshSrv.
%
%
% fields = {'name', 'host', 'id', 'actor', 'mmPerVox', 'lights', 'origin', ...
%     'initialvertices', 'vertices', 'triangles', 'colors', 'normals', 'curvature',...
%     'ngraylayers', 'vertexGrayMap', 'fibers',...
%     'smooth_sinc_method', 'smooth_relaxation', 'smooth_iterations', 'mod_depth'};
%
% (c) Stanford VISTA Team

msh.name = '';
msh.type = 'vistaMesh';
msh.host = 'localhost';
msh.id   = -1;    % Figure this out as soon as possible.
msh.filename = [];
msh.path = [];
msh.actor = 33;   % This is default.  But we should be able to change.
msh.mmPerVox = [1 1 1];
msh.lights   = {};
msh.origin   = [];
msh.initVertices = [];   % Initial vertices, without smoothing.
msh.vertices = [];
msh.triangles = [];

% Surface shading typically for pseudo-color or for showing curvature
msh.colors = [];
msh.mod_depth = 0.25;

msh.normals = [];   % Normals to the patches.  Can be computed using Matlab

msh.curvature = []; % Not sure how we compute this.  Uh oh.

% Not sure why these are here.  They relate the vertices to gray map.
% Probably essential for VISTASOFT/mrBOLD
msh.grayLayers = [];
msh.vertexGrayMap =[];

% Not sure why these are here too, but probably related to mrDiffusion
msh.fibers = [];

% Mesh smoothing related
msh.smooth_sinc_method = 0;
msh.smooth_relaxation = 0.5;
msh.smooth_iterations = 32;


return;
