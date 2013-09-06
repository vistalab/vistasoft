function dt6FileName = dtiRawPreprocessSimple(dwRawFileName, bvalsFile, bvecsFile, t1FileName, dt6BaseName, numBootStrapSamples, dwOutMm)
%
% dtiRawPreprocessSimple([dwRawFileName], [bvalFile], [bvecFile],
%                        [t1FileName], [dt6BaseName='dti'],
%                        [numBootStrapSamples=500], [dwOutMm=[2 2 2]]) 
%
% A function for running a simple version of the mrDiffusion pre-processing
% steps on raw DWI data. This is similar to dtiRawPreprocess, but skips
% alignment to a t1 anatomical and assumes that you already have
% appropriate bvals/bvecs files.
%
% This assumes that you've already generated the raw NIFTI data file with
% something like dinifti.
%
% HISTORY:
% 2010.11.29 RFD wrote it.
%

% 1 = always clobber existing files, -1 = never replace existing files, just
% load them and use them, 0 = ask the user what to do for each file
clobber = -1;

outSuffix = '_aligned';
excludeVols = [];
bsplineInterpFlag = false;

if(~exist('dwOutMm','var')||isempty(dwOutMm))
    % The eddy-current-corrected, aligned diffusion images will be resampled at
    % 2mm isotropic voxels by default.
    dwOutMm = [2 2 2];
end

if(~exist('dt6BaseName','var')||isempty(dt6BaseName))
    dt6BaseName = '';
end

if(~exist('numBootStrapSamples','var')||isempty(numBootStrapSamples))
  numBootStrapSamples = 500;
end

mrDiffusionDir = fileparts(which('mrDiffusion.m'));

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
outBaseDir = fullfile(dataDir,outBaseName);
inBaseDir = fullfile(dataDir,inBaseName);
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
if(~exist(t1FileName,'file'))
    error(['Couldn''t find t1 data file "' t1FileName '".']);
end

%bvalsFile = [inBaseDir '.bval'];
%bvecsFile = [inBaseDir '.bvec'];
if(~exist('bvalsFile','var')||isempty(bvalsFile))
    [f,p] = uigetfile({'*.bval';'*.bvals';'*.*'},'Select the bvals file...');
    if(isnumeric(f)), disp('User canceled.'); return; end
    bvalsFile = fullfile(p,f); 
end
if(~exist('bvecsFile','var')||isempty(bvecsFile))
    [f,p] = uigetfile({'*.bvec';'*.bvecs';'*.*'},'Select the bvecs file...');
    if(isnumeric(f)), disp('User canceled.'); return; end
    bvecsFile = fullfile(p,f); 
end

ecFile = [inBaseDir '_ecXform.mat'];
acpcFile = [inBaseDir '_acpcXform.mat'];
alignedBvecsFile = [outBaseDir '.bvecs'];
alignedBvalsFile = [outBaseDir '.bvals'];
dwAlignedRawFile = [outBaseDir '.nii.gz'];

disp('loading raw data...');
dwRaw = niftiRead(dwRawFileName);
oldPhaseDim = dwRaw.phase_dim;
% *** FIXME: the canXform might need to be applied to bvecs.
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

doResamp = false;

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


% Compute the eddy-current correction for all the DWIs (SLOW!)
if(clobber==1||~exist(ecFile,'file'))
    dtiRawRohdeEstimateEddyMotion(dwRaw, mnB0Name, bvals, ecFile);
    doResamp = true;
else
    if(clobber==0)
        resp = questdlg([ecFile ' exists- would you like to overwrite it?'], 'Clobber EddyCorrect', ...
            'Overwrite','Use Existing File','Abort','Use Existing File');
        if(strcmpi(resp,'Abort')), error('User aborted.'); end
        if(strcmpi(resp,'Overwrite'))
            dtiRawRohdeEstimateEddyMotion(dwRaw, mnB0Name, bvals, ecFile);
            doResamp = true;
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
% the eddy-current correction xforms. 
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

if((doResamp&&clobber==-1)||clobber==1||~exist(alignedBvecsFile,'file')||~exist(alignedBvalsFile,'file'))
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
    if(bsplineInterpFlag)
        dt6BaseName = [dt6BaseName 'bs'];
    end
else
    if(isempty(fileparts(dt6BaseName)))
        % Don't allow a relative path
        dt6BaseName = fullfile(subjectDir,dt6BaseName);
    end
end

dt6FileName = dtiRawFitTensorMex(dwRawAligned, alignedBvecsFile, alignedBvalsFile, dt6BaseName, bs);
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
