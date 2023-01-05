function msh = mrmBuildMeshMatlab(cFile,reduce)
% Create a msh structure from a class file using mainly Matlab calls
%
%  msh = mrmBuildMeshMatlab(cFile,[reduce = 0.1])
%
% Example:
%    cFile = fullfile(mrvDataRootPath,'anatomy','anatomyV','left','left.Class');
%    msh = mrmBuildMeshMatlab(cFile,0.2);
%    meshVisualize(msh);
%
% (c) Stanford VISTA Team 2011

% TODO:  Figure out coloring, smoothing, and normals

if notDefined('cFile')
    cFile = mrvSelectFile('r','class',[],'Class file'); 
end
if notDefined('reduce'), reduce = 0.1; end

% Grow gray matter from the white class
[nodes,edges,classData] = mrgGrowGray(cFile,2);
clear nodes
clear edges

% Create a volume with 1 at white matter and 2 at gray matter and 0
% elsewhere
classData.data(classData.data == classData.type.white) = 1;
classData.data(classData.data == classData.type.gray) =  2;
classData.data(classData.data == classData.type.unknown) =  5;
classData.data(classData.data == classData.type.other) =  5;
classData.data(classData.data == classData.type.csf) =  5;

% Make the vertices and triangles
Ds = isosurface(classData.data,1);
Ds = reducepatch(Ds,reduce);

% If there is enough memory, try this
normals = isonormals(classData.data,Ds.vertices);
clear classData

% Create the mesh for return.
% These should be sets
msh = meshCreate;
msh.triangles = double(Ds.faces' - 1);
msh.vertices  = double(Ds.vertices');
msh.normals   = normals';


% Set the colors.  Ultimately these should be colored with meshColor.
c = ones(3,size(msh.vertices,2))*120;
c(4,size(msh.vertices,2)) = 255;
msh.colors = c;

return


