function [dt6FileName, outBaseDir] = ...
    dtiRawPreprocess(dwRawFileName, t1FileName, bvalue, gradDirsCode, clobber, dt6BaseName, flipLrApFlag, numBootStrapSamples, eddyCorrect, ...
    excludeVols, bsplineInterpFlag, phaseEncodeDir, dwOutMm, rotateBvecsWithRx, rotateBvecsWithCanXform)
% Running the mrDiffusion pre-processing steps on raw DWI data
%
%  dtiRawPreprocess([dwRawFileName], [t1FileName], [bvalue=[]], ...
% [gradDirsCode=[]], [clobber='ask'], [dt6BaseName='dti'], ...
% [flipLrApFlag=false], ...
% [numBootStrapSamples=500],[eddyCorrect=1],[excludeVols=[]], ...
% [bsplineInterpFlag=false], [phaseEncodeDir=[]], [dwOutMm=[2 2 2]], ...
% [rotateBvecsWithRx=false], [rotateBvecsWithCanXform=false]);
%
% A function for running the mrDiffusion pre-processing steps on raw
% DWI data. If you already have appropriate bvals/bvecs files in with your
% diffusion data, then you can leave bvalue and gradDirsCode parameters
% empty.
%
% INPUTS:
% If clobber=='always' or true, then existing output files will be
% silently overwritten. If clobber=='ask' (the default), then you'll
% be asked if you want to recompute the file or use the existing
% one. If clobber==false, then any existing files will
% be used and only those that are missing will be recomputed.
%
% This assumes that you've already generated the raw NIFTI data file with
% something like dinifti.
%
% If you collected your DTI data using GE's ASSET, you may be
% prompted to provide phase-encode direction (1= LR, 2=AP).
% Information about this, as well as the b-value and gradient code,
% can be found in the dicom file header. More detailed instructions
% can be found here:
%
% excludeVols is an optional list of volume indices to ignore in the tensor
% fitting. Useful if you know that some of your data are bad. Note that the
% volume indices start at 1, unlike some viewers (e.g., fslview), that
% start at 0. So, if you are using a zero-indexed viewer to find bad
% volumes, be sure to add 1 to the resulting indices.
%
% If eddyCorrect is 1 (the default), motion and eddy-current correction are
% done. If it's 0, then only motion correction is done, and if it is -1
% then nothing is done.
%
% WARNING: spm_coreg is broken under Matlab r2006b (and later) on a64
% platforms. It won't return an error, but wil iterate forever. Not sure
% why, but it seems to work OK on r2006a. This is an issue with a mex file
% and library dependencies, so if you rebuild your spm mex files for your
% platform, you should be OK. In our lab, the rebuilt mex files are in
% /usr/local/matlab/toolbox/mri/spm5_r2008.
%
% TODO:
% * Ask all questions up front.
%
% Web resources:
%  http://white.stanford.edu/newlm/index.php/DTI_Preprocessing
%  mrvBrowseSVN('dtiRawPreprocess');
%
% HISTORY:
% 2007.?? RFD wrote it.
% 2007.04.20 RFD: cleaned it up a bit and make it a real function.
% 2007.07.20 AJS: Relative filenames to the parent directory.
% 2008.01.30 RFD: Added check for NIFTI files to avoid mysterious
% error messages caused by empty nifti structs.
% 2008.08.27 ER/RFD: fixes to eddy current correction (comment by DY)
% 2009.10.08 RFD: bsplineInterpFlag now defaults to false.
% 2011.07.20 LMP: Three changes by RFD: (1) Added a flag to allow the bvecs to be rotated
% with the Rx. The default behavior is false. (rotateBvecsWithRx = false;)
% (2) Added code that (by default) applies the cannonical xform to the bvecs.
% (bvecXform = canXform(1:3,1:3);). (3) While not a change to this function
% itself the call to niftiApplyCannnicalXform calls niftiCheckQto which now
% will check the qform code and run niftiSetQto if the code = 0.
%
% Copyright Stanford team, mrVista, 2011


