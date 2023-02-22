%% t_gifti_4
%

% Download from RDT
%{
 rdt = RdtClient('vistasoft');
 rdt.crp('/vistadata/anatomy/anatomyNIFTI');

 leftMeshFile = rdt.readArtifact('leftMesh',...
    'type','mat',...
    'destinationFolder',fullFolderName);
%}

%%  Set the vista data path and change into the gifti data directory

chdir(fullfile(vistaRootPath,'local'));
%% Create a gifti structure from a mrMesh mesh

% This loads a VISTASOFT msh structure
% First the original mesh
load(fullfile(vistaRootPath,'local','leftMesh.mat'));
g = gifti;
g.faces = int32(meshGet(msh,'triangles')' + 1);

% Choose either the initial unsmoothed vertices, or the smoothed vertices
% g.vertices = single(meshGet(msh,'initVertices')');
g.vertices = single(meshGet(msh,'vertices')');

% We don't know how this is used.
g.mat = eye(4,4);  
% g.mat = rand(4,4);
% mrvNewGraphWin; h = plot(g);

% we take the green channel and use a gray scale map.  Their algorithm
% seems to normalize the color list and map it through the color map.
cdata = meshGet(msh,'colors');
cdata = cdata(2,:)';
gg.cdata = single(cdata);
mrvNewGraphWin; clf; colormap(gray); h = plot(g,gg);

%% Change the color map - I had some time on my hands.
colormap(cool); pause(0.5)
colormap(jet); pause(0.5)
colormap(redGreenCmap); pause(0.5)
colormap(blueyellowCmap); pause(0.5)

%% Change lighting and such
daspect([1,1,1]); view(45,30); axis tight
lightangle(45,30);
set(h,'SpecularColorReflectance',0,'SpecularExponent',50)
[az,el] = view;
g.mat = eye(4,4);  
% g.mat = rand(4,4);
% mrvNewGraphWin; h = plot(g);

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
% mrvNewGraphWin; h = plot(g); axis on; grid on

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
% mrvNewGraphWin; h = plot(g);  axis on; grid on

% and actually, according to the specifications of the file format, you can
% store metadata for the complete file as above or for a given DataArray: 
% g.private.data{2}.metadata(1).name = 'AnatomicalStructurePrimary'; 
% g.private.data{2}.metadata(1).value = 'CortexLeft';
% 
% We need to figure out how to save these fields to work with dtiQuery.

%% End


