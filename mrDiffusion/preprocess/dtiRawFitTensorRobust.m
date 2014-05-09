function dt6FileName = dtiRawFitTensorRobust(dwRaw, bvecs, bvals, ... 
                       outBaseName, brainMask, adcUnits, xformToAcPc, ... 
                       nstep, clobber, noiseCalcMethod)
% Fits a tensor to the raw DW data using the restore algorithm
%
% dt6FileName = dtiRawFitTensorRobust([dwRaw=uigetfile], ...
%               [bvecsFile=uigetfile], [bvalsFile=uigetfile], ...
%               [outBaseDir=uigetdir], [brainMask=''], ...
%               [adcUnits=dtiGuessAdcUnits], [xformToAcPc=dwRaw.qto_xyz],
%               ... [nstep=50], [noiseCalcMethod = 'corner']);
%
% The tensors are returned in [Dxx Dyy Dzz Dxy Dxz Dyz] format and are
% saved in a dt6 file outBaseName 'dt6.mat'. This method works by first
% calculating the noise in the image and then rejecting fits that are worse
% than would be expected given the noise. There are 2 ways to calculate the
% noise. The first is based on the standard deviation of the signal in the
% corner of the image (noiseCalcMethod = 'corner'). This method works well
% as long as the corner of the image has not been padded with zeros.
% Currently GE zeros out the pixel intensity outside of the brain. So for
% new GE data we calculate the noise by taking the standard deviation of
% the b=0 images (noiseCalcMethod = 'b0') which means that we need a number
% of b0 acquisitions.
%
% Comments about the tensor formula and estimation are embedded in the
% code, below.
%
% If adcUnits is not provided, we try to guess based on the magnitude
% of the mean diffusivity. This guess is based on typical values for
% in-vivo human brain tissue. Our preferred units are 'micron^2/msec',
% because they produce very human-friendly numbers (eg. free diffusion of
% water is 3 micron^2/msec). Your adcUnits are determined by the units in
% which your bvals are specified. (adcUnits = 1/bvalUnits) For our GE
% Bammer/Hedehus DTI sequence, the native bvalUnits are sec/mm^2. However,
% we usually divide the bval by 1000, producing msec/micrometer^2 units.
%
% RESTORE: 
%     Robust tensor fitting and outlier rejection: Chang, Jones & Pierpaoli
%     (2005). RESTORE: Robust Estimation of Tensors by Outlier Rejection.
%     Magnetic Resonance in Medicine, v53.
% 
%     Note that the RESTORE implementation is experimental and needs more
%     testing. Also, don't do a bootstrap with RESTORE- that doesn't work
%     yet.
%
% EXAMPLE USAGE:
%      f    = 'raw/dti_g13_b800_aligned.'; 
%      out  = 'dti06rt'; 
%      mask ='dti06/bin/brainMask.nii.gz';
%      dtiRawFitTensor([f 'nii.gz'], [f 'bvecs'], [f 'bvals'], out, [], 'rt', mask);
% 
% Show outlier count as an overlay on the b0:
%      aNi = niftiRead(fullfile(out,'bin','b0.nii.gz'));
%      oNi = niftiRead(fullfile(out,'bin','outliers.nii.gz'));
%      aIm = mrAnatHistogramClip(double(aNi.data),0.4,0.98);
%      oIm = double(sum(oNi.data,4));
%      mrAnatOverlayMontage(oIm, oNi.qto_xyz, aIm, aNi.qto_xyz,...
%                           autumn(256), [1 10], [-34:2:62],[],3,1,false);
%
% WEB:
%      mrvBrowseSVN('dtiRawFitTensorRobust');
%
% 
% ** Code adapted from dtiRawFitTensor **
% 
% (C) Stanford VISTA Team  8/2011 [lmp]
% 


%% Check dwRaw input and set base names
% 
if(~exist('dwRaw','var') || isempty(dwRaw))
    [f,p] = uigetfile({'*.nii.gz;*.nii';'*.*'}, 'Select the raw DW NIFTI dataset...');
    if(isnumeric(f)), error('User cancelled.'); end
    dwRaw = fullfile(p,f);
end

% Load the raw data
if(ischar(dwRaw))
    disp(['Loading raw data ' dwRaw '...']);
    dwRaw = niftiRead(dwRaw);
    weLoadedRaw = true;
    [dataDir,inBaseName] = fileparts(dwRaw.fname);
else
    weLoadedRaw = false;
    [dataDir,inBaseName] = fileparts(dwRaw.fname);
end

