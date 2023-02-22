function ConvertMesh(vAnatMatFileName, niftiFileName, meshMatFileName, outFileName)
% Converts a mrVista mesh to a Quench's mesh format.
% 
% vAnatMatFileName  vAnatomy file name
% niftiFileName     Nifti image file name
% meshMatFileName   mrVista mesh file name
% outFileName       Quench's mesh file name
%
% In a valid mrVista mesh file, the number of vertices, normals and colors
% are the same.
%
% What are the niftiFileName data - used in defining the transform, but how
%
% The scale factor is there to deal with the smoothed case.  The smoothing
% in mrMesh really shrinks the mesh.  So we center and scale it back up in
% the smoothed case.  In the initVertices case, we leave the scale at 1.
%
% are the file formats for the mesh and vertices and normals OK?  Do we
% want any further information in the header so we can reuse them over
% time, or is this one-time usage and we dont want time stamps, source of
% the data, and so forth?
%
%


%Scale factor
scale = 0.9;%1.3;

% Read input files
[vAnatomy,vAnatMm] = readVolAnat(vAnatMatFileName);
ni = niftiRead(niftiFileName);
msh = mrmReadMeshFile(meshMatFileName);

xformVAnatToAcpc = dtiXformVanatCompute(double(ni.data), ni.qto_xyz, vAnatomy, vAnatMm);
swapXY = [0 1 0 0; 1 0 0 0; 0 0 1 0; 0 0 0 1];
vertex2acpc = inv( swapXY*diag([msh.mmPerVox([2,1,3]) 1])*inv(xformVAnatToAcpc) );
len = size(msh.vertices,2);
% fname='C:\Shireesh\Work\vistasoft\trunk\mrAnatomy\mrMesh\mrVistaSampleSession\3DAnatomy\Left\3DMeshes\sample_left_almostfootball.mat';

fp = fopen(outFileName, 'wb');
%acpc2Vertex = open('C:/acpc2Vertex.mat');

%Add the 4th coordinate to homogenise the vertex coordinates 
%vertices  = vertex2acpc*[msh.vertices; ones(1,len)];
vertices  = vertex2acpc*[msh.initVertices; ones(1,len)];
vertices(4,:)=[];
% Scale the vertices
center = mean(vertices,2);
center = center * ones(1,len);
vertices = (vertices-center)*scale + center;
fwrite(fp,length(vertices),'int32');
fwrite(fp,vertices,'double');

%Write the bumpy vertices too
vertices  = vertex2acpc*[msh.initVertices; ones(1,len)];
vertices(4,:)=[];
fwrite(fp,length(vertices),'int32');
fwrite(fp,vertices,'double');

%Save normals
normals = msh.normals;
fwrite(fp,length(normals),'int32');
fwrite(fp,normals,'double');

%Save colors
fwrite(fp,length(msh.colors),'int32');
fwrite(fp,msh.colors,'double');

%Save triangles
fwrite(fp,length(msh.triangles),'int32');
fwrite(fp,msh.triangles,'int32');

fclose(fp);
end
