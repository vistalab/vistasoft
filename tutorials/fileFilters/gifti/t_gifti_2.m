%% t_gifti_2
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

% Help
%{
 % If you need to download the nifti files, use this
 rdt = RdtClient('vistasoft');
 rdt.crp('/vistadata/anatomy/T1andMesh');

 niT1File = rdt.readArtifact('t1.nii',...
    'type','gz',...
    'destinationFolder',fullFolderName);
 niCFile = rdt.readArtifact('t1_class_5GrayLayers.nii',...
    'type','gz',...
    'destinationFolder',fullFolderName);
%}

%%
chdir(fullfile(vistaRootPath,'local'));

%% Read T1 anatomical and itkGray class file with both white and gray

% The T1 nifti is called the background image. That data and the two gifti
% meshes created in this cell are used within dtiquery.  The gifti files
% are assigned a transform in the the g.mat slot that aligns the T1 and
% meshes. The package (t1.nii.gz, left_gifti and right_gifti) are all used
% by dtiquery as part of the visualization.
%
% Read the anatomical.  We will use the transform in qto_xyz for
% coregistering.
niT1File = fullfile(vistaRootPath,'local','t1.nii.gz');
niT1 = niftiRead(niT1File);

% In this example, we produce the gifti data from an itkGray segmentation.
% The class file with gray identified is written by mrgSaveClassWithGray.
% That routine reads the itkGray class file, grows gray matter separately
% for left and right, and saves the output.
niCFile = fullfile(vistaRootPath,'local','t1_class_5GrayLayers.nii.gz');
niClass = niftiRead(niCFile);

%% Make the isosurface between gray and white

% First for the left
Ds = uint8(niClass.data);

% These are the ITKGRAY class labels
%    0: unlabeled
%    1: CSF
%    2: Subcortical
%    3: left white matter
%    5: left gray matter
%    4: right white matter
%    6: right gray matter 

% To get the boundary between white and gray in left hemisphere set the
% labels for everything that is not left gray or white to unlabeled.
Ds(Ds == 2) = 0;    % Subcortical
Ds(Ds == 4) = 0;    % right white
Ds(Ds == 6) = 0;    % right gray
% unique(Ds(:))

% showMontage(double(Ds))
% Matlab finds the boundary between left white (3) and left gray (5)
g = gifti(isosurface(Ds,4));  

% Set the flag to indicate this is a left hemisphere.  This was explained
% to me in an email from the author.
g.private.data{2}.metadata(1).name = 'AnatomicalStructurePrimary'; 
g.private.data{2}.metadata(1).value = 'CortexLeft';

% Store the T1 transform in the gifti.  Note that the first two columns are
% exchanged; not sure why. This transform is necessary for coregistering
% with dtiquery.
g.mat = niT1.qto_xyz([2 1 3 4],:);

% Safe the GIFTI mesh
save(g,'left_gifti.gii');

% Show what we did.
g = gifti('left_gifti.gii'); mrvNewGraphWin; 
h = plot(g); axis on; grid on

%% Now for the right gifti mesh.

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

g = gifti('right_gifti.gii'); 
mrvNewGraphWin; h = plot(g); axis on; grid on

%% End

% 
% %% 3. Convert a typical class file to a gifti surface
% 
% cFile = fullfile(mrvDataRootPath,'anatomy','anatomyV','left','left.Class');
% lc = readClassFile(cFile);
% Ds = lc.data;
% 
% % class.type.unknown = (0*16);
% % class.type.white   = (1*16);
% % class.type.gray    = (2*16);
% % class.type.csf     = (3*16);
% % class.type.other   = (4*16);
% 
% % Make the unknown type equal to csf
% Ds(Ds == 0) = 48;
% 
% % showMontage(double(Ds))
% tmp = isosurface(Ds,20); 
% 
% % mrvNewGraphWin; patch(tmp); shading faceted
% g = gifti(tmp);
% mrvNewGraphWin; plot(g)


%% End