% The raw data are resampled to apply the motion/eddy correction and
% alignment to standard space. Setting the following to true will use a
% 7th-order bspline interpolation. Setting it to false will trigger
% trilinear interpolation. Note that with trilinear, your variance
% estimates from the bootstrap will likely show beating patterns (see Rohde
% et. al. (2005). Estimating intensity variance due to noise in registered
% images: applications to diffusion tensor MRI. Neuroimage, PMID:
% 15955477.) With the larger base of the 7th-order bspline, these patterns
% seem to be almost completely absent (ie. below my visual detection
% threshold) and thus we can safely ignore the variance correction step.
%
% However, if your data are particularly noisy and/or have substantial
% artifacts, a bspline interpolation might make things worse, so you will
% want to set this to false to stick to trilinear interpolation.

%% This code is no longer used: We use dtiInit instead. 

warning('"dtiRawPreprocess" has been replaced by "dtiInit".');
prompt = sprintf('This function, "dtiRawPreprocess", has been replaced by "dtiInit".\n Please update your code. \n\nWould you like to load the documentation for dtiInit and the VISTA DTI preprocessing WIKI?');
resp   = questdlg(prompt,'WARNING','YES','EXIT','YES');
if(strcmp(resp,'YES')), 
    doc('dtiInit.m');
web('http://white.stanford.edu/newlm/index.php/DTI_Preprocessing','-browser');
end
return


%%
outSuffix = '_aligned';

% By default we use this method, trilinear
if ~exist('bsplineInterpFlag','var') || isempty(bsplineInterpFlag)
    bsplineInterpFlag = 0;
end

if(~bsplineInterpFlag), outSuffix = [outSuffix '_trilin']; end

if(~exist('dwOutMm','var')||isempty(dwOutMm))
    % The eddy-current-corrected, aligned diffusion images will be resampled at
    % 2mm isotropic voxels by default.
    dwOutMm = [2 2 2];
end

if(~exist('clobber','var')||isempty(clobber))
    clobber = 'ask';
end
if(~exist('dt6BaseName','var')||isempty(dt6BaseName))
    dt6BaseName = '';
end
if(~exist('flipLrApFlag','var')||isempty(flipLrApFlag))
    flipLrApFlag = false;
end
if(~exist('numBootStrapSamples','var')||isempty(numBootStrapSamples))
    numBootStrapSamples = 500;
end
if(~exist('eddyCorrect','var')||isempty(eddyCorrect))
    eddyCorrect = 1;
end
if(~exist('excludeVols','var')||isempty(excludeVols))
    excludeVols = [];
end

if(~exist('rotateBvecsWithRx','var')||isempty(rotateBvecsWithRx))
    rotateBvecsWithRx = false;
end
if(~exist('rotateBvecsWithCanXform','var')||isempty(rotateBvecsWithCanXform))
    rotateBvecsWithCanXform = false;
end

% For new CNI data, this should be 0, I think.  For older data this should
% be 1, which is the default.  Confirm with Bob D. 
if ~exist('eddyCorrect','var') || isempty(eddyCorrect), eddyCorrect = 1; end

if(eddyCorrect == 0)
    disp('Skipping eddy-current correction, just doing rigid-body motion correction.');
elseif(eddyCorrect == -1)
    outSuffix = [outSuffix '_noMEC'];
    disp('No eddy-current or motion correction.');
elseif (eddyCorrect == 1)
    % Default, motion and eddy-current correction
else
    error('eddyCorrect must be [-1|0|1]!');
end

mrDiffusionDir = fileparts(which('mrDiffusion.m'));

if(islogical(clobber))
    if(clobber), clobber = 'always';
    else clobber = 'no'; end
end
if(strcmpi(clobber,'always')), clobber = 1;
elseif(strcmpi(clobber,'no')), clobber = -1;
else clobber = 0;
end

if(~exist('dwRawFileName','var')||isempty(dwRawFileName))
    [f,p] = uigetfile({'*.nii.gz';'*.*'},'Select a raw NIFTI file for input...');
    if(isnumeric(f)), disp('User canceled.'); return; end
    dwRawFileName = fullfile(p,f);
