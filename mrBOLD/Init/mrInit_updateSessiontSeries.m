function mrInit_updateSessiontSeries()
%
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

try
    loadSession;
    mrGlobals;
    
    numScans = numel(sessionGet(mrSESSION,'Functionals'));
    %Now that we have the number of scans, we know how many tSeries nifti
    %files we will need to create
    
        
    %Before we reset mrSESSION, let's save a backup
	copyfile('./mrSESSION.mat','./mrSESSION_tSeriesMigrationBackup.mat');
    
    tSeriesOutPath = fullfile(pwd,'Inplane','Original');
    tSeriesInBasePath = fullfile(tSeriesOutPath,'TSeries');
    keepFrames = zeros(numScans,2);

    for scan = 1:numScans
        % For each scan, go through each scan directory, read in all of the
        % matrix files and then build the data for a nifti from them.
        numSlices = numel(sessionGet(mrSESSION,'N Slices', scan));
        tSeriesInFolder = fullfile(tSeriesInBasePath,['Scan' num2str(scan)]);
        dimSize = [sessionGet(mrSESSION,'N Frames', scan) sessionGet(mrSESSION,'Functionals Slice Dim', scan) numel(sessionGet(mrSESSION,'N Slices', scan))];
        tSeries = zeros(dimSize);
        for slice = 1:numSlices
            tSeriesInFile = fullfile(tSeriesInFolder,['tSeries' num2str(slice) '.mat']);
            tSeriesIn = load(tSeriesInFile);
            tSeriesIn = reshape(tSeriesIn.tSeries, dimSize(1:3));
            tSeries = cat(4, tSeries, tSeriesIn);
        end %for
        tSeries = permute(tSeries,[2 3 4 1]); %Standard format: freq phase slice time

        
        
        %TODO: Check the syntax of this    
	xform = [diag(1./sessionGet(mrSESSION,'Functional Voxel Size'), size(tSeries)'/2; 0 0 0 1];
        
    %Build the nifti from the components above
    nii = niftiCreate('data',inplaneAnat.anat,'qto_xyz',xform,'freq_dim',freqPhaseSliceDims,'slice_code',sliceInfo);
        
        keepFrames(scan) = [0 -1];

        mrSESSION = sessionSet(mrSESSION,'Keep Frames',keepFrames, scan);

        tSeriesOut = fullfile(tSeriesOutPath,['tSeriesScan' num2str(scan) '.nii.gz']);
        
        %TODO: Check the syntax of this
        mrSESSION = dtSet(dataTYPES(1),'Functional Path',tSeriesOut,scan);
        
        niftiWrite(nii,tSeriesOut);        
    end %for
   
    %Create the freq, phase and slice dimensions, assuming that we are in
    %standard format
    freqPhaseSliceDims = [1 2 3];
    
    %Create the slice information
    sliceInfo = [3 0 mrSESSION.inplanes.nSlices-1 mrSESSION.inplanes.voxelSize(3)];
    
    
    %However, this does not create the proper pix dims, so let's fix that
    nii = niftiSet(nii,'Pix dim',mrSESSION.inplanes.voxelSize);
    
    fileName = fullfile(pwd,'Inplane/inplaneNifti.nii.gz');
    
    nii = niftiSet(nii,'File Path',fileName);
    
    writeFileNifti(nii);
    
    
    save('./mrSESSION.mat', 'mrSESSION','-append');
    
catch err
    warning(['There was an error when attempting to update your session.\n',...
        'No changes have been made to your system. Please run the update code again.\n']);
    rethrow(err);
end %try

return