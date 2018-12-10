function mrInit_updateSessiontSeries()
%
% USAGE: Takes a session that has already been initialized with an older
% version of mrInit and update it to the newest version. This version
% is of 2013-05-05 and it no longer uses tSeries data in the form of
% matrices, instead saving tSeries data to a nifti and using that.
%
% INPUT: N/A, no input is used. As long as the user is in the directory of
% the session to be migrated, this should work correctly.
%
% OUTPUT: N/A, no output is given. The error handling has been upgraded to
% use built in matlab try-catch blocks.
%
% This migration tool takes a series of folders of tSeries*.mat files and
% makes some assumptions about their orientation. Specifically, it is assumed
% that these are already in the normal display format.
% All of the tSeries data is loaded and the migration tool creates
% a nifti structure around this data, saves it to the filesystem and writes
% the information about its location in the session and datatype global
% variables, before saving these to mrSESSION.mat as well.

try
    loadSession;
    mrGlobals;
    
    %Before we reset mrSESSION, let's save a backup
    copyfile('mrSESSION.mat','mrSESSION_tSeriesMigrationBackup.mat');
    
    %Now that we have the number of scans, we know how many tSeries nifti
    %files we will need to create
    
    % Use local paths, not absolute paths
    % inplaneBasePath = fullfile(pwd,'Inplane');
    inplaneBasePath = 'Inplane';
    
    
    for dtNum = 1:numel(dataTYPES)
        fprintf('Starting dataTYPE number %d\n', dtNum);
        tSeriesOutPath = fullfile(inplaneBasePath, dtGet(dataTYPES(dtNum),'Name'));
        tSeriesInBasePath = fullfile(tSeriesOutPath,'TSeries');
        
        if exist(fullfile(tSeriesInBasePath,'Scan1','tSeries1.mat'),'file')
            %Checks to see if there is any inplane tSeries data in this
            %dataTYPE if there is, then does all of the processing
            
            numScans = dtGet(dataTYPES(dtNum),'N Scans');
            
            keepFrames = zeros(numScans,2);
            
            for scan = 1:numScans
                fprintf('Starting scan number %d\n', scan);
                % For each scan, go through each scan directory, read in all of the
                % matrix files and then build the data for a nifti from them.
                numSlices = dtGet(dataTYPES(dtNum),'N Slices', scan);
                tSeriesInFolder = fullfile(tSeriesInBasePath,['Scan' num2str(scan)]);
                dimSize = [dtGet(dataTYPES(dtNum),'N Frames', scan) dtGet(dataTYPES(dtNum),'Func Size', scan) dtGet(dataTYPES(dtNum),'N Slices', scan)];
                tSeries = zeros(dimSize);
                for slice = 1:numSlices
                    tSeriesInFile = fullfile(HOMEDIR, tSeriesInFolder,['tSeries' num2str(slice) '.mat']);
                    tSeriesIn = load(tSeriesInFile);
                    tSeriesIn = reshape(tSeriesIn.tSeries, dimSize(1:3));
                    tSeries(:,:,:,slice) = tSeriesIn;
                end %for
                
                % The following transform will preserve the orientation of the data
                % across the migration, such that inplane to vAnatomy xforms do not
                % need to change, nor do parameter maps, ROIs, etc. The permute([2 1])
                % followed by flipdim(2) effectively converts from x/y coordinates to
                % row/column coordinates. The reason we do this is that the old
                % vistasoft (prior to the move to NIFTIs) did this transform when
                % showing the slices as images, whereas the current code simply pulls
                % the data array from a nifti (after applying a standard xform to the
                % nifti), and uses an image tool such as imagesc slice by slice without
                % re-orienting the array. Since we no longer do this xform each time we
                % show the data, we must do it here as part of the migration if want
                % the migrated data to appear the same way as the pre-migrated data.
                % See also mrInit_updateInplaneSession.m.
                tSeries = permute(tSeries,[3 2 4 1]); %Standard format: freq phase slice time
                tSeries = flip(tSeries, 2);
                %Note: this needed to be changed to reflect the fact that
                %MATLAB stores values row, column, etc. and not column,
                %row,
                
                %Create the freq, phase and slice dimensions, assuming that we are in
                %standard format
                freqPhaseSliceDims = [1 2 3];
                
                %Create the slice information
                % We are assuming that the voxels are the same size in all
                % of the dataTYPES
                funcVoxel = sessionGet(mrSESSION,'Functional Voxel Size',scan);
                
                xform = [[diag(1./funcVoxel); 0 0 0], size(tSeries)'/2];
                
                funcVoxel(4) = dtGet(dataTYPES(dtNum),'Frame Period',scan);
                
                sliceInfo = [3 0 dtGet(dataTYPES(dtNum),'N Slices',scan)-1 funcVoxel(4)];
                
                %Build the nifti from the components above
                nii = niftiCreate('data',tSeries,'qto_xyz',xform,'freq_dim',freqPhaseSliceDims,'slice_code',sliceInfo);
                
                %However, this does not create the proper pix dims, so let's fix that
                nii = niftiSet(nii,'Pix dim',funcVoxel);
                
                keepFrames(scan, 1) = 0;
                keepFrames(scan, 2) = -1;
                
                mrSESSION = sessionSet(mrSESSION,'Keep Frames',keepFrames, scan);
                
                tSeriesOut = fullfile(tSeriesInBasePath,['tSeriesScan' num2str(scan) '.nii.gz']);
                
                nii = niftiSet(nii,'File Path',tSeriesOut);
                
                dataTYPES(dtNum) = dtSet(dataTYPES(dtNum),'Inplane Path',tSeriesOut,scan);
                dataTYPES(dtNum) = dtSet(dataTYPES(dtNum),'Keep Frames', keepFrames, scan);
                
                niftiWrite(nii,tSeriesOut);
                
                mrSESSION = sessionSet(mrSESSION,'Version','2.1');
                
                %Update the session variables
                save('mrSESSION.mat', 'mrSESSION','-append');
                save('mrSESSION.mat', 'dataTYPES','-append');
                
                % we already wrote the nifti 4 lines above. this is
                % redundant.
                %   writeFileNifti(nii);
                
                fprintf('Finished scan number %d\n', scan)
            end %for
            
        end %if
        fprintf('Finished dataTYPE number %d\n', dtNum)
    end %for
    
catch err
    warning(['There was an error when attempting to update your session.',...
        'No changes have been made to your system. Please run the update code again.']);
    rethrow(err);
end %try

return