% If clobber is passed in as 1 and the processing has been done previously
% overwrite the directory that contains the data. 
if(~exist('clobber','var')) || isempty('clobber')
    clobber = 0;
end

[tmp,inBaseName] = fileparts(inBaseName); %#ok<ASGLU>
if(isempty(dataDir)), dataDir = pwd; end

if(~exist('outBaseName','var') || isempty(outBaseName))
    if(nargout == 0)
        outBaseName = fullfile(dataDir,inBaseName);
    else
        outBaseName = [];
    end
end
if(isempty(outBaseName))
    outBaseName = uigetdir(inBaseName,'Select a directory for the data...');
    if (isnumeric(outBaseName)), disp('User canceled.'); return; end
end

% Set dt6.mat file name and bin directory name
dt6FileName = fullfile(outBaseName, 'dt6.mat');
binDirName  = fullfile(outBaseName, 'bin');

% If the directory exist prompt the user for overwrite
if(exist(outBaseName,'dir'))
    if( exist(dt6FileName,'file') ...
        || (exist(binDirName,'dir') ...
        && ~isempty(dir(fullfile(binDirName,'*.nii*'))))) ...
        && clobber ~= 1 ... 
        && clobber ~= -1
             q = ['Output dir ' outBaseName ...
                  ' exists and appears to contain data. Are you sure that you want to overwrite the data files in there?'];
            resp = questdlg(q,'Confirm Overwrite','Yes','Cancel','Cancel');
            
        if(strcmp(resp,'Cancel')), disp('canceled.'); return; end
    
    elseif( exist(dt6FileName,'file') ...
        || (exist(binDirName,'dir') ...
        && ~isempty(dir(fullfile(binDirName,'*.nii*'))))) ...
        && clobber ~= 1 ... 
        && clobber == -1
        disp('Tensor fitting already completed and "Clobber" is set to "false". Exiting tensor fit.'); 
        return 
    end
end

disp(['data will be saved to ' outBaseName '.']);


%% Check Inputs
% 
if(~exist('bvecs','var') || isempty(bvecs))
    bvecs = fullfile(dataDir,[inBaseName '.bvecs']);
    [f,p] = uigetfile({'*.bvecs';'*.*'},'Select the bvecs file...',bvecs);
    if(isnumeric(f)), disp('User canceled.'); return; end
    bvecs = fullfile(p,f);
end

if(~exist('bvals','var') || isempty(bvals))
    bvals = fullfile(dataDir,[inBaseName '.bvals']);
    [f,p] = uigetfile({'*.bvals';'*.*'},'Select the bvals file...',bvals);
    if(isnumeric(f)), disp('User canceled.'); return; end
    bvals = fullfile(p,f);
end

if(~exist('adcUnits','var'))
    adcUnits = '';
end

if(~exist('brainMask','var'))
    brainMask = '';
end

if(~exist('xformToAcPc','var') || isempty(xformToAcPc))
    xformToAcPc = dwRaw.qto_xyz;
end

if ~exist('noiseCalcMethod','var') || isempty(noiseCalcMethod)
    noiseCalcMethod = 'b0';
end

%% Load the bvecs & bvals
% 
% NOTE: these are assumed to be specified in image space. If bvecs are in
% scanner space, use dtiReorientBvecs and dtiRawReorientBvecs.
if(~isnumeric(bvecs))
    %bvecs = dlmread(bvecs, ' ');
    bvecs = dlmread(bvecs);
end
if(~isnumeric(bvals))
    %bvals = dlmread(bvals, ' ');
    bvals = dlmread(bvals);
end

% Set the number of volumes in the raw data
nvols = size(dwRaw.data,4);
if(size(bvecs,2)~=nvols || size(bvals,2)~=nvols)
    error(['bvecs/bvals: need one entry for each of the ' num2str(nvols) ' volumes.']);
end

minD = min(dwRaw.data(dwRaw.data(:)>0));
b0   = mean(double(dwRaw.data(:,:,:,bvals<=0.01)),4);


%% Compute a brain mask
% 
% Try to get one that was passed in
if(~isempty(brainMask))
    if(ischar(brainMask))
        % brainMask can be a path to the file or the nifti struct or an image
        disp(['Loading brainMask ' brainMask '...']);
        brainMask = niftiRead(brainMask);
    end
    if(isstruct(brainMask))
        brainMask = uint8(brainMask.data);
    end
    liberalBrainMask = brainMask;
