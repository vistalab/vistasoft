% function intersect = dtiFiberIntersectMesh(fibers, triangles, vertices)
%
% Given a set of 'fibers' and a surface mesh (defined by 
% triangles/vertices), will find every triangle in the surface mesh
% that is intersected by the fibers.
%
% ARGUMENTS:
% 
% fibers = an Nx1 cell array of fibers, where each cell contains a 
%          3xN real array of points (XYZ order) that specify a fiber 
%          path. A fiber must contain more than 1 point (or be empty).
%
% triangles = a 3xN uint32 array of triangles, where each entry is
%             an index into the vertices array.
%
% vertices = a 3xN double array of vertices in YXZ order.
%
% NOTE! We assume that the mesh vertices are X-Y swapped relative to
% the fiber vertices. (Because they are in our data representations.)
%
% RETURNS:
%
% intersect = an Nx1 cell array, where N = the number of fibers
%             (ie. length(fibers)). Each cell contains a 5xN array
%             where N is the number of intersections. It has the 
%             following structure: [triangleIndex  fiberIndex X Y Z]
%
% NOTES:
% The hard work is done by the RAPID collision detection library. This 
% is only free for non-commercial use, so you'll need to get the library
% from its maintainer if you want to rebuild the mex file. See: 
% http://www.cs.unc.edu/~geom/OBB/OBBT.html or search google for
% "Robust and Accurate Polygon Interference Detection".
%
% To compile on Linux:
%    mex -O -I. dtiFiberIntersectMesh.cxx libRAPID.a
%
% on Windows:
%    mex -O -I. dtiFiberIntersectMesh.cxx RAPID.lib
%
% To make Rapid.lib on Windows, there is a directory
%    ..\mrDiffusion\src\RAPID_VStudio_201\MSVC_Compile
% with a Visual Studio Solution file.
%
% HISTORY:
% 2004.07.28 Bob Dougherty: wrote it.