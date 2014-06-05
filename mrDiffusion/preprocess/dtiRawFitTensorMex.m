function [dt6FileName,pdd] = dtiRawFitTensorMex(dwRaw, bvecs, bvals, outBaseName, bs, bCalcBrainMask, fitMethod, adcUnits, xformToAcPc, clobber)
%
% dt6FileName = dtiRawFitTensorMex([dwRaw=uigetfile],
% [bvecsFile=uigetfile], [bvalsFile=uigetfile], [outBaseDir=uigetdir],
% [numBootstrap=[]], [bCalcBrainMask=true], [fitMethod='ls'],
% [adcUnits=dtiGuessAdcUnits], [xformToAcPc=dwRaw.qto_xyz], [clobber=0])
%
% Fits a tensor to the raw DW data. The tensors are saved in outBaseName.
%
% If adcUnits is not provided, we'll try to guess based on the magnitude
% of the mean diffusivity. This guess is based on typical values for
% in-vivo human brain tissue. Our preferred units are 'micron^2/msec',
% because they produce very human-friendly numbers (eg. free diffusion of
% water is 3 micron^2/msec). Your adcUnits are determined by the units in
% which your bvals are specified. (adcUnits = 1/bvalUnits) For our GE
% Bammer/Hedehus DTI sequence, the native bvalUnits are sec/mm^2. However,
% we usually divide the bval by 1000, producing msec/micrometer^2 units.
%
% Currently, the only supported fitMethod is 'ls' (linear least-squares).
%
% You can also specify a number of bootstrap permutations to estimate
% tensor fit uncertainty. To skip the bootstrap, make numBootstrap empty.
% We've found that 200-300 gives a good variance estimate, but 500 is
% probably better.
%
% Currently, specifying the bootstrap causes the resulting dt6 file to have
% the following additional variables:
%
%   faStd, mdStd: standard deviations on fa and mean diffusivity.
%
%   pddDisp: dispersion of PDD axes (based on the Watson) in degrees of
%   angle (54 deg is maximum dispersion).
%
% EXAMPLE:
% f = 'raw/dti_g13_b800_aligned.'; out = 'dti06';
% [outName,pdd] = dtiRawFitTensorMex([f 'nii.gz'], [f 'bvecs'], [f 'bvals'], out, []);
% makeMontage3(abs(pdd));
%
%
% TODO:
%
% * add more statistics to bootstrap. We should fit an assymetric
% distribution to the PDD pdf, like the Bingham. Also, we should do
% ksdensity on fa and md and save out a more complete description of the
% PDFs, as they are not well-fit by the normal assumption implicit in the
% standard deviation.
%
% HISTORY:
%
% 2007.07.31 RFD: wrote it, based on dtiRawFitTensor.
% 2008.09.12 RFD: changed wmMask calc to ignore the b0. Adding the b0
% sometimes helps, but it's contrast is very parameter-dependent, so it is
% difficult to get a generalizable set of parameters. Ignoring it produces
% a fine wmMask, and mask it much more robust.
% 2009.11.15 AJS: Added bCalcBrainMask flag so that I don't throw away
% voxels just because they don't fit the brain mask parameters... this is
% particularly important for phantom data

if(~exist('dwRaw','var')||isempty(dwRaw))
   [f,p] = uigetfile({'*.nii.gz;*.nii';'*.*'}, 'Select the raw DW NIFTI dataset...');
   if(isnumeric(f)) error('User cancelled.'); end
   dwRaw = fullfile(p,f);
end
if(ischar(dwRaw))
    % dwRaw can be a path to the file or the file itself
    [dataDir,rawDataFileName] = fileparts(dwRaw);
else
    [dataDir,rawDataFileName] = fileparts(dwRaw.fname);
end
[junk,inBaseName,junk] = fileparts(rawDataFileName);
if(isempty(dataDir)) dataDir = pwd; end

if(~exist('bvecs','var')||isempty(bvecs))
  bvecs = fullfile(dataDir,[inBaseName '.bvecs']);
  [f,p] = uigetfile({'*.bvecs';'*.*'},'Select the bvecs file...',bvecs);
  if(isnumeric(f)), disp('User canceled.'); return; end
  bvecs = fullfile(p,f);
