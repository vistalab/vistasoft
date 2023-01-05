%% t_gifti_3
%
% Introduction to the gifti reader/writer.  
% GIFTI is from
% http://www.artefact.tk/software/matlab/gifti/
% https://github.com/nno/matlab_GIfTI
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

%%  Set the vista data path and change into the gifti data directory

chdir(fullfile(vistaRootPath,'local'));

%% Read T1 anatomical and itkGray class file

% The T1 nifti is called the background image. That data and the two gifti
% meshes created in this cell are used within dtiquery.  The gifti files
% are assigned a transform in the the g.mat slot that aligns the T1 and
% meshes. The package (t1.nii.gz, left_gifti and right_gifti) are all used
% by dtiquery as part of the visualization.
%
% Read the anatomical.  We will use the transform in qto_xyz for
% coregistering.

% Help
%{
 % If youi need to download the nifti files, use this
 rdt.crp('/vistadata/anatomy/T1andMesh'); 
 niT1File = rdt.readArtifact('t1.nii',...
    'type','gz',...
    'destinationFolder',fullFolderName);
%}

niT1File = fullfile(vistaRootPath,'local','t1.nii.gz');
niT1 = niftiRead(niT1File);

% In this example, we produce the gifti data from an itkGray segmentation.
% The class file with gray identified is written by mrgSaveClassWithGray.
% That routine reads the itkGray class file, grows gray matter separately
% for left and right, and saves the output.
niCFile = fullfile(vistaRootPath,'local','t1_class_5GrayLayers.nii.gz');
niClass = niftiRead(niCFile);

%% Make an isosurface between left gray and white

% These are the ITKGRAY class labels
%    0: unlabeled
%    1: CSF
%    2: Subcortical
%    3: left white matter
%    5: left gray matter
%    4: right white matter
%    6: right gray matter 

Ds = uint8(niClass.data);

% To get the boundary between white and gray in left hemisphere set the
% labels for everything that is not left gray or white to unlabeled.
Ds(Ds == 2) = 0;    % Subcortical
Ds(Ds == 4) = 0;    % right white
Ds(Ds == 6) = 0;    % right gray


%% Matlab calculations reducing the patches and computing normals

% Makes the isosurface at level 4 (20 sec)
fv = isosurface(Ds,4);

% Reduce the number of patches (10 sec)
fv = reducepatch(fv,.06);

% A blurry, red brain, no shading.  Ugly.
mrvNewGraphWin;
p1 = patch(fv, 'FaceColor','red','EdgeColor','none');

%%  Make it nicer

% Plots the surface using the normals, I think

mrvNewGraphWin;
p1 = patch(fv, 'FaceColor','red','EdgeColor','none');
fv.normals = isonormals(Ds,fv.vertices);
view(3); daspect([1 1 1]); axis tight
camlight;  camlight(-80,-10); lighting phong; 
title('Data Normals')

%% End