end

if(~exist(dwRawFileName,'file'))
    error(['Couldn''t find diffusion data file "' dwRawFileName '".']);
end

[dataDir,inBaseName] = fileparts(dwRawFileName);
[junk,inBaseName] = fileparts(inBaseName);
if(isempty(dataDir)), dataDir = pwd; end
mnB0Name = fullfile(dataDir,[inBaseName '_b0.nii.gz']);

outBaseName = [inBaseName outSuffix];
outBaseDir  = fullfile(dataDir,outBaseName);
inBaseDir   = fullfile(dataDir,inBaseName);
% Default output dir is one level above the dataDir. We assume that
% this is the 'subjectDir', which contains the 'raw' data dir.
subjectDir = fileparts(dataDir);
if(isempty(subjectDir)), subjectDir = pwd; end

if(~exist('t1FileName','var')||isempty(t1FileName))
    t1FileName = fullfile(subjectDir,'t1');
    [f,p] = uigetfile('*.nii.gz','Select the t1-file for alignment...',t1FileName);
    if(isnumeric(f)), error('user canceled.'); end
    t1FileName = fullfile(p,f);
elseif(strcmpi(t1FileName,'MNI'))
    t1FileName = fullfile(mrDiffusionDir,'templates','MNI_EPI.nii.gz');
    disp('The MNI EPI template will be used for alignment.');
end

% Read or announce failure for T1 data
if(~exist(t1FileName,'file'))
    error(['Couldn''t find t1 data file "' t1FileName '".']);
elseif isempty(findstr(t1FileName, pwd))&& exist(fullfile(pwd, t1FileName),'file' )
    t1FileName=fullfile(pwd, t1FileName);%make t1FileName absolute
end

% Find data files for the b vector directions and vals in different
% coordinate frames
bvalsFile = [inBaseDir '.bvals'];
bvecsFile = [inBaseDir '.bvecs'];
ecFile = [inBaseDir '_ecXform.mat'];
acpcFile = [inBaseDir '_acpcXform.mat'];
alignedBvecsFile = [outBaseDir '.bvecs'];
alignedBvalsFile = [outBaseDir '.bvals'];
dwAlignedRawFile = [outBaseDir '.nii.gz'];

disp('loading raw data...');
dwRaw = niftiRead(dwRawFileName);
% oldPhaseDim = dwRaw.phase_dim;

% Reorient the voxel order to a standard unflipped axial order:
[dwRaw,canXform] = niftiApplyCannonicalXform(dwRaw);

% Make sure there is a valid phase-encode dir, as this is crucial for
% eddy-current correction.
if notDefined('phaseEncodeDir')
    while(dwRaw.phase_dim<1 || dwRaw.phase_dim>3)
        prompt = sprintf('Phase-encode dir is currently %d, but must be 1, 2 or 3. New value:',dwRaw.phase_dim);
        resp = inputdlg(prompt,'Set phase encode direction',1,{'2'});
        if(~isempty(resp))
            dwRaw.phase_dim = round(str2double(resp{1}));
        end
    end
else
    dwRaw.phase_dim=phaseEncodeDir;
end

fprintf('dataDir = %s; dims = [%d %d %d %d];\n',dataDir,size(dwRaw.data));
fprintf('t1FileName = %s;\n',t1FileName);

% Allow bvecs/bvals files without the 's'.
if(~exist(bvalsFile,'file')&&exist(bvalsFile(1:end-1),'file'))
    bvalsFile = bvalsFile(1:end-1);
end
if(~exist(bvecsFile,'file')&&exist(bvecsFile(1:end-1),'file'))
    bvecsFile = bvecsFile(1:end-1);
end

