function mtrEC2Tensor(subjectDirName, numRepeats, diffusionTime, numBootstrap)
% Converts eddy corrected DWI to tensor and related files.
% 
%  mtrEC2Tensor(subjectDirName, numRepeats, [diffusionTime], [numBootstrap])
%
% subjectDirName: This conversion process follows a standardized file
% naming procedure. With files stored in the subject folder.
% numRepeats: Number of repeated volumes of DWIs recorded.
% numDWGrads: Number of diffusion weighted and non-diffusion weighted
%   measurements taken per repeat.
% diffusionTime: Time in seconds that diffusion was allowed to occur during
%   DWI experiment.  Default is 0.04s.
% numBootstrap: Number of synthetic bootstrap samples to generate during
%   tensor fitting and scanner noise estimation.  Default is 1000.
%
% With the following files and directories expected to already exist:
% INPUT
% rawAlignedFile - 'rawAligned.nii.gz': Eddy current corrected DWI images in compressed Nifti format
% bvalsFile - 'bvals': FSL format files specifying the b (s/mm^2) value of each DW measurement, where 
%   b = q^2*delta and q = labeling strength (1/mm) and delta (s) is the diffusion time which we 
%   assume as a default is 0.04s
% bvecsFile - 'rawAligned.bvecs': FSL format files specifying the vectors for DW measurements.
%   These vectors have a length of one.
% 
%
% And the following files and directories produced:
% OUTPUT
% schemeFile - 'camino.scheme': Scheme file contains the same information
%   as the rawAligned.bvecs and bvals file combined with the additional diffusionTime
%   information.  This file is used during the bootstrap estimation of
%   scanner noise.
% rawAlignedVoxelFormatFile - 'rawDtiAligned.Bfloat': Big endian voxel order data file.
%   This file contains the same information as rawAlignedFile, except that the
%   data is ordered so that all voxel information is stored in the file in
%   order.
% bootstrapData - 'dtboot.Bdouble': Result of running the modelfit code
%   which uses bootstrap to generate 1000 sample 
% brainMaskFile - 'brainMask.nii.gz': Output from FSL's BET program that
%   is a binary.
% tensorFile - 'bin\tensors.nii.gz': Tensor file in the format for DTIQuery.
%   Dxx,Dyy,Dzz,Dxy,Dxz,Dyz.
% meanB0File - 'bin\b0.nii.gz': Mean of the B0 data from the
%  raw eddy corrected files.
% faFile - 'bin\fa.nii.gz': Fractional anisotropy image
%   calculated from the tensorFile.
% wmMaskFile - 'bin\wmMask.nii.gz': Binary image indicating non-zero value
%   where white matter tissue is expected and zero otherwise.
% pdfFile - 'bin\pdf.nii.gz': Probability distribution function file that
%  is used during tractography in order to represent scanner noise per
%  voxel as well as shape information of the tensor fit per voxel. Data
%  stored: EV3,EV2,EV1,k1,k2,Cl,Cp.

% 
% AUTOMATICALLY GENERATED OUTPUT
%
% SPECIFIED OUTPUT
%
% Examples:   
%   Generate dt6 using dtiMakeDt6 <- (high level calls FromBin, FromTensorCalc, Muscle)
%
% AJS
%

% Go to subject directory
oldDirName = pwd;
cd(subjectDirName);

if( ieNotDefined('diffusionTime') ) 
    diffusionTime = 0.04;
end

if( ieNotDefined('numBootstrap') ) 
    numBootstrap = 1000;
end

schemeFile = fullfile('raw','camino.scheme');
rawAlignedFile = fullfile('raw','rawDti_aligned.nii.gz');
rawAlignedVoxelFormatFile = fullfile('raw','rawDti_aligned.Bfloat');
rawBvecsFile = fullfile('raw','rawDti_aligned.bvecs');
rawBvalsFile = fullfile('raw','rawDti_aligned.bvals');

% Check to see if which files need to be generated
%bGenBoot = queryOverwrite('dtboot.Bdouble');
bGenBoot = queryOverwrite(fullfile('bin','pdf.nii.gz'));
if bGenBoot
    bGenScheme = queryOverwrite(schemeFile);