end
if(~exist('bvals','var')||isempty(bvals))
  bvals = fullfile(dataDir,[inBaseName '.bvals']);
  [f,p] = uigetfile({'*.bvals';'*.*'},'Select the bvals file...',bvals);
  if(isnumeric(f)), disp('User canceled.'); return; end
  bvals = fullfile(p,f);
end
if(~exist('outBaseName','var')||isempty(outBaseName))
    if(nargout==0)
        outBaseName = fullfile(dataDir,inBaseName);
    else
        outBaseName = [];
    end
end
if(~exist('adcUnits','var'))
  adcUnits = '';
end

% If clobber is passed in as 1 and the processing has been done previously
% overwrite the directory that contains the data.
if(~exist('clobber','var')) || isempty('clobber')
    clobber = 0;
end

if(isempty(outBaseName))
    outBaseName = uigetdir(inBaseName,'Select a directory for the data...');
    if(isnumeric(outBaseName)), disp('User canceled.'); return; end
end
dt6FileName = fullfile(outBaseName, 'dt6.mat');
binDirName = fullfile(outBaseName, 'bin');

if(~exist(outBaseName,'dir'))
    mkdir(outBaseName);
else
    if(exist(dt6FileName,'file')||(exist(binDirName,'dir')&&~isempty(dir(fullfile(binDirName,'*.nii*'))))) && clobber ~=1 && clobber ~=-1
        q = ['Output dir ' outBaseName ' exists and appears to contain data. Are you sure that you want to overwrite the data files in there?'];
        resp = questdlg(q,'Confirm Overwrite','Yes','Cancel','Cancel');
        if(strcmp(resp,'Cancel')) disp('canceled.'); return; end
        %error(['Output dir ' outBaseName ' exists and appears to contain data- please move it out of the way.']);
        %outBaseName = uigetdir('Select directory for output...',dt6FileName);
        %if(isnumeric(f)), disp('User canceled.'); return; end
        %dt6FileName = fullfile(p,f);
        %[p,f] = fileparts(dt6FileName);
        %binDirName = fullfile(p,f);
    end
    if (exist(dt6FileName,'file') || (exist(binDirName,'dir') && ~isempty(dir(fullfile(binDirName,'*.nii*'))))) && clobber == -1
        disp('Tensor fitting already completed and "Clobber" is set to "false". Exiting tensor fit.');
        return
    end
end
if(~exist(binDirName,'dir'))
    mkdir(binDirName);
end
disp(['data will be saved to ' outBaseName '.']);

if(ischar(dwRaw))
    % dwRaw can be a path to the file or the file itself
    disp(['Loading raw data ' dwRaw '...']);
    dwRaw = niftiRead(dwRaw);
    weLoadedRaw = true;
else
    weLoadedRaw = false;
end

nvols = size(dwRaw.data,4);
mmPerVox = dwRaw.pixdim(1:3);
if(~exist('xformToAcPc','var')||isempty(xformToAcPc))
  xformToAcPc = dwRaw.qto_xyz;
end

if(~exist('bs','var')||isempty(bs))
    bs.n = 0;
elseif(~isstruct(bs))
    tmp = bs; clear bs;
    bs.n = tmp;
end
if(bs.n<=1)
    bs.permutations = [];
else
    bs.permutations = dtiBootGetPermutations(nvols, bs.n);
end

if(~exist('fitMethod','var')||isempty(fitMethod))
    fitMethod = 'ls';
end
if(~strcmpi(fitMethod,'ls')), error('Currently only fitMethod=''ls'' is supported.'); end

if(ieNotDefined('bCalcBrainMask')); bCalcBrainMask=true; end


%% Load the bvecs & bvals
% NOTE: these are assumed to be specified in image space.
% If bvecs are in scanner space, use dtiReorientBvecs and
% dtiRawReorientBvecs.
if(~isnumeric(bvecs))
  %bvecs = dlmread(bvecs, ' ');
  bvecs = dlmread(bvecs);