% NOTE: TODO item below.
if(~exist(bvalsFile,'file')||~exist(bvecsFile,'file'))
    % Generate bvecs file and a bvals file from a dwepi.grads file.
    % *** FIX ME: get the bval and grad dir file number from the
    % dicom header.
    doBvecs = true;
    if(~exist('bvalue','var')||isempty(bvalue))
        [bvalue, gradDirsCodeTmp] = dtiRawGetBvalVecFromName(inBaseName);
    end
    gradsDir = fullfile(mrDiffusionDir,'gradFiles');
    if(~exist('gradDirsCode','var')||isempty(gradDirsCode))
        if(exist('gradDirsCodeTmp','var'))
            gradDirsCode = gradDirsCodeTmp;
        else
            [bvalue, gradDirsCode] = dtiRawGetBvalVecFromName(filename);
        end
    end
    if(isempty(gradDirsCode))
        [f,p] = uigetfile({'*.grads';'*.*'},'Select the GE grads file...',gradsDir);
        if(isnumeric(f)), error('Canceled.'); end
        gradDirsCode = fullfile(p,f);
    end
    if(ischar(gradDirsCode))
        gradsFile = gradDirsCode;
    else
        gradsFile = fullfile(gradsDir,sprintf('dwepi.%d.grads',gradDirsCode));
    end
    %fprintf('NOTE: bvals/bvecs not found- building them with bval=%f micrometers^2/msec, gradDirsCode=%d.\n',bvalue,gradDirsCode);
    % NOTE: most sequences will need the bvecs reoriented based on the
    % scanner-to-image transform stored in qto_ijk. But, for our Bammer
    % sequence, the bvecs were rotated during image acquisition.
    %dtiRawBuildBvecs(size(dwRaw.data,4)niftiApplyCannonicalXform, dwRaw.qto_ijk, gradsFile, bvalue, inBaseName);
    dtiRawBuildBvecs(size(dwRaw.data,4), eye(4), gradsFile, bvalue, inBaseDir, flipLrApFlag);
    fprintf('bvalsFile = %s; %% (bvalue = %0.3f)\nbvecsFile = %s; %%(gradDirsCode = %d)\n',bvalsFile,bvalue,bvecsFile,gradDirsCode);
else
    doBvecs = false;
end

doResamp = false;

% Check for missing data and fix, if necessary
% *** TODO: allow arbitrary volumes to be skipped downstream to avoid
% needing to touch the raw data here.
bvecs = dlmread(bvecsFile);
bvals = dlmread(bvalsFile);
goodVols = squeeze(max(max(max(dwRaw.data))))~=0;
% Negative bvals are used to indicate bad volumes that should be skipped
if(any(bvals<0))
    goodVols = goodVols&bvals>0;
end
if(~isempty(excludeVols))
    goodVols(excludeVols) = false;
end
if(~all(goodVols))
    fprintf('Found %d bad volumes in data- removing them from analysis...\n',sum(~goodVols));
    dwRaw.data = dwRaw.data(:,:,:,goodVols);
    bvecs = bvecs(:,goodVols);
    bvals = bvals(goodVols);
    doResamp = true;
else
    if(length(goodVols)<size(bvecs,2))
        warning('mrDiffusion:dimMismatch', 'More bvecs than vols- ignoring some bvecs...');
        bvecs = bvecs(:,goodVols);
    end
    if(length(goodVols)<size(bvals,2))
        warning('mrDiffusion:dimMismatch', 'More bvals than vols- ignoring some bvals...');
        bvals = bvals(goodVols);
    end
end

% Reorient bvecs, if necessary
if(rotateBvecsWithRx)
    bvecXform = affineExtractRotation(dwRaw.qto_xyz);
else
    bvecXform = eye(3);
end
if(rotateBvecsWithCanXform)
    bvecXform = bvecXform*canXform(1:3,1:3);
end
if(all(bvecXform~=eye(3)))
    for(ii=1:size(bvecs,2))
        bvecs(:,ii) = bvecXform*bvecs(:,ii);
    end
end

% Get a mean b0 to be used for eddy-current correction and
% alignment to a structural scan.
if(clobber==1||~exist(mnB0Name,'file'))
    dtiRawComputeMeanB0(dwRaw, bvals, mnB0Name);