else
    bGenScheme = 0;
end


% Convert bvecs and bvals into Camino scheme file
if bGenScheme
    if ispc
        error('Can not call fsl2scheme from matlab on Windows OS.')
    end
    delete(schemeFile);
    cmd = sprintf('fsl2scheme -bvalfile %s -bvecfile %s -diffusiontime %g -outputfile %s', rawBvalsFile, rawBvecsFile, diffusionTime, schemeFile);
    disp(cmd);
    [s, ret_info] = system(cmd,'-echo');
else
    disp('Using previously generated camino.scheme');
end

% Convert NIFTI raw image into Camino voxel format
if bGenBoot
    disp('Generating voxel format file, rawAligned.Bfloat');
    rawAligned = mtrNiftiToCamino(rawAlignedFile,'float', rawAlignedVoxelFormatFile);
    xformToAcPc = rawAligned.qto_xyz;
    mmPerVox = rawAligned.pixdim(1:3);
    numDWGrads = size(rawAligned.data,4) / numRepeats;
    if floor(numDWGrads) ~= numDWGrads
        msg = ['Num. volumes = ', num2str(size(rawAligned.data,4)), ' Num. repeats can''t be ', num2str(numRepeats)];
        error(msg);
    end
    % Calculate and save average B0 data
    img_b0 = mean(rawAligned.data(:,:,:,1:numDWGrads:end),4);
    dtiWriteNiftiWrapper(img_b0,xformToAcPc,fullfile('bin','b0.nii.gz'));
    clear rawAligned;
else
    nib0 = niftiRead(fullfile('bin','b0.nii.gz'));
    img_b0 = nib0.data;
    xformToAcPc = nib0.qto_xyz;
    mmPerVox = nib0.pixdim(1:3);
end

% Calculate and save brain mask
img_bm = mrAnatHistogramClip(img_b0,0.4,0.99);
img_bm = dtiCleanImageMask(img_bm > 0.25*max(img_bm(:)));
%img_bm = img_bm > 0.1;
%img_bm = dtiCleanImageMask(img_bm, 9);
dtiWriteNiftiWrapper(uint8(img_bm),xformToAcPc,fullfile('bin','brainMask.nii.gz'));

img_ten = zeros([size(img_bm) 6]);
img_fa = zeros([size(img_bm)]);
img_md = zeros([size(img_bm)]);

% Run bootstrap DTI fit
if bGenBoot
    
    % Store brain mask in a flat file for bootstrap fitting
    fid = fopen('brainMask.img','wb');
    fwrite(fid,img_bm,'short');fclose(fid);
    if ispc
        error('Can not call modelfitboot from matlab on Windows OS.')
    end
    delete(fullfile('raw','dtboot.Bdouble'));
    cmd = sprintf('modelfitboot -inputfile %s -inversion 1 -schemefile %s -outputfile raw/dtboot.Bdouble -bootstrap %g -bgmask brainMask.img -repeats %g -components %g', rawAlignedVoxelFormatFile, schemeFile, numBootstrap, numRepeats, numDWGrads);
    disp(cmd);
    [s, ret_info] = system(cmd,'-echo');

    % Remove flat file version of the brain mask
    delete('brainMask.img');

    % Load in the bootstrap results
    % XXX get format of data file, load data beforehand.
    fid = fopen(fullfile('raw','dtboot.Bdouble'),'rb','b');
    d = fread(fid,'double'); fclose(fid);

    % Write tensor file
    img_d = shiftdim(reshape(d,[21 81 106 76]),1);
    img_ten = zeros(size(img_d(:,:,:,3:8)));
    img_ten(:,:,:,1) = img_d(:,:,:,3);
    img_ten(:,:,:,2) = img_d(:,:,:,6);
    img_ten(:,:,:,3) = img_d(:,:,:,8);
    img_ten(:,:,:,4) = img_d(:,:,:,4);
    img_ten(:,:,:,5) = img_d(:,:,:,5);
    img_ten(:,:,:,6) = img_d(:,:,:,7);
    % Convert units from m^2/s to um^2 / ms
    img_ten(:) = img_ten(:)*1e9;
    dtiWriteNiftiWrapper(img_ten,xformToAcPc,fullfile('bin','tensors.nii.gz'));

    % Write fa file
    [eigVec, eigVal] = dtiSplitTensor(img_ten);
    [img_fa,img_md] = dtiComputeFA(eigVal);
    % Apply the brain mask
    img_fa(isnan(img_fa)) = 0;
    dtiWriteNiftiWrapper(img_fa,xformToAcPc,fullfile('bin','fa.nii.gz'));

    img_pdf = img_d(:,:,:,9:end-1);
    img_pdf(:,:,:,end+1) = eigVal(:,:,:,2);
    img_pdf(:,:,:,end+1) = eigVal(:,:,:,3);
    clear img_d;

    % Write pdf file for scanner fit uncertainty estimates
    % Make pdf 0 where it is outside of brain mask, this is necessary for
    % ConTrac program
    img_pdf( repmat(img_bm, [1 1 1 size(img_pdf,4)]) == 0 ) = 0;
    dtiWriteNiftiWrapper(img_pdf,xformToAcPc,fullfile('bin','pdf.nii.gz'));
    clear img_pdf;
    delete(fullfile('raw','dtboot.Bdouble'));

