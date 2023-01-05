function msh = meshBuildFromGifti(g)
%Build a msh from gifti data or a gifti filename (full path)
%
%   msh = meshBuildFromGifti(g)
%
% Example:
%   g = fullfile(mrvDataRootPath,'gifti','BV_GIFTI','Base64','sujet01_Lwhite.surf.gii');
%   msh = meshBuildFromGifti(g);
%   meshVisualize(msh);
%
% (c) Stanford VISTA Team, 2011

if ischar(g),  g = gifti(g); end

% Seen with mrMesh - shading not yet right, but it comes up
msh = meshCreate;
msh.triangles = double(g.faces' - 1);
msh.vertices  = double(g.vertices');
% msh = meshColor(msh);

c = ones(3,size(msh.vertices,2))*120;
c(4,size(msh.vertices,2)) = 255;
msh.colors = c;

return
