%% t_gifti
%
% Introduction to the gifti reader/writer.  
%
% The examples here 
%
%  1. Run through the gifti team example
%  2. Prepare T1 and itkGray class file for viewing with dtiquery
%  3. Produces a gifti mesh from a gray/white segmentation class file
%  4. Illustrations of mesh computations
%       reducing the number of triangles and computing the normals
%       (isonormals, reducepatch). 
%  5. Interoperability of GIFTI and mrMesh meshes
%     * Loads a VISTASOFT mesh, converts it to GIFTI format, colors it,
%   attaches metadata, saves it, and display the results in a Matlab window.
%     * Load a GIFTI mesh, converts it to a VISTASOFT mesh, displays it in a
%  mrMesh window.
%
% This script should be separated into about 3 other simpler scripts.
%
% (c) Stanford VISTA Team 

%%  Download from the Remote Data TOolbox directory two gifti files
fullFolderName = fullfile(vistaRootPath,'local');
rdt = RdtClient('vistasoft');
rdt.crp('/vistadata/gifti/BV_GIFTI/Base64'); 
a = rdt.listArtifacts('print',true);
rdt.readArtifact(a(4),'destinationFolder',fullFolderName);
rdt.readArtifact(a(3),'destinationFolder',fullFolderName);

chdir(fullFolderName);

%% 1. Run through the gifti team example

% This failed on my Mac with the SPM12 version of gitfi.
% I went to Flandin's github repository and downloaded 
% https://github.com/nno/matlab_GIfTI
% That gifti read worked.
g = gifti('sujet01_Lwhite.surf.gii');

% Blue shaded
figure; plot(g);  

% The color overlay values are determined by an color map and a single
% scaling (I think).
gg = gifti('sujet01_Lwhite.shape.gii');
figure; h = plot(g,gg);


%% 2. Read T1 anatomical and itkGray class file with both white and gray

% The T1 nifti is called the background image. That data and the two gifti
% meshes created in this cell are used within dtiquery.  The gifti files
% are assigned a transform in the the g.mat slot that aligns the T1 and
% meshes. The package (t1.nii.gz, left_gifti and right_gifti) are all used
% by dtiquery as part of the visualization.
%
% We haven't yet figured out about loading the fibers properly.

% TODO - Change to downloading from RDT

% Read the anatomical.  We will use the transform in qto_xyz for
% coregistering.
niT1File = fullfile(mrvDataRootPath,'anatomy','T1andMesh','t1.nii.gz');
niT1 = niftiRead(niT1File);

% In this example, we produce the gifti data from an itkGray segmentation.
% The class file with gray identified is written by mrgSaveClassWithGray.
% That routine reads the itkGray class file, grows gray matter separately
% for left and right, and saves the output.
niCFile = fullfile(mrvDataRootPath,'anatomy','T1andMesh','t1_class_5GrayLayers.nii.gz');
niClass = niftiRead(niCFile);
Ds = uint8(niClass.data);

% These are the ITKGRAY class labels
%    0: unlabeled
%    1: CSF
%    2: Subcortical
%    3: left white matter
%    5: left gray matter
%    4: right white matter
%    6: right gray matter 

% To get the boundary between white and gray in left hemisphere, do this
Ds(Ds == 2) = 0;
Ds(Ds == 4) = 0;
Ds(Ds == 6) = 0;
% unique(Ds(:))

% showMontage(double(Ds))
g = gifti(isosurface(Ds,4));  % Matlab finds the gray/white boundary

% Set the flag to indicate this is a left hemisphere
g.private.data{2}.metadata(1).name = 'AnatomicalStructurePrimary'; 
g.private.data{2}.metadata(1).value = 'CortexLeft';

% Store the T1 transform in the gifti.  Note that the first two columns are
% exchanged; not sure why. This transform is necessary for coregistering
% with dtiquery.
g.mat = niT1.qto_xyz([2 1 3 4],:);

% Safe the GIFTI mesh
save(g,'left_gifti.gii');
% g = gifti('left_gifti.gii'); figure; h = plot(g); axis on; grid on

%% Build the right gifti mesh.

Ds = uint8(niClass.data);
Ds(Ds == 2) = 0;
Ds(Ds == 3) = 0;
Ds(Ds == 5) = 0;
% unique(Ds(:))

g = gifti(isosurface(Ds,5));

% Set the flag to indicate this is a right hemisphere
g.private.data{2}.metadata(1).name = 'AnatomicalStructurePrimary'; 
g.private.data{2}.metadata(1).value = 'CortexRight';

g.mat = niT1.qto_xyz([2 1 3 4],:);

save(g,'right_gifti.gii');
% g = gifti('right_gifti.gii'); figure; h = plot(g); axis on; grid on


%% 3. Convert a typical class file to a gifti surface
cFile = fullfile(mrvDataRootPath,'anatomy','anatomyV','left','left.Class');
lc = readClassFile(cFile);
Ds = lc.data;

% class.type.unknown = (0*16);
% class.type.white   = (1*16);
% class.type.gray    = (2*16);
% class.type.csf     = (3*16);
% class.type.other   = (4*16);

% Make the unknown type equal to csf
Ds(Ds == 0) = 48;

% showMontage(double(Ds))
tmp = isosurface(Ds,20); 

% figure; patch(tmp); shading faceted
g = gifti(tmp);
figure; plot(g)