end
if(~isnumeric(bvals))
  %bvals = dlmread(bvals, ' ');
  bvals = dlmread(bvals);
end

if(size(bvecs,2)~=nvols || size(bvals,2)~=nvols)
  error(['bvecs/bvals: need one entry for each of the ' num2str(nvols) ' volumes.']);
end

d = double(dwRaw.data);
clear dwRaw;
minD = min(d(d(:)>0));

%% Compute a brain mask
%
disp('Computing brain mask from average b0...');
b0 = mean(d(:,:,:,bvals<=0.01),4);
try
    % try using BET
    brainMask = uint8(mrAnatExtractBrain(int16(round(b0)), mmPerVox, 0.3));
    liberalBrainMask = brainMask;
catch
    warning('Brain extraction using BET failed- using a simple threshold method.');
    b0clip = mrAnatHistogramClip(b0,0.4,0.98);
    % We use a liberal brain mask for deciding which tensors to compute, but a
    % more conservative mask will be saved so that that the junk outside the
    % brain won't be displayed when we view the data.
    liberalBrainMask = dtiCleanImageMask(b0clip>0.1&all(d>0,4),10,1,0.25,50);
    % force the data to be physically plausible.
    d(d<=0) = minD;
    liberalBrainMask = uint8(liberalBrainMask);
    brainMask = uint8(dtiCleanImageMask(b0clip>0.2,7));
    % make sure the display-purposes brain mask is a subset of the
    % tensor-fitting (liberal) brain mask.
    brainMask(~liberalBrainMask) = 0;
    clear b0clip badEdgeVox;
end

% Remove brain masking if I didn't want it
if ~bCalcBrainMask
    brainMask(:) = 1;
    liberalBrainMask(:) = 1;
end

b0 = int16(round(b0));

%% Fit the tensor maps.
%
disp('Fitting the tensor model...');
% Compute the X-matrix (this will be inverted for the tensor fit)
% Each row is of the form:
% [1, -b bvx bvx, -b bvy bvy, -b bvz bvz, -2b bvx bvy, -2b bvx bvz, -2b bvy bvz].
% b = norm(q)*tau, where:
%   tau (DELTA) is the diffusion time- the time between beginning of first DW
%       gradient pulse and second DW gradient pulse
%   q is the gyromagnetic ratio of the proton times the gradient strength and
%       delta, where delta is the DW gradient pulse duration
% NOTE: tau must use the same time units as bvals for tau~=1 to work.
%tau = 40;
tau = 1;
q = [bvecs.*sqrt(repmat(bvals./tau,3,1))]';
X = [ones(size(q,1),1) -tau.*q(:,1).^2 -tau.*q(:,2).^2 -tau.*q(:,3).^2 -2*tau.*q(:,1).*q(:,2) -2*tau.*q(:,1).*q(:,3) -2*tau.*q(:,2).*q(:,3)];

tic;
if(bs.n>1)
    [dt6,pdd,mdStd,faStd,pddDisp] = dtiFitTensor(d,X,0,bs.permutations,liberalBrainMask);
else
    [dt6,pdd] = dtiFitTensor(d,X,0,[],liberalBrainMask);
end
toc
%makeMontage3(abs(pdd));
% The first volume is the b=0 derived from the tensor fit
dt6 = dt6(:,:,:,[2:7]);


%% Compute a rough white-matter mask
%
wmProb = dtiFindWhiteMatter(dt6,[]);
wmProb(~brainMask) = 0;
wmProb = uint8(round(wmProb*255));
%wmMask = wmProb>0.5;
%wmMask = uint8(dtiCleanImageMask(wmMask,0,0));

%% Save all results
%
params.nBootSamps = bs.n;
params.buildDate = datestr(now,'yyyy-mm-dd HH:MM');
l = license('inuse');
params.buildId = sprintf('%s on Matlab R%s (%s)',l(1).user,version('-release'),computer);
params.rawDataDir = dataDir;
params.rawDataFile = rawDataFileName;
% We assume that the raw data file is a directory inside the 'subject'
% directory.
params.subDir = fileparts(dataDir);

