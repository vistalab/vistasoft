function ok = mrInit_updateInplaneSession()

%
% USAGE: Takes a session that has already been initialized with an older
% version of mrInit and update it to the newer version. The newer version
% is of 2013-03-01 and it no longer saves the Inplane data out to a matlab
% matrix file.
%
% INPUT: paramIn
% Parameter input that will be stripped of all capitalization as well as
% whitespace before it is attempted to be translated. If it is not
% translated, a warning is returned as well as an empty answer.
%
%
% OUTPUT: ok
% error code for whether the migration completed successfully

% This migration tool takes an anat.mat file that presently exists and
% makes some assumptions about its orientation. Specifically, it is assumed
% that it is already in ARS format (which is the normal display format).
% Once this has been found, the migration tool creates a nifti structure
% for this data matrix.

%We should have access to a mrSESSION as well as an anat.mat 
loadSession;
mrGlobals;

inplanePath = fullfile(pwd,'Inplane/anat.mat');

inplaneAnat = load(inplanePath);
inplaneAnat.anat = permute(inplaneAnat.anat,[2 1 3]);

%Build the transform
mrSESSION.inplanes.voxelSize = mrSESSION.inplanes.voxelSize([2 1 3]);
xform = [diag(1./mrSESSION.inplanes.voxelSize), size(inplaneAnat.anat)'/2; 0 0 0 1];

%Create the freq, phase and slice dimensions, assuming that we are in
%standard format
freqPhaseSliceDims = [1 2 3];

%Create the slice information
sliceInfo = [3 0 mrSESSION.inplanes.nSlices-1 mrSESSION.inplanes.voxelSize(3)];

%Build the nifti from the components above
nii = niftiCreate('data',inplaneAnat.anat,'qto_xyz',xform,'freq_dim',freqPhaseSliceDims,'slice_code',sliceInfo);

%However, this does not create the proper pix dims, so let's fix that
nii = niftiSet(nii,'Pix dim',mrSESSION.inplanes.voxelSize);

fileName = fullfile(pwd,'inplaneNifti.nii.gz');

nii = niftiSet(nii,'File Path',fileName);

writeFileNifti(nii);

%Before we reset mrSESSION, let's save a backup
save mrSESSION_inplaneMigrationBackup mrSESSION;

%Reset mrSESSION.inplanes:
fieldNames = fieldnames(sessionGet(mrSESSION,'Inplane'));

mrSESSION = sessionSet(mrSESSION,'Inplane',rmfield(sessionGet(mrSESSION,'Inplane'),fieldNames));

mrSESSION = sessionSet(mrSESSION,'Inplane Path',fileName);

save mrSESSION mrSESSION -append; 

ok = 1;
return
