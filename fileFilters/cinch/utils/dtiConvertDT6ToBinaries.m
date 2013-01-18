function dtiConvertDT6ToBinaries(DT6Filename, outputDirectory)
% Convert a DT6 file into our new binary data formats for subjects.
%  
%   convertDT6ToBinaries(DT6Filename, outputDirectory)
%
%  We write out a set of different images and derived parameters in various
%  files in a format useful for dtiQuery, Cinch and MetroTrac.  It also
%  writes out a parameter file for MetroTrac.  The data include T1 anatomy,
%  tensors, B0, FA an Directions.  Then it saves a the remaining dt6
%  information.  We think dt6 files will eventually be replaced by this
%  directory and files.
%
%  DT6Filename: the name of the input DT6 (Matlab format) file. If
%  unspecified, a file selection dialog box will open.
%
%  outputDirectory: [optional] the name of the output directory you want to create.
%  If unspecfied, data will be written in a 'bin' directory underneath the
%  DT6 directory.   We use this default a lot.
% HISTORY:
% Author: DA
% 2006.07.19 RFD: Made several changes:
%      * we no longer copy the entire  dt6 file. Disk space is getting
%      tight and this copy is totally redundant. We do, however, copy over
%      the shell of a dt6 file with all the big stuff removed.
%      * The tensor data are no longer guaranteed to be masked. So, we
%      explicitly apply the dtBrainMask (if it exists).
%
%

if(~exist('DT6Filename','var') || isempty(DT6Filename))
    [f, p] = uigetfile({'*.mat';'*.*'}, 'Load DT6 file...');
    if(isnumeric(f)), disp('Conversion canceled.'); return; end
    DT6Filename = fullfile(p,f);
end;

if (~exist('outputDirectory','var') || isempty(outputDirectory))
    dataPath = fileparts(DT6Filename);
    if(isempty(dataPath)) dataPath = pwd; end
    outputDirectory = fullfile(dataPath, 'bin');
end;

disp ('Loading DT6 file...');

dt6 = load(DT6Filename);

% if exist(outputDirectory, 'dir')
%     reply = input(['The directory ''' outputDirectory ''' exists. Do you want to overwrite the contents? (Y/N) [N]'], 's');
%     if isempty(reply)
%         reply = 'N';
%     end
%     if (not (reply == 'y')) & (not (reply == 'Y'))
%         return;
%     end
% end

% Begin by making the new directory:

[success, message, messageID] = mkdir (outputDirectory);

% Next, make the tensors Nifti file.
disp ('Writing tensors...');
if(isfield(dt6,'dtBrainMask'))
    disp('   Applying dtBrainMask...');
    dt6.dt6(~repmat(dt6.dtBrainMask,[1,1,1,6])) = 0;
end
dtiWriteNiftiWrapper(dt6.dt6, dt6.xformToAcPc, fullfile(outputDirectory,'tensors.nii.gz'));

% create directory for background images:

backgroundDirectory = [outputDirectory filesep 'backgrounds'];

[success, message, messageID] = mkdir (backgroundDirectory);

selectionDirectory = [outputDirectory filesep 'selections'];

[success, message, messageID] = mkdir (selectionDirectory);

% create metrotrac directory
mtrDirectory = [outputDirectory filesep 'metrotrac'];

[success, message, messageID] = mkdir (mtrDirectory);

if(isfield(dt6,'anat'))
    % Write the T1:
    disp ('Writing T1 image...');

    %maxVal = max(max(max(dt6.anat.img)));

    dt6.anat.img = mrAnatHistogramClip (double(dt6.anat.img), 0.4, 0.98);
    dt6.anat.img (dt6.anat.img < 0) = 0;
    dt6.anat.img (dt6.anat.img > 1) = 1;

    dtiWriteNiftiWrapper (dt6.anat.img, dt6.anat.xformToAcPc, fullfile(backgroundDirectory,'t1.nii.gz'), 1.0);
    if(isfield(dt6.anat,'brainMask'))
        dtiWriteNiftiWrapper(uint8(dt6.anat.brainMask), dt6.anat.xformToAcPc, fullfile(backgroundDirectory,'t1_brainMask.nii.gz'), 1.0);
    end
end

% Write the B0:

disp ('Writing B0 image...'); 
%maxVal = max(max(max(dt6.b0)));
dt6.b0 = mrAnatHistogramClip (double(dt6.b0), 0.4, 0.97);
dt6.b0 (dt6.b0 < 0) = 0;
dt6.b0 (dt6.b0 > 1) = 1;

dtiWriteNiftiWrapper (dt6.b0, dt6.xformToAcPc, fullfile(backgroundDirectory,'b0.nii.gz'), 1.0);

% Now need to compute FA and direction map, and store these.
[eigVec, eigVal] = dtiSplitTensor(dt6.dt6);

faImage = dtiComputeFA(eigVal);
faImage(find(isnan(faImage))) = 0.0;

directionMap = squeeze(eigVec(:,:,:,[1 3 2],1));
directionMap(isnan(directionMap)) = 0;
for(ii=1:3) directionMap(:,:,:,ii) = abs(directionMap(:,:,:,ii)).*faImage; end
%directionMap = uint8(round(directionMap*255));

disp ('Writing FA image...');
%faImage = single(faImage);
dtiWriteNiftiWrapper(faImage, dt6.xformToAcPc, fullfile(backgroundDirectory,'fa.nii.gz'));

disp ('Writing direction map...');
dtiWriteNiftiWrapper(directionMap, dt6.xformToAcPc, fullfile(backgroundDirectory,'vectorRGB.nii.gz'));

% Store metrotrac options file to disk
disp ('Writing MetroTrac options...');
mtr = mtrCreate();
mtr = mtrSet(mtr,'tensors_filename',fullfile(outputDirectory,'tensors.nii.gz'));
mtr = mtrSet(mtr,'fa_filename',fullfile(backgroundDirectory,'fa.nii.gz'));
mtrSave(mtr,fullfile(mtrDirectory,'met_params.txt'),dt6.xformToAcPc);

%if (~isempty ('dt6.t1NormParams.sn'))
%    sn = dt6.t1NormParams.sn;
%    disp ('Writing out sn.mat file...');
%    save ([outputDirectory filesep 'sn.mat'], 'sn');
%else
%    disp ('Skipping sn (not in DT6 structure)...');
%end;

% fid = fopen (fullfile(outputDirectory, 'Notes.txt'), 'W');
% tmpNotes = dt6.notes;
% fprintf (fid, '%s\n\n', tmpNotes);

% remove stuff that is no longer needed:
if(isfield(dt6,'dtBrainMask'))
    dt6 = rmfield(dt6, {'dtBrainMask'});
end
dt6 = rmfield(dt6, {'xformToAcPc','b0','dt6'});
if(isfield(dt6,'anat'))
    dt6.anat = rmfield(dt6.anat, {'img','xformToAcPc'});
end

disp ('Saving remnants of the DT6 file...');
dtiSaveStruct(dt6, fullfile(outputDirectory,'dt6_file.mat'));

disp ('Done!');
% xxx should be writing out all of dt6.scanInfo as well.