else
    if(clobber==0)
        resp = questdlg([mnB0Name ' exists- would you like to overwrite it?'], 'Clobber mnB0', 'Overwrite','Use Existing File','Abort','Use Existing File');
        if(strcmpi(resp,'Abort')), error('User aborted.'); end
        if(strcmpi(resp,'Overwrite'))
            dtiRawComputeMeanB0(dwRaw, bvals, mnB0Name);
        end
    end
end

if(eddyCorrect==-1)
    ecFile = [];
else
    % Compute the eddy-current correction for all the DWIs (SLOW!)
    if(clobber==1||~exist(ecFile,'file'))
        dtiRawRohdeEstimateEddyMotion(dwRaw, mnB0Name, bvals, ecFile, eddyCorrect==1);
        doResamp = true;
    else
        if(clobber==0)
            resp = questdlg([ecFile ' exists- would you like to overwrite it?'], 'Clobber EddyCorrect', ...
                'Overwrite','Use Existing File','Abort','Use Existing File');
            if(strcmpi(resp,'Abort')), error('User aborted.'); end
            if(strcmpi(resp,'Overwrite'))
                dtiRawRohdeEstimateEddyMotion(dwRaw, mnB0Name, bvals, ecFile, eddyCorrect==1);
                doResamp = true;
            end
        end
    end
end

% Compute the dti-structural alignment
if(clobber==1||~exist(acpcFile,'file'))
    dtiRawAlignToT1(mnB0Name, t1FileName, acpcFile);
    doResamp = true;
else
    if(clobber==0)
        resp = questdlg([acpcFile ' exists- would you like to overwrite it?'], 'Clobber AcPc', ...
            'Overwrite','Use Existing File','Abort','Use Existing File');
        if(strcmpi(resp,'Abort')), error('User aborted.'); end
        if(strcmpi(resp,'Overwrite'))
            dtiRawAlignToT1(mnB0Name, t1FileName, acpcFile);
            doResamp = true;
        end
    end
end

% Resample all the DWIs, applying the dti-to structural xform and
% the eddy-current correction xforms. (If eddyCorrect==false, ecFile will
% be empty and dtiRawResample will only do acpcAlignment.)
if((doResamp&&clobber==-1)||clobber==1||~exist(dwAlignedRawFile,'file'))
    dtiRawResample(dwRaw, ecFile, acpcFile, dwAlignedRawFile, bsplineInterpFlag, dwOutMm);
else
    if(clobber==0)
        resp = questdlg([dwAlignedRawFile ' exists- would you like to overwrite it?'], 'Clobber Resampled Data', ...
            'Overwrite','Use Existing File','Abort','Use Existing File');
        if(strcmpi(resp,'Abort')), error('User aborted.'); end
        if(strcmpi(resp,'Overwrite'))
            dtiRawResample(dwRaw, ecFile, acpcFile, dwAlignedRawFile, bsplineInterpFlag, dwOutMm);
        end
    end
end

if(doBvecs||(doResamp&&clobber==-1)||clobber==1||~exist(alignedBvecsFile,'file')||~exist(alignedBvalsFile,'file'))
    dtiRawReorientBvecs(bvecs, ecFile, acpcFile, alignedBvecsFile);
    %copyfile(bvalsFile, alignedBvalsFile);
    dlmwrite(alignedBvalsFile,bvals,' ');
else
    if(clobber==0)
        resp = questdlg([alignedBvecsFile ' exists- would you like to overwrite it?'], 'Clobber Bvecs/bvals', ...
            'Overwrite','Use Existing File','Abort','Use Existing File');
        if(strcmpi(resp,'Abort')), error('User aborted.'); end
        if(strcmpi(resp,'Overwrite'))
            dtiRawReorientBvecs(bvecsFile, ecFile, acpcFile, alignedBvecsFile);
            dlmwrite(alignedBvalsFile,bvals,' ');
        end
    end
end

clear dwRaw;
dwRawAligned = niftiRead(dwAlignedRawFile);

