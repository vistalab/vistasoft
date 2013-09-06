function dtiRawPreprocess(dwRawFileName, t1FileName, bvalue, gradDirsCode, clobber, dt6BaseName, assetFlag, numBootStrapSamples)
%
% dtiRawPreprocess(dwRawFileName, t1FileName, [bvalue],
% [gradDirsCode], [clobber='ask'], [dt6BaseName='dti'],
% [assetFlag=false], [numBootStrapSamples=500])
%
% A function for running the mrDiffusion pre-processing steps on raw
% DWI data.
%
% If clobber=='always' or true, then existing output files will be
% silently overwritten. If clobber=='ask' (the default), then you'll
% be asked if you want to recompute the file or use the existing
% one. If clobber=='never' or false, then any existing files will
% be used and only those that are missing will be recomputed.
%
% If t1MaskFileName == 'nomask', then no t1-based brain mask will
% be used in the dti-to-structural alignment step. 
%
% This assumes that you've already generated the raw NIFTI data file with
% something like dinifti.
%
% If you collected your DTI data using GE's ASSET, you may be 
% prompted to provide phase-encode direction (1= LR, 2=AP). 
% Information about this, as well as the b-value and gradient code,
% can be found in the dicom file header. More detailed instructions
% can be found here:
%   http://white.stanford.edu/newlm/index.php/DTI#DTI_data_pre-processing. 
%
% WARNING: spm_coreg is broken under Matlab r2006b (and later) on a64
% platforms. It won't return an error, but wil iterate forever. Not sure
% why, but it seems to work OK on r2006a. Probably an issue with a mex file
% and library dependencies. 
%
% TO DO:
% * Ask all questions up front.
%
% HISTORY:
% 2007.?? RFD wrote it.
% 2007.04.20 RFD: cleaned it up a bit and make it a real function.
% 2007.07.20 AJS: Relative filenames to the parent directory.


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
bsplineInterpFlag = false;

% The eddy-current-corrected, aligned diffusion images will be resampled at
% 2mm isotropic voxels by default. 
dwOutMm = [2 2 2];

doEddyCorrect = false;

if(~exist('clobber','var')||isempty(clobber))
    clobber = 'ask';
end
if(~exist('dt6BaseName','var')||isempty(dt6BaseName))
    dt6BaseName = 'dti';
end
if(~exist('assetFlag','var')||isempty(assetFlag))
    assetFlag = false;
end
if(~exist('numBootStrapSamples','var')||isempty(numBootStrapSamples))
  numBootStrapSamples = 500;
end

if(islogical(clobber))
  if(clobber) clobber = 'always';
  else clobber = 'no'; end
end
if(strcmpi(clobber,'always')) clobber = 1;
elseif(strcmpi(clobber,'no')) clobber = -1;
else clobber = 0; end

if(~exist('dwRawFileName','var')||isempty(dwRawFileName))
    [f,p] = uigetfile({'*.nii.gz';'*.*'},'Select a raw NIFTI file for input...');
    if(isnumeric(f)), disp('User canceled.'); return; end
    dwRawFileName = fullfile(p,f); 
end

[dataDir,inBaseName,ext] = fileparts(dwRawFileName);
[junk,inBaseName,junk] = fileparts(inBaseName);
if(isempty(dataDir)) dataDir = pwd; end
mnB0Name = fullfile(dataDir,[inBaseName '_b0.nii.gz']);

outBaseName = [inBaseName '_aligned'];
outBaseDir = fullfile(dataDir,outBaseName);
inBaseDir = fullfile(dataDir,inBaseName);
% Default output dir is one level above the dataDir. We assume that
% this is the 'subjectDir', which contains the 'raw' data dir. 
subjectDir = fileparts(dataDir);
if(isempty(subjectDir)) subjectDir = pwd; end

if(~exist('t1FileName','var')||isempty(t1FileName))
    t1FileName = fullfile(subjectDir,'t1','t1.nii.gz');
    [f,p] = uigetfile('*.nii.gz','Select the t1-file for alignment...',t1FileName);
    if(isnumeric(f)) error('user canceled.'); end
    t1FileName = fullfile(p,f);
elseif(strcmpi(t1FileName,'MNI'))
  t1FileName = fullfile(fileparts(which('mrDiffusion.m')),'templates','MNI_EPI.nii.gz');
  disp('The MNI EPI template will be used for alignment.');
end

