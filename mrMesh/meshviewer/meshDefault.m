function msh = meshDefault(host,id,mmPerVox,relaxIter,meshName,decimateReduction)
%
%    msh = meshDefault([host],[id],[mmPerVox],[relaxIter],[meshName])
%
%Author: Wandell/RFD
%Purpose:
%   Return a default mesh structure used by mrVista (and mrMesh).  The
%   various parameters were originally set by RFD.  The structures and
%   access routines were built by BW and are still in progress.
%

if ieNotDefined('host'),host = 'localhost'; end
if ieNotDefined('id'), id = 1; end
if ieNotDefined('mmPerVox'), mmPerVox = [1,1,1]; end
if ieNotDefined('relaxIter'), relaxIter = 0; end
if ieNotDefined('meshName'), meshName = 'untitled'; end
if ieNotDefined('decimateReduction'), decimateReduction = 0.1; end

% These can be passed in.
msh.name = meshName;
msh.fileName = '';
msh.relaxIterations = relaxIter;
msh.mmPerVox = mmPerVox;
msh.host = host;
msh.id = id;
msh.actor  = [];
msh.curvature = [];
% We always save the initial vertices so we can go back to the unsmoothed
% form and so that we can compute the vertex to gray map without
% distortion.
msh.initVertices = [];

% Empty specifications for data.  These are the data slots that mrMesh
% uses.
msh.data.camera_space = [];
msh.data.triangles = [];
msh.data.normals = [];
msh.data.vertices = [];
msh.data.rotation = [];
msh.data.colors = [];
msh.data.origin = [];


% These are hard-wired for now.
msh.grayLayers = 0;
msh.vertexGrayMap = [];

msh.decimate_reduction = decimateReduction;

msh.decimate_iterations = 0;
msh.decimate_subiterations = 0;
msh.decimate_preserve_edges = 0;
msh.decimate_preserve_topology = 1;
msh.decimate_boudary_vertex_deletion = 1;
msh.decimate_aspect_ratio = 25;
msh.decimate_degree = 20;
msh.smooth_sinc_method = 0;

% If you use sinc, smooth_relaxation is the passband parameter. Lower
% values will give more smoothing. Try .05 with 20-40 iterations for light
% smoothing, or .0001 with 150 iterations to fully relax a mesh. The main
% advantage of windowed sinc smoothing over the regular smoothing
% (Laplacian) is that it doesn't shrink the mesh with heavy smoothing.
msh.smooth_iterations = 50;
msh.smooth_relaxation = .25;
msh.smooth_feature_angle = 45;
msh.smooth_edge_angle = 15;
msh.smooth_boundary = 1;
msh.smooth_feature_angle_smoothing = 0;

% This smooth_pre boolean flag param is new. If true, an additional
% smoothing will be applied BEFORE decimation. Currently, it uses the same
% parameters as the post-decimation smoothing. Note that this param only
% applies to the build_mesh, open_gray and open_class commands (NOT smooth).
msh.smooth_pre = 0;
msh.curvature_mod_depth = 0.25;
msh.curvature_color = 1;

msh.conMat = [];
msh.lights = [];

return;
