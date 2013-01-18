function [msh, lights] = meshVisualize(msh,id)
% Visualize a VTK mesh of the cortical surface using mrMesh
%
%  [msh] = meshVisualize(msh,[id]);
% 
% This mesh structure must contain vertices and faces.
%
% A msh is input and the mesh is displayed in mrMesh window number id.  If
% no id number is sent in a new window is opened.
%
% If the input is an old style mesh, it is changed updated the best we can. 
%
% Questions:
%    What are the minimal fields required for this msh to run with mrMesh?
%    Can we pass in a modified gifti mesh and convert it to the proper
%    fields and have this run?
%
% Example:
%  fName ='X:\anatomy\nakadomari\left\20050901_fixV1\left.Class';
%  fName ='/biac1/wandell/data/anatomy/dougherty/t1_class_left.nii.gz';
%  msh = meshBuildFromClass(fName);
%  msh = meshSmooth(msh);
%  meshVisualize(msh);
%
% (c) Stanford Vista Team

backColor = [1,1,1];  

if notDefined('msh'), error('The mesh is required.'); end
% if ieNotDefined('mmPerVox'), mmPerVox = [1 1 1]; end
if notDefined('host'), host = 'localhost'; end
if notDefined('id'), id = -1; end

% Set initial parameters for the mesh.
if isempty(meshGet(msh,'host')), msh = meshSet(msh,'host',host); end
if isempty(meshGet(msh,'id')),   msh = meshSet(msh,'id',id); end

% If the window is already open, no harm is done.
if mrmCheckServer, mrMesh(meshGet(msh,'host'),meshGet(msh,'id'),'close'); end
msh = mrmInitHostWindow(msh); 

% Initializes the mesh
[msh, lights] = mrmInitMesh(msh,backColor);

return;