bvalsFile = [inBaseDir '.bvals'];
bvecsFile = [inBaseDir '.bvecs'];
ecFile = [inBaseDir '_ecXform.mat'];
acpcFile = [inBaseDir '_acpcXform.mat'];
alignedBvecsFile = [outBaseDir '.bvecs'];
alignedBvalsFile = [outBaseDir '.bvals'];
dwAlignedRawFile = [outBaseDir '.nii.gz'];

disp('loading raw data...');
dwRaw = niftiRead(dwRawFileName);
oldPhaseDim = dwRaw.phase_dim;
% For the Siemens data niftified via dcm2nii, the sto contains the correct
% xform. (*** Need to figure this out ***)
dwRaw = niftiSetQto(dwRaw, dwRaw.sto_xyz);
[dwRaw,canXform] = niftiApplyCannonicalXform(dwRaw);
% Make sure there is a valid phase-encode dir, as this is crucial for
% eddy-current correction.
while(dwRaw.phase_dim<1 || dwRaw.phase_dim>3)
    prompt = sprintf('Phase-encode dir is currently %d, but must be 1, 2 or 3. New value:',dwRaw.phase_dim);
    resp = inputdlg(prompt,'Set phase encode direction',1,{'2'});
    if(~isempty(resp))
        dwRaw.phase_dim = round(str2double(resp{1}));
    end
end
if(~all(all(canXform==eye(4)))||dwRaw.phase_dim~=oldPhaseDim)
    %disp('Saving re-oriented raw data.');
    %writeFileNifti(dwRaw);
end
fprintf('dataDir = %s; dims = [%d %d %d %d];\n',dataDir,size(dwRaw.data));
fprintf('t1FileName = %s;\n',t1FileName);

if(~exist(bvalsFile,'file')||~exist(bvecsFile,'file'))
  % Generate bvecs file and a bvals file from a dwepi.grads file.
  % *** FIX ME: get the bval and grad dir file number from the
  % dicom header.
  doBvecs = true;
  if(~exist('bvalue','var')||isempty(bvalue))
      bvalue = [];
      s = strfind(inBaseName,'_b');
      if(~isempty(s)&&length(s)==1&&length(inBaseName)>s+1)
          tmp = inBaseName(s+2:end);
          s = strfind(tmp,'_');
          if(~isempty(s)) tmp = tmp(1:s(1)-1); end
          bvGuess = str2double(tmp);
          % sanity-check
          if(bvGuess>=10&&bvGuess<=15000)
              bvalue = bvGuess/1000;
          end
      end
      if(isempty(bvalue))
        bvalue = 0.8;
        resp = inputdlg('b-value (in millimeters^2/msec):','b-value',1,{num2str(bvalue*1000)});
        if(isempty(resp)) error('canceled'); end
        bvalue = str2double(resp)/1000;
      end
  end
  if(~exist('gradDirsCode','var')||isempty(gradDirsCode))
      gradDirsCode = [];
      gradsFile = '/usr/local/dti/diffusion_grads/';
      if(~exist(gradsFile,'dir')) gradsFile = dataDir; end
      s = strfind(inBaseName,'_g');
      if(~isempty(s)&&length(s)==1&&length(inBaseName)>s+1)
          tmp = inBaseName(s+2:end);
          s = strfind(tmp,'_');
          if(~isempty(s)) tmp = tmp(1:s(1)-1); end
          gcGuess = str2double(tmp);
          % sanity-check
          if(gcGuess>0&&gcGuess<=10000)
              gradDirsCode = gcGuess;
          end
      end
      if(isempty(gradDirsCode))
        [f,p] = uigetfile({'*.grads';'*.*'},'Select the GE grads file...',gradsFile);
        if(isnumeric(f)) error('Canceled.'); end
        gradDirsCode = fullfile(p,f);
      end
  end
  if(ischar(gradDirsCode))
    gradsFile = gradDirsCode;
  else
    gradsFile = sprintf('/usr/local/dti/diffusion_grads/dwepi.%d.grads',gradDirsCode);
  end
  %fprintf('NOTE: bvals/bvecs not found- building them with bval=%f micrometers^2/msec, gradDirsCode=%d.\n',bvalue,gradDirsCode);
  % NOTE: most sequences will need the bvecs reoriented based on the
  % scanner-to-image transform stored in qto_ijk. But, for our Bammer
  % sequence, the bvecs were rotated during image acquisition.
  %dtiRawBuildBvecs(size(dwRaw.data,4), dwRaw.qto_ijk, gradsFile, bvalue, inBaseName);
  dtiRawBuildBvecs(size(dwRaw.data,4), eye(4), gradsFile, bvalue, inBaseDir, assetFlag);
  fprintf('bvalsFile = %s; %% (bvalue = %0.3f)\nbvecsFile = %s; %%(gradDirsCode = %d)\n',bvalsFile,bvalue,bvecsFile,gradDirsCode);
