function mesh = mrReadMrMNoScale(filename,showProgress)
% function mesh = mrReadMrM(filename,showProgress)
% 
%
% AUTHOR:  Maher Khoury 
% DATE:    07.15.99
% PURPOSE:
% 
%	Reads in a .MrM file created in MrGray and stores the information
%  in a Matlab structure.  The output structure contains the vertices,
%  normal vectors, and curvature information of the mesh
%
% INPUT:
%	filename is a .MrM file 
%   
% SEE ALSO:  MrCurvature, mrScaleCoords
%
% Notes: 
%
%	08/01/99 - This routine reads both .MrM format: mr3DVisMesh (older 
%  version) and mr3DMesh_v2.  Scaling using the voxel sizes is only for
%  the new format 
% ARW 040301 Doesn't do the scaling and so retains compatibilty with old mrGray


MrMfile = fopen(filename,'r','l');

if MrMfile == -1
   error(['Cannot open file:  ',filename]);
end
if(showProgress)
	h = msgbox(['Reading vertices and normals from ', filename]);
	drawnow;
	pause(0.5);
end

% Signature, Flags, nStrips, nTriangles, Bounds
%
mesh.signature = fgets(MrMfile, 11);
temp = transpose(fread(MrMfile, 3, 'long'));
flags = temp(1); nStrips = temp(2); nTriangles = temp(3); 

mesh.bounds = transpose(fread(MrMfile,6,'float'));
mesh.bounds = reshape(mesh.bounds, [2 3]);

% Offsets in file
%
strip_off = fread(MrMfile, 1, 'long');
strip_vertex_off = fread(MrMfile, 1, 'long');
tri_vertex_off = fread(MrMfile, 1, 'long');

% Strip list
stripList = transpose(fread(MrMfile, [2,nStrips], 'long'));
mesh.stripList = stripList;

% Number of Stripped Vertices
%
nStrippedVerts = stripList(nStrips,1)+stripList(nStrips,2);

% Determine offset of Triangle Vertice
mesh.triangleOffset = nStrippedVerts + 1;

% Vertices
%
sVertices = transpose(fread(MrMfile, [7,nStrippedVerts+3*nTriangles], 'float'));

mesh.vertices = sVertices(:,1:3);
mesh.normal = sVertices(:,4:6);


if mesh.signature=='mr3DMesh_v2'
   
   % Parameters
   %
   % Structural
   %
   %garbage = fgets(MrMfile, 1);
   mesh.parameters.structural.GrayFile = fgets(MrMfile, 60);
   mesh.parameters.structural.GrayToAdd = fread(MrMfile,1,'int');
   mesh.parameters.structural.EncodeCurvature = fread(MrMfile,1,'int');
   mesh.parameters.structural.voxSize = fread(MrMfile, [1,3], 'float');
   mesh.parameters.structural.IsoSurfacer = fread(MrMfile,1,'int');
   
   % Overlays
   %
   mesh.parameters.overlays.OverlayROIs = fread(MrMfile,1,'int');
   mesh.parameters.overlays.ClipToROIs = fread(MrMfile,1,'int');
   mesh.parameters.overlays.OverlayFunctionals = fread(MrMfile,1,'int');
   mesh.parameters.overlays.OverlayCuts = fread(MrMfile,1,'int');
   mesh.parameters.overlays.ColorModDepth = fread(MrMfile,1,'float');
   
   % Smoothing 1
   %
   mesh.parameters.smoothing1.Convergence = fread(MrMfile,1,'float');
   mesh.parameters.smoothing1.NumberOfIterations = fread(MrMfile,1,'int');
   mesh.parameters.smoothing1.RelaxationFactor = fread(MrMfile,1,'float');
   mesh.parameters.smoothing1.FeatureAngle = fread(MrMfile,1,'float');
   mesh.parameters.smoothing1.EdgeAngle = fread(MrMfile,1,'float');
   mesh.parameters.smoothing1.FeatureEdgeSmoothing = fread(MrMfile,1,'int');
   mesh.parameters.smoothing1.BoundarySmoothing = fread(MrMfile,1,'int');
   mesh.parameters.smoothing1.Skip = fread(MrMfile,1,'int');
   
   % Decimation
   %
   mesh.parameters.decimation.InitialFeatureAngle = fread(MrMfile,1,'float');
   mesh.parameters.decimation.FeatureAngleIncrement = fread(MrMfile,1,'float');
   mesh.parameters.decimation.MaximumFeatureAngle = fread(MrMfile,1,'float');
   mesh.parameters.decimation.PreserveEdges = fread(MrMfile,1,'int');
   mesh.parameters.decimation.BoundaryVertexDeletion = fread(MrMfile,1,'int');
   mesh.parameters.decimation.InitialError = fread(MrMfile,1,'float');
   mesh.parameters.decimation.ErrorIncrement = fread(MrMfile,1,'float');
   mesh.parameters.decimation.MaximumError = fread(MrMfile,1,'float');
   mesh.parameters.decimation.MaximumIterations = fread(MrMfile,1,'int');
   mesh.parameters.decimation.MaximumSubIterations = fread(MrMfile,1,'int');
   mesh.parameters.decimation.AspectRatio = fread(MrMfile,1,'float');
   mesh.parameters.decimation.Degree = fread(MrMfile,1,'int');
   mesh.parameters.decimation.PreserveTopology = fread(MrMfile,1,'int');
   mesh.parameters.decimation.TgtNPolys = fread(MrMfile,1,'int');
   mesh.parameters.decimation.Skip = fread(MrMfile,1,'int');
   
   % Smoothing 2
   %
   mesh.parameters.smoothing2.Convergence = fread(MrMfile,1,'float');
   mesh.parameters.smoothing2.NumberOfIterations = fread(MrMfile,1,'int');
   mesh.parameters.smoothing2.RelaxationFactor = fread(MrMfile,1,'float');
   mesh.parameters.smoothing2.FeatureAngle = fread(MrMfile,1,'float');
   mesh.parameters.smoothing2.EdgeAngle = fread(MrMfile,1,'float');
   mesh.parameters.smoothing2.FeatureEdgeSmoothing = fread(MrMfile,1,'int');
   mesh.parameters.smoothing2.BoundarySmoothing = fread(MrMfile,1,'int');
   mesh.parameters.smoothing2.Skip = fread(MrMfile,1,'int');
   
   % Output
   %
   %garbage = fgets(MrMfile, 1);
   mesh.parameters.output.OutputFile = fgets(MrMfile, 60);
   mesh.parameters.output.SaveOutput = fread(MrMfile,1,'int');
   mesh.parameters.output.ViewOutput = fread(MrMfile,1,'int');
   
   % Scale the coordinates
   %mesh.vertices = mrScaleCoords(mesh.vertices, mesh.parameters.structural.voxSize);
   %mesh.bounds = mrScaleCoords(mesh.bounds, mesh.parameters.structural.voxSize);
      
end


fclose(MrMfile);


if (showProgress)
	close(h);
	h = msgbox('Reading Colors');
	drawnow
	pause(0.5);
end
% R,G,B,A 
MrMfile = fopen(filename,'r');
garbage = fgets(MrMfile, 11);
garbage = fread(MrMfile, [2,nStrips+6], 'long');
garbage = transpose(fread(MrMfile,[28,nStrippedVerts+3*nTriangles],'uchar'));
mesh.rgba = garbage(:,25:28);

fclose(MrMfile);
if (showProgress)
	close(h);
end


return;
