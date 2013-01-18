% BIG PICTURE TODOS (01/09/07 ras):
% A lot of the previous things on the ToDo list have been implemented in 
% 2006. Here are some things that remain.
%
%
%  * Spaces: add ability to call external matlab function to 
%            get coords (e.g., for Talairach; may also be easier
%            for flattening). I think the format of any function
%            called in this way should be:
%               newCoords = myFunction(oldCoords,mr);
%
%   * Import GLM tools to work on mr objects
%
%   * Flattening: either implement the 'flatten-on-the-fly' code from
%   mrFlatMesh, or else come up with a tool to flatten using the meshes.
%   Given that we were able to use Jonas Larsson's SurfRelax code for
%   mesh inflation, maybe we could also port over his flattening routines?
%   (This would appeal a bit more to me, because having a non-disc flat map
%   makes maps easier to interpret, allowing the viewer to relate the shape
%   of the cuts to positions on the 3D mesh. May also reduce distortions?)
%