else
    disp('Computing brain mask from average b0...');
    try
        % try using BET
        brainMask = uint8(mrAnatExtractBrain(int16(round(b0)), dwRaw.pixdim, 0.3));
        liberalBrainMask = brainMask;
    catch ME
        disp(ME);
        warning(wm,'Brain extraction using BET failed- using a simple threshold method.');
        b0clip = mrAnatHistogramClip(b0,0.4,0.98);
        
        % We use a liberal brain mask for deciding which tensors to compute, but a
        % more conservative mask will be saved so that that the junk outside the
        % brain won't be displayed when we view the data.
        liberalBrainMask = dtiCleanImageMask(b0clip>0.1&all(dwRaw.data>0,4),10,1,0.25,50);
        
        % Force the data to be physically plausible.
        dwRaw.data(dwRaw.data<=0) = minD;
        liberalBrainMask = uint8(liberalBrainMask);
        brainMask = uint8(dtiCleanImageMask(b0clip>0.2,7));
        
        % Make sure the display-purposes brain mask is a subset of the
        % tensor-fitting (liberal) brain mask.
        brainMask(~liberalBrainMask) = 0;
        clear b0clip;
    end
end

b0 = int16(round(b0));


%% Reorganize the data to make computations easier
%
numVols   = size(dwRaw.data,4);
brainInds = find(liberalBrainMask);
% preallocate a 2d array (with a 2nd dimension that is a singleton). The
% first dimension is the number of volumes and the 3rd is each voxel
% (within the brain mask).
data      = zeros(numVols,1,length(brainInds));

% Loop over the volumes and assign the voxels within the brain mask to data
for ii=1:numVols
    tmp = double(dwRaw.data(:,:,:,ii));
    data(ii,1,:) = tmp(brainInds);
end

%% Compute signal to noise estimate

% The default method is to calculate noise from the corner of the image.
% However GE scanners pad the corner of the image with zeros so we need to
% calculate noise from the variance of the b=0 images

sigma = dtiComputeImageNoise(dwRaw, bvals, liberalBrainMask, noiseCalcMethod);
if sigma==0
    error('Noise estimate (sigma) is exactly zero; maybe try a different noiseCalcMethod?');
end

% Memory usage is tight- if we loaded the raw data, clear it now since
% we've made the reorganized copy that we'll use for all subsequent ops.
if(weLoadedRaw), clear dwRaw; end; clear liberalBrainMask;

% Voxels with intensity exactly==0 sometimes occur by chance (usually in a
% artifact region, like a blood vessel) or as a result of eddy/motion
% correction and interpolation. They are a problem because fitting the
% tensor involves taking the log(intensity).
minVal        = min(data(data(:) > 0));
data(data==0) = minVal;


