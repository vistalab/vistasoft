function mrInit_updateInplaneSession()
%
%
% USAGE: Takes a session that has already been initialized with an older
% version of mrInit and update it to the newer version. The newer version
% is of 2013-03-01 and it no longer saves the Inplane data out to a matlab
% matrix file.
%
% INPUT: N/A, no input is used. As long as the user is in the directory of
% the session to be migrated, this should work correctly.
%
% OUTPUT: N/A, no output is given. The error handling has been upgraded to
% use built in matlab try-catch blocks.

% This migration tool takes an anat.mat file that presently exists and
% makes some assumptions about its orientation. Specifically, it is assumed
% that it is already in ARS format (which is the normal display format).
% Once this has been found, the migration tool creates a nifti structure
% for this data matrix.

try
    %TODO: Change this script to use sessionGet
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
    
    fileName = fullfile(pwd,'Inplane/inplaneNifti.nii.gz');
    
    nii = niftiSet(nii,'File Path',fileName);
    
    writeFileNifti(nii);
    
    %Before we reset mrSESSION, let's save a backup
    copyfile('./mrSESSION.mat','./mrSESSION_inplaneMigrationBackup.mat');
        
    %Reset mrSESSION.inplanes:
    fieldNames = fieldnames(sessionGet(mrSESSION,'Inplane'));
    
    mrSESSION = sessionSet(mrSESSION,'Inplane',rmfield(sessionGet(mrSESSION,'Inplane'),fieldNames));
    
    mrSESSION = sessionSet(mrSESSION,'Inplane Path',fileName);
    
    save('./mrSESSION.mat', 'mrSESSION','-append');
    
catch err
    warning(['There was an error when attempting to update your session.',...
        'No changes have been made to your system. Please run the update code again.']);
    rethrow(err);
end %try

return