bs.n = numBootStrapSamples;
% We'll use the non-realigned bvecs since we want to count bvecs that are
% only a little differnt due to motion correction as 'repeats'. Also, we
% can count a direction with just a sign-flip as a 'repeat' since it will
% contain essentially the same diffusion info.
% Note that this code is now used just to compute the number of unique
% diffusion directions. We now use a residual bootstrap, so the repetion
% pattern is no long important for the bootstrap.
[bs.permuteMatrix, nNonRepeats, nUniqueDirs] = dtiBootGetPermMatrix(dlmread(bvecsFile), dlmread(bvalsFile));
% We still need an over-determined tensor fit to do residual bootstrap.
% We'll skip the bootstrap for datasets with fewer than 14 measurements
% (7 is the minimum for tensor fitting).
if(size(dwRawAligned.data,4)<14)
    warning('mrDiffusion:bootstrap','Not enough redundancy in the data- skipping bootstrap.');
    bs.n = 0;
end
bs.showProgress = false;
if(isempty(dt6BaseName))
    dt6BaseName = fullfile(subjectDir,sprintf('dti%02d',nUniqueDirs));
    if(~bsplineInterpFlag)
        dt6BaseName = [dt6BaseName 'trilin'];
    end
else
    if(isempty(fileparts(dt6BaseName)))
        % Don't allow a relative path
        dt6BaseName = fullfile(subjectDir,dt6BaseName);
    end
end

% Actual fitting of the tensor is in this file
%dt6FileName = dtiRawFitTensorMex(dwRawAligned, alignedBvecsFile, alignedBvalsFile, dt6BaseName, bs);
dt6FileName = dtiRawFitTensor(dwRawAligned, alignedBvecsFile, alignedBvalsFile, dt6BaseName, bs);
% Make sure paths are correct
%dtiRawFixDt6File(dt6FileName);

% snCheckIm = dtiComputeSpatialNorm(dt6FileName);
% imwrite(makeMontage(snCheckIm),fullfile(dt6BaseName,'MNIalignmentCheck.png'),'CreationTime',now,'Author','mrDiffusion from Stanford University','Description','b0 with MNI overlay');

dt6 = load(dt6FileName,'files');
files = dt6.files;

% Make the t1 filename relative
k = strfind(t1FileName,dtiGetSubjDirInDT6(dt6FileName));
if isempty(k) || ~exist(t1FileName(k:end),'file')
    [p,t1RelFileName,e] = fileparts(t1FileName);
    t1RelFileName = [t1RelFileName e];
    if(exist(fullfile(subjectDir,'t1'),'dir'))
        t1RelFileName = fullfile('t1',t1RelFileName);
    end
else
    t1RelFileName = t1FileName(k+1+length(dtiGetSubjDirInDT6(dt6FileName)):end);
end
files.t1 = t1RelFileName;
% add the raw data file names (these will be full paths)
files.alignedDwRaw = dwAlignedRawFile;
file.alignedDwBvecs = alignedBvecsFile;
file.alignedDwBvals = alignedBvalsFile;
save(dt6FileName,'files','-APPEND');

[pddT1,xform,mm] = dtiRawCheckTensors(fullfile(dt6BaseName,'bin','tensors.nii.gz'),t1FileName);
pddT1 = flipdim(permute(pddT1,[2 1 3 4]),1);
imSlices = [1:2:size(pddT1,3)];
m = makeMontage3(pddT1,imSlices,mm(1),0,[],[],0);
%imshow(m)
imwrite(m,fullfile(dt6BaseName,'t1pdd.png'),'CreationTime',now,'Author','mrDiffusion from Stanford University','Description','T1 with PDD overlay');

% Setup conTrack directory
fiberDir = fullfile(subjectDir,'fibers');
if(~exist(fiberDir,'dir')); mkdir(fiberDir); end;
conTrackDir = fullfile(fiberDir,'conTrack');
if(~exist(conTrackDir,'dir')); mkdir(conTrackDir); end;
paramsName = fullfile(conTrackDir,'met_params.txt');

% Create conTrack options file if it doesn't exist or we need to clobber
bWriteParams = 0;
if(clobber==1||~exist(paramsName,'file'))
    bWriteParams = 1;