else
    doBvecs = false;
end

doResamp = false;

% Check for missing data and fix, if necessary
% *** TODO: allow arbitrary volumes to be skipped downstream to avoid
% needing to touch the raw data here.
goodVols = squeeze(max(max(max(dwRaw.data))))~=0;
if(~all(goodVols))
    badVols = find(~goodVols);
  fprintf('WARNING: Found %d empty volumes in data (%d)!\n',numel(badVols),badVols);
  if(0)
      dwRaw.data = dwRaw.data(:,:,:,goodVols);
      writeFileNifti(dwRaw);
      bvecs = dlmread(bvecsFile);
      bvals = dlmread(bvalsFile);
      bvecs = bvecs(:,goodVols);
      bvals = bvals(goodVols);
      dlmwrite(bvecsFile,bvecs,' ');
      dlmwrite(bvalsFile,bvals,' ');
      doResamp = true;
  end
else
  bvecs = dlmread(bvecsFile);
  bvals = dlmread(bvalsFile);
  if(length(goodVols)<size(bvecs,2))
	warning('More bvecs than vols- ignoring some bvecs...');
    bvecs = bvecs(:,goodVols);
	dlmwrite(bvecsFile,bvecs,' ');
  end
  if(length(goodVols)<size(bvals,2))
	warning('More bvals than vols- ignoring some bvals...');
    bvals = bvals(goodVols);
    dlmwrite(bvalsFile,bvals,' ');
  end
end



% Get a mean b0 to be used for eddy-current correction and
% alignment to a structural scan.
if(clobber==1||~exist(mnB0Name,'file'))
  dtiRawComputeMeanB0(dwRaw, bvalsFile, mnB0Name);
else
  if(clobber==0)
    resp = questdlg([mnB0Name ' exists- would you like to overwrite it?'], 'Clobber mnB0', 'Overwrite','Use Existing File','Abort','Use Existing File');
    if(strcmpi(resp,'Abort')) error('User aborted.'); end
    if(strcmpi(resp,'Overwrite'))
      dtiRawComputeMeanB0(dwRaw, bvalsFile, mnB0Name);
    end
  end
end

if(doEddyCorrect)
    % Compute the eddy-current correction for all the DWIs (SLOW!)
    if(clobber==1||~exist(ecFile,'file'))
        dtiRawRohdeEstimateEddyMotion(dwRaw, mnB0Name, bvalsFile, ecFile);
        doResamp = true;
    else
        if(clobber==0)
            resp = questdlg([ecFile ' exists- would you like to overwrite it?'], 'Clobber EddyCorrect', ...
                'Overwrite','Use Existing File','Abort','Use Existing File');
            if(strcmpi(resp,'Abort')) error('User aborted.'); end
            if(strcmpi(resp,'Overwrite'))
                dtiRawRohdeEstimateEddyMotion(dwRaw, mnB0Name, bvalsFile, ecFile);
                doResamp = true;
            end
        end
    end
else
    ecFile = [];
end

% Compute the dti-structural alignment
if(clobber==1||~exist(acpcFile,'file'))
  dtiRawAlignToT1(mnB0Name, t1FileName, acpcFile);
  doResamp = true;
else
  if(clobber==0)
    resp = questdlg([acpcFile ' exists- would you like to overwrite it?'], 'Clobber AcPc', ...
		    'Overwrite','Use Existing File','Abort','Use Existing File');
    if(strcmpi(resp,'Abort')) error('User aborted.'); end
    if(strcmpi(resp,'Overwrite'))
      dtiRawAlignToT1(mnB0Name, t1FileName, acpcFile, t1MaskFileName);
      doResamp = true;
    end
  end
end

% Resample all the DWIs, applying the dti-to structural xform and
% the eddy-current correction xforms. 
if((doResamp&&clobber==-1)||clobber==1||~exist(dwAlignedRawFile,'file'))
  dtiRawResample(dwRaw, ecFile, acpcFile, dwAlignedRawFile, bsplineInterpFlag);
else
  if(clobber==0)
    resp = questdlg([dwAlignedRawFile ' exists- would you like to overwrite it?'], 'Clobber Resampled Data', ...
		    'Overwrite','Use Existing File','Abort','Use Existing File');
    if(strcmpi(resp,'Abort')) error('User aborted.'); end
    if(strcmpi(resp,'Overwrite'))
      dtiRawResample(dwRaw, ecFile, acpcFile, dwAlignedRawFile, bsplineInterpFlag, dwOutMm);
    end
  end