%% 4. Matlab calculations reducing the patches and computing normals
fv = isosurface(Ds);
fv = reducepatch(fv,.02);
figure;
p1 = patch(fv, 'FaceColor','red','EdgeColor','none');

isonormals(Ds,p1)
view(3); daspect([1,1,1]); axis tight
camlight; camlight(-80,-10); lighting phong; 
title('Triangle Normals')

% Plots the surface using the normals, I think
% fv.normals = isonormals(Ds,fv.vertices);
figure;
p1 = patch(fv, 'FaceColor','red','EdgeColor','none');
isonormals(Ds,p1)
view(3); daspect([1 1 1]); axis tight
camlight;  camlight(-80,-10); lighting phong; 
title('Data Normals')

%%  5. Create a gifti structure from a mrMesh mesh

% This loads a VISTASOFT msh structure
% First the original mesh
load(fullfile(mrvDataRootPath,'anatomy','anatomyNIFTI','leftMesh.mat'));
g = gifti;
g.faces = int32(meshGet(msh,'triangles')' + 1);

% Choose either the initial unsmoothed vertices, or the smoothed vertices
% g.vertices = single(meshGet(msh,'initVertices')');
g.vertices = single(meshGet(msh,'vertices')');

% We don't know how this is used.
g.mat = eye(4,4);  
% g.mat = rand(4,4);
% figure; h = plot(g);

% we take the green channel and use a gray scale map.  Their algorithm
% seems to normalize the color list and map it through the color map.
cdata = meshGet(msh,'colors');
cdata = cdata(2,:)';
gg.cdata = single(cdata);
figure; clf; colormap(gray); h = plot(g,gg);

%% Change the color map - I had some time on my hands.
colormap(cool); pause(0.5)
colormap(jet); pause(0.5)
colormap(redGreenCmap); pause(0.5)
colormap(blueYellowCmap); pause(0.5)

% %Change lighting and such
daspect([1,1,1]); view(45,30); axis tight
lightangle(45,30);
set(h,'SpecularColorReflectance',0,'SpecularExponent',50)
[az,el] = view;
g.mat = eye(4,4);  
% g.mat = rand(4,4);
% figure; h = plot(g);

g.private.data{2}.metadata(1).name = 'AnatomicalStructurePrimary'; 
g.private.data{2}.metadata(1).value = 'CortexLeft';

% Also, DTI-Query will use the AnatomicalStructureSecondary metadata field
% to distinguish the surfaces that have been loaded.  While it's not
% necessary, it may be helpful to set this field as well:  
% g.private.data{2}.metadata(2).name = 'AnatomicalStructureSecondary'; 
% g.private.data{2}.metadata(2).value = 'Pial'; % (or whatever you would like to tag the structure as)

% Then, 
% save(g,'dhTest.gii');

% From Guillaume Flandin - storing metadata2
% g = gifti('file.gii');
% g.private.metadata(1).name  = 'AnatomicalStructurePrimary'; 
% g.private.metadata(1).value = 'CortexLeft'; 

%% Attach metadata to the gifti so Doug H. can read it. Name it as left.
% Helped by Guillaume Flandin email: gflandin@fil.ion.ucl.ac.uk

% First the left
load(fullfile(mrvDataRootPath,'anatomy','T1andMesh','Left_Mesh_Unsmoothed.mat'));
g = gifti;
g.faces = int32(meshGet(msh,'triangles')' + 1);

% Choose either the initial unsmoothed vertices, or the smoothed vertices
% g.vertices = single(meshGet(msh,'initVertices')');
g.vertices = single(meshGet(msh,'initVertices')');

% Set the flag to indicate this is a left hemisphere
g.private.data{2}.metadata(1).name = 'AnatomicalStructurePrimary'; 
g.private.data{2}.metadata(1).value = 'CortexLeft';
save(g,'left_gifti.gii');
% figure; h = plot(g); axis on; grid on

% Now the right
load(fullfile(mrvDataRootPath,'anatomy','T1andMesh','Right_Mesh_Unsmoothed.mat'));
g = gifti;
g.faces = int32(meshGet(msh,'triangles')' + 1);

% Choose either the initial unsmoothed vertices, or the smoothed vertices
% g.vertices = single(meshGet(msh,'initVertices')');
g.vertices = single(meshGet(msh,'initVertices')');

% Set the flag to indicate this is a left hemisphere
g.private.data{2}.metadata(1).name = 'AnatomicalStructurePrimary'; 
g.private.data{2}.metadata(1).value = 'CortexRight';

save(g,'right_gifti.gii');
% figure; h = plot(g);  axis on; grid on

% and actually, according to the specifications of the file format, you can
% store metadata for the complete file as above or for a given DataArray: 
% g.private.data{2}.metadata(1).name = 'AnatomicalStructurePrimary'; 
% g.private.data{2}.metadata(1).value = 'CortexLeft';
% 
% We need to figure out how to save these fields to work with dtiQuery.

%% 6. Converting  gifti to mrMesh (see above for the other direction)

mshFile = fullfile(mrvDataRootPath,'anatomy','anatomyNIFTI','leftMesh.mat');
load(mshFile)
meshVisualize(msh);

% Load a GIFTI file
gFile = fullfile(mrvDataRootPath,'gifti','BV_GIFTI','Base64','sujet01_Lwhite.surf.gii');
g = gifti(gFile);
% Blue shaded
% figure; plot(g);  

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


