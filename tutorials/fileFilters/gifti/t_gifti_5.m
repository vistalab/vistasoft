%% t_gifti_1
%

% Download from RDT
%{
 fullFolderName = fullfile(vistaRootPath,'local');
 rdt = RdtClient('vistasoft');

 rdt.crp('/vistadata/anatomy/anatomyNIFTI');
 leftMeshFile = rdt.readArtifact('leftMesh',...
    'type','mat',...
    'destinationFolder',fullFolderName);

 rdt.crp('/vistadata/gifti/BV_GIFTI/Base64');
 gFile = rdt.readArtifact('sujet01_Lwhite.surf',...
    'type','gii',...
    'destinationFolder',fullFolderName);

%}

%%
chdir(fullfile(vistaRootPath,'local'));

%% Converting  gifti to mrMesh (see above for the other direction)

mshFile = fullfile(vistaRootPath,'local','leftMesh.mat');
load(mshFile)
meshVisualize(msh);

% Load a GIFTI file
gFile = fullfile(vistaRootPath,'local','sujet01_Lwhite.surf.gii');
g = gifti(gFile);
% Blue shaded
% mrvNewGraphWin; plot(g);  

% Seen with mrMesh - shading not yet right, but it comes up
msh = meshCreate;
msh.triangles = double(g.faces' - 1);
msh.vertices  = double(g.vertices');
% msh = meshColor(msh);

c = ones(3,size(msh.vertices,2))*120;
c(4,size(msh.vertices,2)) = 255;
msh.colors = c;
meshVisualize(msh);

% Can't smooth without the normals.  Perhaps we can create these using
% isonormals().  Also, we might be able to effectively smooth using the
% Matlab function reducepatch.  I don't know how to meshColor.  
%
% msh2 = meshSmooth(msh);
% meshVisualize(msh);
% Also doesn't work just yet.
% foo = mrMeshCurvature(msh);

%% End