end

% Be sure to apply the cannonical xform to the bvecs.
% We bundle it in with the acpc xform here.
bvecs = dlmread(bvecsFile);
% rot = canXform(1:3,1:3);
% for(ii=1:size(bvecs,2))
%    bvecs(:,ii) = rot*bvecs(:,ii);
% end
%dlmwrite(bvecsFile,bvecs,' ');
if(doBvecs||(doResamp&&clobber==-1)||clobber==1||~exist(alignedBvecsFile,'file')||~exist(alignedBvalsFile))
    dtiRawReorientBvecs(bvecs, ecFile, acpcFile, alignedBvecsFile);
    copyfile(bvalsFile, alignedBvalsFile);
else
    if(clobber==0)
        resp = questdlg([alignedBvecsFile ' exists- would you like to overwrite it?'], 'Clobber Bvecs/bvals', ...
            'Overwrite','Use Existing File','Abort','Use Existing File');
        if(strcmpi(resp,'Abort')) error('User aborted.'); end
        if(strcmpi(resp,'Overwrite'))
            dtiRawReorientBvecs(bvecs, ecFile, acpcCanXform, alignedBvecsFile);
            copyfile(bvalsFile, alignedBvalsFile);
        end
    end
end

clear dwRaw;
dwRawAligned = niftiRead(dwAlignedRawFile);

bs.n = numBootStrapSamples;
%bs.maxMem = maxMemoryToUse;
% We'll use the non-realigned bvecs since we want to count bvecs that are
% only a little differnt due to motion correction as 'repeats'. Also, we
% can count a direction with just a sign-flip as a 'repeat' since it will
% contain essentially the same diffusion info. 
[bs.permuteMatrix, nNonRepeats, nUniqueDirs, nUniqueMeasurements] = dtiBootGetPermMatrix(dlmread(bvecsFile), dlmread(bvalsFile));
if(nNonRepeats>(0.9*nUniqueMeasurements))
    warning('Most measurements were not repeated- skipping bootstrap.');
    bs.n = 0;
elseif(nNonRepeats>0)
    warning('%n measurements were not repeated- bootstrap analysis might be bogus.',nNonRepeats);
end
bs.showProgress = false;
dt6BaseName = fullfile(subjectDir,sprintf('%s%02d',dt6BaseName,nUniqueDirs));

dt6FileName = dtiRawFitTensorMex(dwRawAligned, alignedBvecsFile, alignedBvalsFile, dt6BaseName, bs);
dt6 = load(dt6FileName,'files');
files = dt6.files;
% Make the t1 filename relative
k = strfind(t1FileName,dtiGetSubjDirInDT6(dt6FileName));
if isempty(k) || ~exist(fullfile(dtiGetSubjDirInDT6(dt6FileName),t1FileName(k:end)),'file')
  [p,t1RelFileName,e] = fileparts(t1FileName);
  t1RelFileName = [t1RelFileName e];
  if(exist(fullfile(subjectDir,'t1'),'dir'))
	t1RelFileName = fullfile('t1',t1RelFileName);
  end
else
  t1RelFileName = t1FileName(k:end);
end
files.t1 = t1RelFileName;
save(dt6FileName,'files','-APPEND')

return;