%% Tensor fitting comments
%
% For each measured direction, v = bvec*bval, at each voxel, there is a
% tensor, Q, such that v'Qv = data.  Data is the diffusion signal, 
%
%   data = S0 exp(-b v'Qv).  
%  
% Consequently,  
%
%    ln(data/S0) = (-b) * (v'Qv), or
%    ln(data)  = ln(S0) + (-b) * (v'Qv)  
%
% Call ln(data) = d. The measurement directions are the same at every
% voxel. Hence, we expand (v'Qv) into a quadratic equation for each voxel,
%
%    d = ln(S0) +  -b * (v1v1 q11 + v2v2 q22 + ... 2 v2 v3 q23 + ... )
%    d = ln(S0) +   V * q, 
%
% where V is a nDirections by 6 matrix and d are the data in all the
% directions. The solution, q, is the tensor (quadratic form) for that
% voxel.
%
%
% IMPLEMENTATION 
%   ALERT: This implementation uses the letter q where v might be
% clearer.  It uses data for both the signal and the ln of the signal.
%
% Start with q, which will have a row for each volume, each row having
% three elements: [bvx bvy bvz].
%
% Each row of X corresponds to a DW direction for that volume of the form:
% [1, -b bvx bvx, -b bvy bvy, -b bvz bvz, -2b bvx bvy, -2b bvx bvz, -2b bvy bvz].
%
% The first entry (1) accounts for the b=0 measurement, so that the data
% slot has the b=0 value in the first position.  This column could be
% removed if we divide all the data by the b=0 term first (I think, BW).
%
% The next six values in each row of X: [-bx^2 -by^2 -bz^2 -2bxy -2bxz
% -2byz] are the six unique values in the symmetric b-matrix. These are
% the same as equation 1 on p.457 of Basser et al, 2002, NMR in
% Biomedicine.
%
% Our goal is to use the raw data from each DWI (from dwRaw.data, stored in
% the matlab workspace currently as data) and its corresponding b-matrix
% (currently computed to be X in the matlab workspace) to estimate D using
% multivariate linear regression.


%% Fit the tensors using the RESTORE Algorithm

% 
nvox = size(data,3);
q    = (bvecs.*sqrt(repmat(bvals,3,1)))';
X    = [ones(numVols,1) -q(:,1).^2 -q(:,2).^2 -q(:,3).^2 -2.*q(:,1).*q(:,2)...
        -2.*q(:,1).*q(:,3) -2.*q(:,2).*q(:,3)];

% If the user does not pass in a number of steps we set it to default to
% 50 steps. Implemented in the loop @ ~li 340
if notDefined('nstep'), nstep = 50; end

fprintf('Fitting %d tensors with RESTORE [nstep=%s] (SLOW!)...\n',...
    nvox,num2str(nstep));

gof      = zeros(1, nvox, 'int16');
outliers = zeros(numVols, nvox, 'uint8');

% Goodness of fit criterion suggested p. 1089:
% If residuals of all data points lie within 3 S.D.s of signal,
% accept the results of nonlinear LS with constant weights computed
% above. If not, proceed with iterative weighting process

% First compute the linear inversion matrix X^-1. This is
% equivalent to the [-(1/b)] in the central DTI equation:
% D = -(1/b) * log(S1/S0) (cf, Cercignani 2001; Basser 2002)
% A = Xinv * log(data) : how we will represent it here
Xinv = pinv(X);

% To avoid log of zero warning:
nz = data > 0; logData = data; logData(nz) = log(data(nz));

% To avoid running out of memory.
clear nz;

% Multiply Xinv * logData for each "page" or 2D matrix in a stack
% (with numVoxels = number of "pages"). Each multiplication
% involves Xinv (7 x nVols) * logData (nVols x 1)
A = zeros(7,size(data,3));
for ii = 1:size(data,3) 
    A(:,ii) = Xinv * logData(:,:,ii); 
end
clear logData;

% Ainit = initial linear fit of seven diffusion parameters for each voxel
% (6 directions + b0) - code removed because of ndfun
% A = ndfun('mult', Xinv, logData); % Ainit = 7 x 1 x nVoxels

% Start timing...
tic;

% Options for fminsearch optimization
options    = optimset('Display', 'off', 'MaxIter', 100,...
                      'Algorithm','levenberg-marquardt');
sigmaSq    = sigma.^2;
voxPerStep = ceil(nvox/nstep);

% nstep sent in by user or set to 50 by default. 
for jj=1:nstep
    s = (jj-1)*voxPerStep+1;
    e = min(s+voxPerStep,nvox); 
        for ii=s:e 
            
            % Use a nonlinear search to compute the tensor fit to the data.
            % dtiRawTensorErr computes the difference between the tensor
            % and the data
            [x, resnorm] = lsqnonlin(@(x) dtiRawTensorErr(x, data(:,ii), ...
                X, sigmaSq, false), A(:,ii), [], [], options);
            
            residuals = data(:,ii)-exp(X*x);
            
            % If any residuals are more than 3 standard deviations from the
            % model prediction then redo the search downweigting that point
            if(any(abs(residuals)>=sigma*3))
                x = lsqnonlin(@(x) dtiRawTensorErr(x, data(:,ii), X, ...
                    sigmaSq, true), A(:,ii), [], [], options);
                
                residuals      = data(:,ii)-exp(X*x);
                o              = abs(residuals)>sigma*3;
                outliers(:,ii) = o;
                
                [x, resnorm] = lsqnonlin(@(x) dtiRawTensorErr(x,...
                    data(~o,ii), X(~o,:), 1, false), A(:,ii), [], [], ...
                    options);
            end
            A(:,ii) = x;
            gof(ii) = int16(round(resnorm));
        end
    o       = sum(outliers(:,s:e),1);
    nOutVox = sum(o>0);
    maxOut  = max(o);
    
    fprintf('   Step %d of %d: RESTORE found %d (%0.1f%%) voxels with up to %d outliers.\n',...
        jj,nstep,nOutVox,nOutVox/(e-s+1)*100,maxOut);
end

fprintf('   Elapsed time: %f minutes.\n',toc/60);

% Temporarily save data
tn = tempname; disp(['saving temp data to ' tn '...']); save(tn);

% Computing the mean b0 (in log space) is exactly equivalent to pulling the
% b0 from the model fit (A(1,:,:)). We use the log-mean b0 that we already
% computed since it saves us a little computation (one less exp) and it has
% no background voxels masked away.
tmp = zeros(size(brainMask));
dt6 = zeros([size(brainMask),6]);

for ii=1:6 
    tmp(brainInds) = squeeze(A(ii+1,:,:));
    dt6(:,:,:,ii)  = tmp;
end


%% Check ADC units and adjust if necessary
%
if(isempty(adcUnits))
    % Always convert to our standard ADC units (micrometer^2/msec)
    [curUnitStr,scale,adcUnits] = dtiGuessDiffusivityUnits(dt6);
    if(scale~=1)
        fprintf('Converting %s to %s with scale = %f.\n',curUnitStr,adcUnits,scale);
        dt6 = dt6.*scale;
    end
end

%% Compute a rough white-matter mask
%
[fa,md] = dtiComputeFA(dt6);
wmMask  = brainMask & fa>.15 & (md<1.1 | fa>0.4);
wmMask  = dtiCleanImageMask(wmMask,0,0);


%% Save all results and write out the nifti files
%
if(~exist(outBaseName,'dir'))
    mkdir(outBaseName);
end
if(~exist(binDirName,'dir'))
    mkdir(binDirName);
end

params.nBootSamps = 0;
params.buildDate  = datestr(now,'yyyy-mm-dd HH:MM');
l                 = license('inuse');
params.buildId    = sprintf('%s on Matlab R%s (%s)',l(1).user,version('-release'),computer);
params.rawDataDir = dataDir;

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
[ppBinDir, pBinDir]     = fileparts(fullParentDir);
pBinDir                 = fullfile(pBinDir,binDir);
files.b0                = fullfile(pBinDir,'b0.nii.gz');
files.brainMask         = fullfile(pBinDir,'brainMask.nii.gz');
files.wmMask            = fullfile(pBinDir,'wmMask.nii.gz');
files.tensors           = fullfile(pBinDir,'tensors.nii.gz');

% description can have up to 80 chars
desc = [params.buildDate ' ' params.buildId];
if(length(desc)>80), disp('NOTE: description field clipped to 80 chars.'); end

% Write out the nifti files
dtiWriteNiftiWrapper(int16(round(b0)), xformToAcPc, ...
                    fullfile(ppBinDir,files.b0), 1, desc, 'b0');
dtiWriteNiftiWrapper(uint8(brainMask), xformToAcPc, ... 
                    fullfile(ppBinDir,files.brainMask), 1, desc, 'brainMask');
dtiWriteNiftiWrapper(uint8(wmMask), xformToAcPc, ...
                    fullfile(ppBinDir,files.wmMask), 1, desc, 'whiteMatterMask');

% Goodness of fit and outliers [NIFTI creation]
if(~isempty(gof))
    tmp            = zeros(size(brainMask),'int16');
    tmp(brainInds) = gof;
    gof            = tmp;
    tmpVol         = zeros([size(brainMask),numVols],'uint8');
    tmp            = zeros(size(brainMask),'uint8');
    
    for ii=1:numVols 
        tmp(brainInds) = outliers(ii,:);
        tmpVol(:,:,:,ii) = tmp;
    end
    
    outliers       = tmpVol;
    files.gof      = fullfile(pBinDir,'gof.nii.gz');
    files.outliers = fullfile(pBinDir,'outliers.nii.gz');
    
    dtiWriteNiftiWrapper(gof, xformToAcPc, fullfile(ppBinDir,files.gof), 1, desc, 'GOF');
    dtiWriteNiftiWrapper(outliers, xformToAcPc, fullfile(ppBinDir,files.outliers), 1, desc, 'outlier mask');
    
    % Create summary image of outliers.nii.gz that can be viewed as an
    % image when loaded into DTIfiberUI.
    outlierImage       = niftiRead(fullfile(ppBinDir,files.outliers));
    outlierImage.data  = sum(outlierImage.data,4);
    outlierImage.fname = fullfile(ppBinDir,pBinDir,'outlier_sum_image.nii.gz');
    writeFileNifti(outlierImage);
end

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
sz  = size(dt6);
dt6 = reshape(dt6,[sz(1:3),1,sz(4)]);

dtiWriteNiftiWrapper(dt6, xformToAcPc, fullfile(ppBinDir,files.tensors),...
                     1, desc, ['DTI ' adcUnits]);

save(dt6FileName,'adcUnits','params','files');
disp('Finished writing dt6 file!');

if(nargout<1), clear dt6; end

return;


