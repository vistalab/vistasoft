% t_anatomyReadDisplay
%
% Illustrates how to read and display an anatomical data set.
%
% See also NIFTI2MRVISTAANAT, MRVIEWER. 
%
% Tested 01/04/2011 - MATLAB r2008a, Fedora 12, Current Repos
%
% Stanford VISTA
%

%% Read in the anatomy
%{
 % If you do not have the file already, you can get it this way
 rdt = RdtClient('vistasoft');
 rdt.crp('/vistadata/anatomy/anatomyNIFTI');
 dest = fullfile(vistaRootPath,'local');
 niFileName = rdt.readArtifact('t1.nii',...
                 'type','gz',...
                 'destinationFolder',dest);
%}

% We store modern anatomies as NIFTI files.  We load the NIFTI this way:
niFileName = fullfile(vistaRootPath,'local','t1.nii.gz');
if ~exist(niFileName,'file')
    error('T1 File not found.  See comments for download.');
end

% The anatomy data are int16.  Load them this way.
anat = niftiRead(niFileName);

%% The data fields in the struct anat
% The variable anat is a structure.
% The image data are in the field anat.data

% Other important files are
anat.xyz_units % Metric units (usually mm)
anat.descrip   % Generic description
anat.dim       % Volume size
anat.pixdim    % Pixel size
anat.fname

% The (x,y,z) dimensions in NIFTI and mrLoadRet coords differ.
% nifti2mrVistaAnat converts NIFTI data into mrLoadRet format.
%
% The NIFTI (x,y,z) format is [sagittal(L:R), coronal(P:A), axial(I:S)]. 
% The mrLoadRet (x,y,z) format is [axial(S:I), coronal(A:P), sagittal(L:R)].
%   L = left, R = right, 
%   P = posterior, A = anterior, 
%   I = inferior,  S = superior
%  

%% To display the anatomy image you can use several methods
% To view a single slice you can extract it directly from the anat.data
% slot
middleSlice = round(anat.dim(3)/2);
img = anat.data(:,:,middleSlice);
imagesc(img);
colormap gray

% You can make a montage of all the slices
montage = imageMontage(anat.data);
imshow(montage)

% It is possible to use itkGray to bring up the file directly.

% From Linux you can use fslview (assuming you have FSL on your path).
% The command is simply 'fslview filename'

% You can call an elaborated Matlab viewer that RAS wrote: mrViewer
% mrViewer(niFileName)

%% END
