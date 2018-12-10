%% t_GiftiFromClass
%
%  1. Create a left and right mesh from a mrGray class file.
%  2. Read the meshes and convert them to GIFTI files.
%  3. Load the T1 anatomical and the meshes into dtiquery.
%
% Concern:  BW had errors with the SPM12 gifti.  He went to the Flandin
% github repository https://github.com/nno/matlab_GIfTI and downloaded from
% there.  Things started working.  Not sure why.  Needs to be resolved.
% Also, there is another version of gifti inside of Vistasoft under
% filefilters.  So, this needs to be resolved.
%
% (c) Stanford VISTA Team

%% Read the anatomical. Use the transform in qto_xyz for coregistering.

% The T1 nifti defines the coordinate frame. The class file is in the same 
% coordinate frame as the T1.  So we place an appropriately modified .mat 
% field into the gifti % to keep them aligned.

niT1File = fullfile(mrvDataRootPath,'anatomy','anatomyV','vAnatomy.nii.gz');
niT1 = niftiRead(niT1File);

%% Load a left class and build the mrMesh mesh.

niCFile = fullfile(mrvDataRootPath,'anatomy','anatomyV','left','left.Class');
leftMsh = meshBuildFromClass(niCFile,[],'left');
leftMsh = meshSet(leftMsh,'name','vistadata-anatomyV-left');

leftMsh = meshSmooth(leftMsh);
leftMsh = meshColor(leftMsh);
% meshVisualize(leftMsh);


%% Load a right class and build the mrMesh mesh

niCFile = fullfile(mrvDataRootPath,'anatomy','anatomyV','right','right.Class');
rightMsh = meshBuildFromClass(niCFile,[],'right');
rightMsh = meshSet(rightMsh,'name','vistadata-anatomyV-right');

rightMsh = meshSmooth(rightMsh);
rightMsh = meshColor(rightMsh);

% meshVisualize(rightMsh);

%% Convert the left and right hemisphere meshes to gifti
g = gifti;

g.faces = int32(meshGet(leftMsh,'triangles')' + 1);

% What should we do to align the vertices in this mesh with the vertices in
% the T1 anatomical we read in?  
% There is the question of the 'origin' field.  And then there is the
% question of the transform.  I think we have to shift, and we may have to
% permute the dimensions.  
g.vertices = single(meshGet(leftMsh,'vertices')');

%g.mat = niT1.qto_xyz([2 1 3 4],:);
% tmp = niT1.qto_xyz([2 1 3 4],:);
% tmp = niT1.qto_xyz;

% The scalar should be the opposite sign of the affine term
% 3rd row negative made it dorsal/ventral match.
% The top row might be front/back?
tmp = [ ...
    0     0     1  -127;
    -1     0     0  127;
    0     -1    0   127;
    0     0     0     1];    
g.mat = tmp';

% Set the flag to indicate this is a left hemisphere
g.private.data{2}.metadata(1).name = 'AnatomicalStructurePrimary'; 
g.private.data{2}.metadata(1).value = 'CortexLeft';

% meshes created in this cell are used within dtiquery.  The gifti files
% are assigned a transform in the the g.mat slot that aligns the T1 and
% meshes. The package (t1.nii.gz, left_gifti and right_gifti) are all used
% by dtiquery as part of the visualization.
% Store the T1 transform in the gifti.  Note that the first two columns are
% exchanged; not sure why. This transform is necessary for coregistering
% with dtiquery.

save(g,fullfile(mrvDataRootPath,'anatomy','anatomyV','leftMesh.gii'));


% g = gifti('left_gifti.gii'); 
% figure; h = plot(g); axis on; grid on

%% Right hemisphere

g = gifti;
g.faces = int32(meshGet(rightMsh,'triangles')' + 1);
g.vertices = single(meshGet(rightMsh,'vertices')');

% Set the flag to indicate this is a right hemisphere
g.private.data{2}.metadata(1).name = 'AnatomicalStructurePrimary'; 
g.private.data{2}.metadata(1).value = 'CortexRight';

g.mat = tmp';

save(g,fullfile(mrvDataRootPath,'anatomy','anatomyV','rightMesh.gii'));


%%  Now, you should be able to run dtiquery 

% Load the t1.nii.gz file
% Load the left and right meshes
% Enjoy.
% TODO:  Set the mesh colors
%        Set the mesh transparencies
%        Find a pdb version 3 fiber set for these data.
%