else
    if(clobber==0&&exist(paramsName,'file'))
        resp = questdlg([paramsName ' exists- would you like to overwrite it?'], 'Clobber conTrack params', 'Overwrite','Use Existing File','Abort','Use Existing File');
        if(strcmpi(resp,'Abort')); error('User aborted.'); end
        if(strcmpi(resp,'Overwrite'))
            bWriteParams = 1;
        end
    end
end
if( bWriteParams )
    mtr = mtrCreate();
    mtr = mtrSet(mtr, 'tensors_filename', fullfile(subjectDir,'bin','tensors.nii.gz'));
    mtr = mtrSet(mtr, 'fa_filename', fullfile(subjectDir,'bin','wmMask.nii.gz'));
    mtr = mtrSet(mtr, 'pdf_filename', fullfile(subjectDir,'bin','pddDispersion.nii.gz'));
    mtrSave(mtr,paramsName);
end

return;



% %% Example scripts
% %
%
% % to run this on many subjects:
bd = '/biac3/wandell4/data/reading_longitude/dti_adults/';
d = dir(bd);
n = 0;
rf = {'dti_g13_b800.nii.gz'};  % {'dti_g87_b900.nii.gz','dti_g86_b900.nii.gz'}
for ii=1:length(d)
    for jj=1:numel(rf)
        dwFn = fullfile(bd,d(ii).name,'raw',rf{jj});
        if(d(ii).isdir && d(ii).name(1)~='.' && exist(dwFn,'file'))
            n = n+1;
            fn{n} = dwFn;
        end
    end
end
fprintf('Found %d DW raw files...\n',n);

od = 'dti06trilin';
s = true(1,n);
for ii=1:n
    dataDir = fileparts(fn{ii});
    subDir = fileparts(dataDir);
    [junk,subCode] = fileparts(subDir);
    if(exist(fullfile(subDir,od),'dir')&&exist(fullfile(subDir,od,'dt6.mat'),'file'))
        disp([subCode ' already done- skipping.']);
        s(ii) = false;
    end
end
fn = fn(s);
fprintf('Beginning processing on %d files...\n',length(fn));

%matlabpool open 4
%parfor(ii=1:length(fn))
for ii=1:length(fn)
    dataDir = fileparts(fn{ii});
    subDir = fileparts(dataDir);
    [junk,subCode] = fileparts(subDir);
    disp(['Processing ' subCode ' (' fn{ii} ')...']);
    t1 = fullfile(subDir, 't1', 't1.nii.gz');
    try
        % NOTE: this assumes that the grad dirs code and the bvalue are
        % correctly coded in the raw file name. If not, specify them in the
        % 3rd and 4th arguments.
        outName = fullfile(subDir, od);
        %dtiRawPreprocess(dwRawFileName, t1FileName, bvalue, gradDirsCode, clobber, dt6BaseName, flipLrApFlag, numBootStrapSamples, eddyCorrect, excludeVols, bsplineInterpFlag)
        [dt6FileName, outBaseDir] = dtiRawPreprocess(fn{ii}, t1, [], [], false, outName, false, 500, true, [], false);
        % fit the tensor again with the RESTORE method.
        outBaseDir=fullfile(subDir,'raw','dti_g13_b800_aligned_trilin');
        dtiRawFitTensor([outBaseDir '.nii.gz'], [outBaseDir '.bvecs'], [outBaseDir '.bvals'], [outName 'rt'], [], 'rt');
    catch
        disp('FAILED.');
    end
end
%matlabpool close