% We want all the important file names to be relative so that they are
% platform-independent. The only platform-dependent path should be
% 'homeDir'. As long as the dt6 project file stays in the same dir as the
% bin dir, we shouldn't need 'homeDir' to find everything.
%
%  TONY: Every filename now is relative to the directory above the
%  directory containing this dt6.  Thus we have no system dependent
%  information.  Just make sure the relative paths stay the same.
%[files.homeDir,files.binDir] = fileparts(binDirName);
[fullParentDir, binDir] = fileparts(binDirName);
[ppBinDir, pBinDir] = fileparts(fullParentDir);
pBinDir = fullfile(pBinDir,binDir);
files.b0 = fullfile(pBinDir,'b0.nii.gz');
files.brainMask = fullfile(pBinDir,'brainMask.nii.gz');
files.wmMask  = fullfile(pBinDir,'wmMask.nii.gz');
files.wmProb  = fullfile(pBinDir,'wmProb.nii.gz');
files.tensors = fullfile(pBinDir,'tensors.nii.gz');
files.vecRgb  = fullfile(pBinDir,'vectorRGB.nii.gz');
% description can have up to 80 chars
desc = [params.buildDate ' ' params.buildId];

if(length(desc)>80) warning('description field clipped to 80 chars.'); end
dtiWriteNiftiWrapper(int16(round(b0)), xformToAcPc, fullfile(ppBinDir,files.b0), 1, desc, 'b0');
dtiWriteNiftiWrapper(brainMask, xformToAcPc, fullfile(ppBinDir,files.brainMask), 1, desc, 'brainMask');
dtiWriteNiftiWrapper(wmProb, xformToAcPc, fullfile(ppBinDir,files.wmProb), 1/255, desc, 'P(whiteMatter)');
dtiWriteNiftiWrapper(uint8(wmProb>=0.5), xformToAcPc, fullfile(ppBinDir,files.wmMask), 1, desc, 'whitematter mask');

% WORK HERE?
dtiWriteNiftiWrapper(uint8(round(pdd.*255)), xformToAcPc, ...
    fullfile(ppBinDir,files.vecRgb), 1/255, desc, 'PDD/FA');
% NIFTI convention is for the 6 unique tensor elements stored in the 5th
% dim in lower-triangular, row-order (Dxx Dxy Dyy Dxz Dyz Dzz). NIFTI
% reserves the 4th dim for time, so in the case of a time-invatiant tensor,
% we just leave a singleton 4th dim. Our own internal convention is
% [Dxx, Dyy, Dzz, Dxy, Dxz, Dyz], so we use the code below to convert to
% the NIFTI order and dt6=squeeze(ni.data(:,:,:,1,[1 3 6 2 4 5])); to get
% back to our convention. FOr reference- the 3x3 tensor matrix is:
%    Dxx Dxy Dxz
%    Dxy Dyy Dyz
%    Dxz Dyz Dzz
dt6 = dt6(:,:,:,[1 4 2 5 6 3]);
sz = size(dt6);
dt6 = reshape(dt6,[sz(1:3),1,sz(4)]);
dtiWriteNiftiWrapper(dt6, xformToAcPc, ...
    fullfile(ppBinDir,files.tensors), 1, desc, ['DTI ' adcUnits]);
if(bs.n>1)
    files.faStd = fullfile(pBinDir,'faStd.nii.gz');
    files.mdStd = fullfile(pBinDir,'mdStd.nii.gz');
    files.pddDisp = fullfile(pBinDir,'pddDispersion.nii.gz');
    dtiWriteNiftiWrapper(single(faStd), xformToAcPc, fullfile(ppBinDir,files.faStd), 1, desc, 'FA stdev');
    dtiWriteNiftiWrapper(single(mdStd), xformToAcPc, fullfile(ppBinDir,files.mdStd), 1, desc, 'MD stdev');
    dtiWriteNiftiWrapper(pddDisp, xformToAcPc, fullfile(ppBinDir,files.pddDisp), 1, desc, 'PDD disp (deg)');
end
save(dt6FileName,'adcUnits','params','files');
if(nargout<1), clear dt6; end

return;