[pddT1,xform,mm] = dtiRawCheckTensors(fullfile(dt6BaseName,'bin','tensors.nii.gz'),t1FileName);
pddT1 = flipdim(permute(pddT1,[2 1 3 4]),1);
acpcSl = [-26:2:56];
imSlices = mrAnatXformCoords(xform,[zeros(length(acpcSl),2) acpcSl']);
m = makeMontage3(pddT1,round(imSlices(:,3)),mm(1),0,[],[],0);
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



%% Example scripts
%

% to run this on many subjects:
bd = '/biac3/wandell4/data/reading_longitude/dti_y3/';
d = dir(bd);
n = 0;
for(ii=1:length(d))
    dwFn = fullfile(bd,d(ii).name,'raw','dti_g13_b800.nii.gz');
    if(d(ii).isdir && d(ii).name(1)~='.' && exist(dwFn,'file'))
        n = n+1;
        fn{n} = dwFn;
    end
end
fprintf('Found %d DW raw files...\n',n);

s = true(1,n);
for(ii=1:n)
    dataDir = fileparts(fn{ii});
    subDir = fileparts(dataDir);
    [junk,subCode] = fileparts(subDir);
    if(exist(fullfile(subDir,'dti06'),'dir')&&exist(fullfile(subDir,'dti06','dt6.mat'),'file'))
        disp([subCode ' already done- skipping.']);
		s(ii) = false;
	end
end
fn = fn(s);
fprintf('Beginning processing on %d files...\n',length(fn));

for(ii=1:length(fn))
    dataDir = fileparts(fn{ii});
    subDir = fileparts(dataDir);
    [junk,subCode] = fileparts(subDir);
    if(exist(fullfile(subDir,'dti06'),'dir'))
        disp([subCode ' already done- skipping.']);
    else
        disp(['Processing ' subCode ' (' fn{ii} ')...']);
        t1 = fullfile(subDir, 't1', 't1.nii.gz');
        try
            dtiRawPreprocess(fn{ii}, t1, 0.8, 13, false);
        catch
            disp('FAILED.');
        end
    end
end

% Other random code scraps:

% rerun resampling and tensor fitting, but keep other stuff.
bd = '/biac3/wandell4/data/reading_longitude/dti_y2/';
d = dir(bd);
n = 0;
baseName = 'dti_g13_b800';
for(ii=1:length(d))
    dwFn = fullfile(bd,d(ii).name,'raw',[baseName '.nii.gz']);
    if(d(ii).isdir && d(ii).name(1)~='.' && exist(dwFn,'file'))
        n = n+1;
        fn{n} = dwFn;
    end
end
fprintf('Found %d DW raw files...\n',n);

for(ii=1:n)
    dataDir = fileparts(fn{ii});
    subDir = fileparts(dataDir);
    [junk,subCode] = fileparts(subDir);
	disp(['Processing ' subCode ' (' fn{ii} ')...']);
	disp('   removing old realigned data and old tensors...');
	delete(fullfile(dataDir,[baseName '_aligned.*']));
	delete(fullfile(dataDir,[baseName '_b0.nii.gz']));
	delete(fullfile(dataDir,[baseName '_acpcXform.mat']));
	delete(fullfile(subDir,'dti06','dt6.mat'));
	delete(fullfile(subDir,'dti06','bin','*'));
	disp('   redoing resampling and tensor fitting...');	
	t1 = fullfile(subDir, 't1', 't1.nii.gz');
	dtiRawPreprocess(fn{ii}, t1, 0.8, 13, false, [], false, []);
end





% Fix wrong tensor-element order
bd = '/biac3/wandell4/data/reading_longitude/dti_y1';
d = dir(bd);
n = 0;
for(ii=1:length(d))
    tFn = fullfile(bd,d(ii).name,'dti06','bin','tensors.nii.gz');
    if(d(ii).isdir && d(ii).name(1)~='.' && exist(tFn,'file'))
        n = n+1;
        fn{n} = tFn;
    end
end
fprintf('Found %d tensor files- fixing them...\n',n);
for(ii=1:n)
    disp(['Fixing ' fn{ii} '...']);
    ni = niftiRead(fn{ii});
    % convert upper-tri, row-order convention (Dxx Dxy Dxz Dyy Dyz Dzz) to
    % lower-tri (Dxx Dxy Dyy Dxz Dyz Dzz).
    ni.data = ni.data(:,:,:,:,[1 2 4 3 5 6]);
    writeFileNifti(ni);
end


% Process T1 brain masks
bd = '/biac2/wandell2/data/reading_longitude/dti';
d = dir(bd);
% Save out brain masks
for(ii=1:length(d))
  dtFn = fullfile(bd,d(ii).name,[d(ii).name '_dt6_noMask.mat']);
  bgDir = fullfile(bd,d(ii).name,'bin','backgrounds');
    if(d(ii).isdir && exist(dtFn,'file'))
      dt = load(dtFn,'anat');
      fn = fullfile(bgDir,'t1_brainMask.nii.gz');
      dtiWriteNiftiWrapper(uint8(dt.anat.brainMask), dt.anat.xformToAcPc, fn, 1.0);
    end
end


% Check raw data integrity
bd = '/biac2/wandell2/data/reading_longitude/dti';
d = dir(bd);
for(ii=1:length(d))
    dtFn = fullfile(bd,d(ii).name,[d(ii).name '_dt6_noMask.mat']);
    if(d(ii).isdir && exist(dtFn,'file'))
        dwFn = fullfile(bd,d(ii).name,'raw','rawDti.nii.gz');
        % Now check for a dti raw nifti file
        if(~exist(dwFn,'file'))
            fprintf('%s does not exist.\n',dwFn);
        else
            dwRaw = niftiRead(dwFn,[]);
            fprintf('%s: dims = [%d %d %d %d];\n',dwFn,dwRaw.dim);
        end
    end
end