%
% % Other random code scraps:
%
% % rerun resampling and tensor fitting, but keep other stuff.
% bd = '/biac3/wandell4/data/reading_longitude/dti_y3/';
% d = dir(bd);
% n = 0;
% baseName = 'ssdti_g13_b800';
% for(ii=1:length(d))
%     dwFn = fullfile(bd,d(ii).name,'raw',[baseName '.nii.gz']);
%     if(d(ii).isdir && d(ii).name(1)~='.' && exist(dwFn,'file'))
%         n = n+1;
%         fn{n} = dwFn;
%     end
% end
% fprintf('Found %d DW raw files...\n',n);
%
% od = 'ssdti06trilin';
% for(ii=1:n)
%     dataDir = fileparts(fn{ii});
%     subDir = fileparts(dataDir);
%     [junk,subCode] = fileparts(subDir);
% 	disp(['Processing ' subCode ' (' fn{ii} ')...']);
% 	disp('   removing old realigned data and old tensors...');
% 	delete(fullfile(dataDir,[baseName '_aligned.*']));
% 	%delete(fullfile(dataDir,[baseName '_b0.nii.gz']));
% 	%delete(fullfile(dataDir,[baseName '_acpcXform.mat']));
% 	delete(fullfile(subDir,od,'dt6.mat'));
% 	delete(fullfile(subDir,od,'bin','*'));
% 	disp('   redoing resampling and tensor fitting...');
% 	t1 = fullfile(subDir, 't1', 't1.nii.gz');
%     outName = fullfile(subDir, od);
% 	%dtiRawPreprocess(fn{ii}, t1, 0.8, 13, false, [], false, []);
%     % To do trilin interpolation:
%     [dt6FileName, outBaseDir] = dtiRawPreprocess(fn{ii}, t1, [], [], false, outName, false, 0, true, [], false);
%     % fit the tensor again with the RESTORE method.
%     dtiRawFitTensor([outBaseDir '.nii.gz'], [outBaseDir '.bvecs'], [outBaseDir '.bvals'], [outName 'rt'], [], 'rt');
% end
%
%
%
%
%
% % Fix wrong tensor-element order
% bd = '/biac3/wandell4/data/reading_longitude/dti_y1';
% d = dir(bd);
% n = 0;
% for(ii=1:length(d))
%     tFn = fullfile(bd,d(ii).name,'dti06','bin','tensors.nii.gz');
%     if(d(ii).isdir && d(ii).name(1)~='.' && exist(tFn,'file'))
%         n = n+1;
%         fn{n} = tFn;
%     end
% end
% fprintf('Found %d tensor files- fixing them...\n',n);
% for(ii=1:n)
%     disp(['Fixing ' fn{ii} '...']);
%     ni = niftiRead(fn{ii});
%     % convert upper-tri, row-order convention (Dxx Dxy Dxz Dyy Dyz Dzz) to
%     % lower-tri (Dxx Dxy Dyy Dxz Dyz Dzz).
%     ni.data = ni.data(:,:,:,:,[1 2 4 3 5 6]);
%     writeFileNifti(ni);
% end
%
%
% % Process T1 brain masks
% bd = '/biac2/wandell2/data/reading_longitude/dti';
% d = dir(bd);
% % Save out brain masks
% for(ii=1:length(d))
%   dtFn = fullfile(bd,d(ii).name,[d(ii).name '_dt6_noMask.mat']);
%   bgDir = fullfile(bd,d(ii).name,'bin','backgrounds');
%     if(d(ii).isdir && exist(dtFn,'file'))
%       dt = load(dtFn,'anat');
%       fn = fullfile(bgDir,'t1_brainMask.nii.gz');
%       dtiWriteNiftiWrapper(uint8(dt.anat.brainMask), dt.anat.xformToAcPc, fn, 1.0);
%     end
% end
%
%
% % Check raw data integrity
% bd = '/biac2/wandell2/data/reading_longitude/dti';
% d = dir(bd);
% for(ii=1:length(d))
%     dtFn = fullfile(bd,d(ii).name,[d(ii).name '_dt6_noMask.mat']);
%     if(d(ii).isdir && exist(dtFn,'file'))
%         dwFn = fullfile(bd,d(ii).name,'raw','rawDti.nii.gz');
%         % Now check for a dti raw nifti file
%         if(~exist(dwFn,'file'))
%             fprintf('%s does not exist.\n',dwFn);
%         else
%             dwRaw = niftiRead(dwFn,[]);
%             fprintf('%s: dims = [%d %d %d %d];\n',dwFn,dwRaw.dim);
%         end
%     end
% end
%