else
    disp('Using previously generated pdf.nii.gz');
    ni = niftiRead(fullfile('bin','tensors.nii.gz'));
    img_ten = ni.data;
    [eigVec, eigVal] = dtiSplitTensor(img_ten);
    [img_fa,img_md] = dtiComputeFA(eigVal);
    % Apply the brain mask
    img_fa(isnan(img_fa)) = 0;
    clear ni;
end


% Generate and write white matter mask file
bUseT1 = 0;
if bUseT1
    ni = niftiRead(fullfile('bin','t1.nii.gz'));
    disp('Please wait while calculating white matter from T1 image, this can take a few minutes ...');
    [wm, gm, csf] = mrAnatSpmSegment(ni.data,ni.qto_xyz,'MNIT1');
    bb = [-size(wm)/2; size(wm)/2-1];
    % now convert to mm space
    bb = ni.qto_xyz*[bb,[0;0]]';
    bb = bb(1:3,:)';
    img_wm = mrAnatResliceSpm(wm/max(wm(:)), inv(ni.qto_xyz), bb, [2 2 2]);
    dtiWriteNiftiWrapper(uint8(img_wm>0.5),ni.qto_xyz,fullfile('bin','wmMask.nii.gz'));
else
    %img_b0clip = mrAnatHistogramClip(img_b0,0.4,0.99);
    %img_brain = dtiCleanImageMask(img_b0clip > 0.4*max(img_b0clip(:)));
    % Do FA again after the clean image mask to make sure the ventricle holes
    % were not closed
    img_wm = img_bm & img_fa>.15 & (img_md<1.1 | img_fa>0.4);
    img_wm = dtiCleanImageMask(img_wm,0,0);    
    dtiWriteNiftiWrapper(uint8(img_wm),xformToAcPc,fullfile('bin','wmMask.nii.gz'));
end

% Save out dt6File
l = license('inuse'); h = hostid;
created = ['Created at ' datestr(now,31) ' by ' l(1).user ' on ' h{1} '.'];
notes = '';
b0 = img_b0;
dtBrainMask = img_bm;
dt6 = img_ten;
disp('Writing dt6.mat');
save('dt6.mat', 'dt6', 'mmPerVox', 'notes', 'xformToAcPc', 'b0', 'dtBrainMask', 'created');

% Return to starting directory
cd(oldDirName);

function val = queryOverwrite(fileName)
val = 1;
if ~isempty(dir(fileName))
    [pathstr, strippedFileName, ext, versn] = fileparts(fileName);
    msg = sprintf('Do you want to overwrite %s ? Y/N [N]: ', [strippedFileName ext]);
    reply = input(msg, 's');
    if isempty(reply) || reply == 'n' || reply == 'N'
        val = 0;
    end
end
return;
