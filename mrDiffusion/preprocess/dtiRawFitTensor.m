function dt6FileName = dtiRawFitTensor(dwRaw, bvecs, bvals, outBaseName, bs, fitMethod, brainMask, adcUnits, xformToAcPc)
% Fits a tensor to the raw DW data.
%
% dt6FileName = dtiRawFitTensor([dwRaw=uigetfile],
% [bvecsFile=uigetfile], [bvalsFile=uigetfile], [outBaseDir=uigetdir],
% [bootstrapParams=[]], [fitMethod='ls'], [brainMask=''],
% [adcUnits=dtiGuessDiffusivityUnits], [xformToAcPc=dwRaw.qto_xyz])
%
% The tensors are returned in [Dxx Dyy Dzz Dxy Dxz Dyz] format and are
% saved in a dt6 file outBaseName 'dt6.mat'.
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
% You can also specify a bootstrap to estimate tensor fit uncertainty.
% To skip the bootstrap, make bootstrapParams empty (or specify n=1
% bootstrap samples). bootstrapParams is a struct  with the following
% fields:
%
%   n: number of bootstrap samples. [] or 1 will trigger no bootstrap.
%      We've found that 200-300 gives a good variance estimate, but 500 is
%      probably better.
%
%   nVolsPerRepeat: each bootstrap sample is a permuted dataset. In order
%      to permute the original data in a reasonable way (ie. preserving the
%      # of unique directions and the # of non-DWIs), we need to know the
%      repetion pattern in the input data. For now, we assume that the data
%      are arranged such that the measurements for each repeat are
%      contiguous and that the order of the direction measurements is the
%      same across all the repeats. In that case, one number can specify
%      the approriate pattern for generating the bootstrap permutations.
%      nVolsPerRepeat specifies the number of image volumes to expect per
%      repeat. E.g., if you make 13 measurements per repeat (12 DWIs + 1
%      non DWI), nVolsPerRepeat = 13. Note that the code below will try to
%      deal gracefully with incomplete data for the last repeat.
%
% ===OR===
%
%   permuteMatrix: a cell-array with one entry for each measurement (ie.
%   N = length(permuteMatrix) = size(dwRaw,4). Each entry of this cell
%   array is a 1-d array of indices into the N dwRaw volumes that are
%   valid bootstrap samples of the corresponding volume. E.g:
%      bv = [dlmread(bvecsFile).*repmat(dlmread(bvalsFile),[3 1])];
%      bs.permuteMatrix = {};
%      for(ii=1:size(bv,2))
%         dist1 = sqrt((bv(1,:)-bv(1,ii)).^2+(bv(2,:)-bv(2,ii)).^2+(bv(3,:)-bv(3,ii)).^2);
%         dist2 = sqrt((bv(1,:)+bv(1,ii)).^2+(bv(2,:)+bv(2,ii)).^2+(bv(3,:)+bv(3,ii)).^2);
%         bs.permuteMatrix{ii} = unique([find(dist1<1e-3) find(dist2<1e-3)]);
%      end
%
%   maxMem: The bootstrap tensor fits can go much faster is we do them in
%      large chunks, but not so large that we cause Matlab to use swap
%      space or run out of memory altogether. So set maxMem (specified in
%      either bytes or Gigabytes) to about 80% of the physical RAM that you
%      have available. (defaults to 1GB)
%
%   showProgress: if true, a progress bar will be shown. (defaults to true)
%
% Currently, specifying the bootstrap cases the resulting dt6 file to have
% the following additional variables:
%
%   faStd, mdStd: standard deviations on fa and mean diffusivity.
%
%   pddDisp: dispersion of PDD axes (based on the Watson) in degrees of
%   angle (54 deg is maximum dispersion).
%
%
% fitMethod: the tensor fitting method.
%   'ls': least-squares (default)
%   'me': maximum-entropy method (Dima Kuzmin and Manfred Warmuth, UCSC)
%   'rt': RESTORE robust tensor fitting and outlier rejection:
%         Chang, Jones & Pierpaoli (2005). RESTORE: Robust Estimation of
%         Tensors by Outlier Rejection. Magnetic Resonance in Medicine, v53.
%
% Note that the RESTORE implementation is experimental and needs more
% testing. Also, don't do a bootstrap with RESTORE- that doesn't work yet.
%
% Examples:
%  f = 'raw/dti_g13_b800_aligned.'; out = 'dti06rt'; 
%  mask ='dti06/bin/brainMask.nii.gz';
%  dtiRawFitTensor([f 'nii.gz'], [f 'bvecs'], [f 'bvals'], out, [], 'rt', mask);
% 
% % Show outlier count as an overlay on the b0:
%  aNi = niftiRead(fullfile(out,'bin','b0.nii.gz'));
%  oNi = niftiRead(fullfile(out,'bin','outliers.nii.gz'));
%  aIm = mrAnatHistogramClip(double(aNi.data),0.4,0.98);
%  oIm = double(sum(oNi.data,4));
%  mrAnatOverlayMontage(oIm, oNi.qto_xyz, aIm, aNi.qto_xyz, autumn(256), [1 10], [-34:2:62],[],3,1,false);
% 
% 
% (c) Stanford VISTA Team


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
% 2007.03.20 RFD: wrote it.
% 2007.05.30 RFD: added bootstrap option
% 2007.06.02 RFD: cleaned and documented bootstrap code. Seems to work well
% now.
% 2007.06.08 RFD: now save in the new all-NIFTI format. THe dt6 file is now
% just a 'project' file with some notes and the filenames of the actual
% data files.
% 2007.06.14 RFD: NIFTI tensor files weren't respecting the NIFTI-1 spec.
% This is now fixed and the tensor elements are stored in lower-triangular,
% row-wise order (Dxx Dxy Dyy Dxz Dyz Dzz).
% 2007.07.20 AJS: Relative fileanames to the parent directory.
% 2008.09.03 DY & RFD: Implemented 'rt' fitMethod (RESTORE)
% 2008.12.16 DY: Forced useParfor (parallel processing flag) to be false, 
% as it seems not to be functional (on Bob's recommendation) 
% 2008.12.18 DY & AL: Create summary image of outliers.nii.gz that can be
% viewed as an image when loaded into DTIfiberUI.
% 2011.8.20  BW - Comments.
%

if(~exist('dwRaw','var')||isempty(dwRaw))
    [f,p] = uigetfile({'*.nii.gz;*.nii';'*.*'}, 'Select the raw DW NIFTI dataset...');
    if(isnumeric(f)), error('User cancelled.'); end
    dwRaw = fullfile(p,f);
end
if(ischar(dwRaw))
    % dwRaw can be a path to the file or the file itself
    [dataDir,inBaseName] = fileparts(dwRaw);
else
    [dataDir,inBaseName] = fileparts(dwRaw.fname);
end
[junk,inBaseName] = fileparts(inBaseName);
if(isempty(dataDir)), dataDir = pwd; end

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
if(~exist('brainMask','var'))
    brainMask = '';
end

if(isempty(outBaseName))
    outBaseName = uigetdir(inBaseName,'Select a directory for the data...');
    if(isnumeric(outBaseName)), disp('User canceled.'); return; end
end
dt6FileName = fullfile(outBaseName, 'dt6.mat');
binDirName = fullfile(outBaseName, 'bin');
if(exist(outBaseName,'dir'))
    if(exist(dt6FileName,'file')||(exist(binDirName,'dir')&&~isempty(dir(fullfile(binDirName,'*.nii*')))))
        q = ['Output dir ' outBaseName ' exists and appears to contain data. Are you sure that you want to overwrite the data files in there?'];
        resp = questdlg(q,'Confirm Overwrite','Yes','Cancel','Cancel');
        if(strcmp(resp,'Cancel')), disp('canceled.'); return; end
        %error(['Output dir ' outBaseName ' exists and appears to contain data- please move it out of the way.']);
        %outBaseName = uigetdir('Select directory for output...',dt6FileName);
        %if(isnumeric(f)), disp('User canceled.'); return; end
        %dt6FileName = fullfile(p,f);
        %[p,f] = fileparts(dt6FileName);
        %binDirName = fullfile(p,f);
    end
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
if(~exist('xformToAcPc','var')||isempty(xformToAcPc))
    xformToAcPc = dwRaw.qto_xyz;
end

if(~exist('bs','var')||isempty(bs))
    bs = 0;
end
if(~isstruct(bs))
    tmp = bs;
    clear bs;
    bs.n = tmp;
    bs.nVolsPerRepeat = 1;
    % 1 GByte = 2^30
    bs.maxMem = 4*2^30;
    bs.showProgress = false;
else
    if(~isfield(bs,'maxMem')), bs.maxMem = 1*2^30;
    elseif(bs.maxMem<100), bs.maxMem = bs.maxMem*2^30; end
    if(~isfield(bs,'showProgress')), bs.showProgress = true; end
end

if(~exist('fitMethod','var') || isempty(fitMethod)), fitMethod = 'ls'; end

useParfor = false;
if(fitMethod(1)=='p')
    if(license('checkout','distrib_computing_toolbox'))
        useParfor = true;
    else
        disp('Not using distributed toolbox- no license available.');
    end
    fitMethod = fitMethod(2:end);
end


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

minD = min(dwRaw.data(dwRaw.data(:)>0));

b0 = mean(double(dwRaw.data(:,:,:,bvals<=0.01)),4);

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
    catch
        warning('Brain extraction using BET failed- using a simple threshold method.');
        b0clip = mrAnatHistogramClip(b0,0.4,0.98);
        % We use a liberal brain mask for deciding which tensors to compute, but a
        % more conservative mask will be saved so that that the junk outside the
        % brain won't be displayed when we view the data.
        liberalBrainMask = dtiCleanImageMask(b0clip>0.1&all(dwRaw.data>0,4),10,1,0.25,50);
        % force the data to be physically plausible.
        dwRaw.data(dwRaw.data<=0) = minD;
        liberalBrainMask = uint8(liberalBrainMask);
        brainMask = uint8(dtiCleanImageMask(b0clip>0.2,7));
        % make sure the display-purposes brain mask is a subset of the
        % tensor-fitting (liberal) brain mask.
        brainMask(~liberalBrainMask) = 0;
        clear b0clip;
    end
end

b0 = int16(round(b0));

%% Reorganize the data to make computations easier
%
numVols = size(dwRaw.data,4);
brainInds = find(liberalBrainMask);
data = zeros(numVols,1,length(brainInds));
for(ii=1:numVols)
    tmp = double(dwRaw.data(:,:,:,ii));
    data(ii,1,:) = tmp(brainInds);
end

%% Compute signal noise estimate
%
% According to Henkelman (1985), the expected signal variance (sigma) can be computed as
% 1.5267 * SD of the background (thermal) noise.
sz = size(dwRaw.data);
x = 10;
y = 10;
z = round(sz(3)/2);
[x,y,z,s] = ndgrid(x-5:x+5,y-5:y:5,z-5:z+5,1:sz(4));
noiseInds = sub2ind(sz,x(:),y(:),z(:),s(:));
sigma = 1.5267 * std(double(dwRaw.data(noiseInds)));

% Memory usage is tight- if we loaded the raw data, clear it now since
% we've made the reorganized copy that we'll use for all subsequent ops.
if(weLoadedRaw), clear dwRaw; end
clear liberalBrainMask;
% Voxels with intensity exactly==0 sometimes occur by chance (usually in a
% artifact region, like a blood vessel) or as a result of eddy/motion
% correction and interpolation. They are a problem because fitting the
% tensor involves taking the log(intensity).
minVal = min(data(data(:)>0));
data(data==0) = minVal;

%% Fit the tensor maps.
%
nvox = size(data,3);
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

q = (bvecs.*sqrt(repmat(bvals,3,1)))';
X = [ones(numVols,1) -q(:,1).^2 -q(:,2).^2 -q(:,3).^2 -2.*q(:,1).*q(:,2) -2.*q(:,1).*q(:,3) -2.*q(:,2).*q(:,3)];
gof = [];
outliers = [];
switch fitMethod
    case 'me'   % Maximum entropy
        fprintf('Fitting tensor to %d voxels with maximum entropy- SLOW...\n',nvox);
        nz = data>0;
        data(nz) = log(data(nz));
        clear nz;
        A = zeros(7,nvox);
        tic;
        for(ii=1:nvox)
            A(2:7,ii) = dtiMEGFitTensor(X,data(:,:,ii));
        end
        fprintf('   Elapsed time: %f minutes.\n',toc/60);

    case 'ls'  % Least squares
        Xinv = pinv(X);
        % The dt values are simply log(data)*Xinv
        % Avoid log of zero warning:
        nz = data>0;
        data(nz) = log(data(nz));
        clear nz;
        % NOTE: could use MTIMESX to speed this up
        % http://www.mathworks.se/matlabcentral/fileexchange/25977-mtimesx-fast-matrix-multiply-with-multi-dimensional-support
        A = zeros(7,size(data,3));
        for(ii=1:size(data,3)), A(:,ii) = Xinv*data(:,:,ii); end
        %A = ndfun('mult', Xinv, data);

    case 'rt' % RESTORE robust tensor fitting: Chang et al, 2005, MRM
        fprintf('Fitting %d tensors with RESTORE (EXPERIMENTAL AND SLOW!)...\n',nvox);
        gof = zeros(1,nvox,'int16');
        outliers = zeros(numVols,nvox,'uint8');
        % Goodness of fit criterion suggested p. 1089:
        % If residuals of all data points lie within 3 S.D.s of signal,
        % accept the results of nonlinear LS with constant weights computed
        % above. If not, proceed with iterative weighting process
        %
        % First compute the linear inversion matrix X^-1. This is
        % equivalent to the [-(1/b)] in the central DTI equation:
        % D = -(1/b) * log(S1/S0) (cf, Cercignani 2001; Basser 2002)
        % A = Xinv * log(data) : how we will represent it here
        Xinv = pinv(X);
        % To avoid log of zero warning:
        nz = data>0; logData = data; logData(nz) = log(data(nz));
        clear nz; % To avoid running out of memory.
        % Multiply Xinv * logData for each "page" or 2D matrix in a stack
        % (with numVoxels = number of "pages"). Each multiplication
        % involves Xinv (7 x nVols) * logData (nVols x 1)
        A = zeros(7,size(data,3));
        for(ii=1:size(data,3)), A(:,ii) = Xinv*logData(:,:,ii); end
        %A = ndfun('mult', Xinv, logData); % Ainit = 7 x 1 x nVoxels
        % Ainit = initial linear fit of seven
        % diffusion parameters for each voxel (6 directions + b0)
        clear logData;
        %options = optimset('LargeScale','on','LevenbergMarquardt','on', 'Display', 'off', 'MaxIter', 50);
        options = optimset('Display', 'off', 'MaxIter', 100);
        sigmaSq = sigma.^2;
        if(useParfor), matlabpool; end
        tic;
        nstep = 50;
        voxPerStep = ceil(nvox/nstep);
        for(jj=1:nstep)
            s = (jj-1)*voxPerStep+1;
            e = min(s+voxPerStep,nvox);
            if(useParfor)
                parfor(ii=s:e)
                    d = data(:,ii);
                    % Nonlinear least-squares procedure:
                    [x, resnorm] = fminsearch(@(x) dtiRawTensorErr(x, d, X, sigmaSq, false), A(:,ii), options);
                    residuals = data(:,ii)-exp(X*x);
                    % If residuals of all data points lie within the given
                    % confidence interval, we assume there are no
                    % outliers and keep the least-squares result.
                    if(any(residuals>=sigma*3))
                        % There are outliers- do the GMM weighted least-squares.
                        x = fminsearch(@(x) dtiRawTensorErr(x, d, X, sigmaSq, true), A(:,ii), options);
                        % Now, reject outliers and re-fit.
                        % Remove points lying outside a confidence
                        % interval (e.g., 3 S.D.s of expected signal).
                        % Weight the remaining data equally and
                        % recompute diffusion tensor using the
                        % nonlinear LS method.
                        residuals = d-exp(X*x);
                        o = residuals'>sigma*3;
                        outliers(:,ii) = o;
                        [x, resnorm] = fminsearch(@(x) dtiRawTensorErr(x, d(~o), X(~o,:), sigmaSq, false), A(:,ii), options);
                    end
                    A(:,ii) = x;
                    gof(ii) = int16(round(resnorm));
                end
            else   % No parallel toolbox
                for(ii=s:e)
                    [x, resnorm] = fminsearch(@(x) dtiRawTensorErr(x, data(:,ii), X, sigmaSq, false), A(:,ii), options);
                    residuals = data(:,ii)-exp(X*x);
                    if(any(residuals>=sigma*3))
                        x = fminsearch(@(x) dtiRawTensorErr(x, data(:,ii), X, sigmaSq, true), A(:,ii), options);
                        residuals = data(:,ii)-exp(X*x);
                        o = residuals>sigma*3;
                        outliers(:,ii) = o;
                        [x, resnorm] = fminsearch(@(x) dtiRawTensorErr(x, data(~o,ii), X(~o,:), sigmaSq, false), A(:,ii), options);
                    end
                    A(:,ii) = x;
                    gof(ii) = int16(round(resnorm));
                end
            end
            o = sum(outliers(:,s:e),1);
            nOutVox = sum(o>0);
            maxOut = max(o);
            fprintf('   Step %d of %d: RESTORE found %d (%0.1f%%) voxels with up to %d outliers.\n',jj,nstep,nOutVox,nOutVox/(e-s+1)*100,maxOut);
        end
        if(useParfor), matlabpool close; end
        fprintf('   Elapsed time: %f minutes.\n',toc/60);
    otherwise,
        error('unknown tensor fitting method "%s".',fitMethod);
end
        
if(strcmp(fitMethod,'ls')==1 && bs.n>1)
    % the data use nvox*numVols doubles and each output uses nvox
    maxMemForStrides = bs.maxMem-(nvox*numVols+4*nvox)*8;
    % Xinv uses 7*numVols*bs.n doubles (8 bytes/dbl)
    % tmp uses 1*numVols*bs.n (=8*numVols*bs.n)
    % the resulting tensor fits use another 7*bs.n
    % We also allow for ~ 25% overhead per stride.
    stride = floor(maxMemForStrides./((8*numVols*bs.n+7*bs.n)*8*1.25));
    tic;
    fprintf('Running %d bootstrap samples on %d voxels (i.e. fitting %0.1f million tensors)- this may take a while!\n',bs.n,nvox,bs.n*nvox/1e6);
    % For the bootstrap, we set up a 3d Xinv matrix and then for each
    % voxel, solve for all the bootstrap tensor-fits at once using ndfun.
    if(isfield(bs,'permuteMatrix'))
        sampInds = zeros(numVols,bs.n);
        for(ii=1:numVols)
            sampInds(ii,:) = bs.permuteMatrix{ii}(ceil(length(bs.permuteMatrix{ii}).*rand(1,bs.n)));
        end
    else
        % FIXME: allow for partial datasets, where numVols<nVolsPerRepeat*nRepeats.
        nRepeats = ceil(numVols/bs.nVolsPerRepeat);
        % The following will sample (with replacement) such that each repeat is
        % a coherent whole (ie. a full set of directions/bvals). You can check
        % this with mod(sampInds,nVolsPerRepeat).
        sampInds = repmat((1:bs.nVolsPerRepeat)',nRepeats,bs.n)+floor(nRepeats.*rand(bs.nVolsPerRepeat*nRepeats,bs.n))*bs.nVolsPerRepeat;
    end
    bsBvecs = bvecs(:,sampInds(:));
    bsBvals = bvals(sampInds(:));
    q = (bsBvecs.*sqrt(repmat(bsBvals,3,1)))';
    sz = size(q);
    X = [ones(sz(1),1) -q(:,1).^2 -q(:,2).^2 -q(:,3).^2 -2*q(:,1).*q(:,2) -2*q(:,1).*q(:,3) -2*q(:,2).*q(:,3)];
    clear q bsBvals bsBvecs;
    X = permute(reshape(X',[7,numVols,bs.n]),[2 1 3]);
    %Xinv = ndfun('inv',X);
    fprintf('   Inverting %d X matrices...\n',bs.n);
    for(ii=1:size(X,3))
        Xinv(:,:,ii) = pinv(X(:,:,ii));
    end
    clear X;
    % To speed up the following loop, we do several (='stride') voxels per
    % iteration. If we had enough RAM, we could do them all in one go
    % to keep the voxel-loop in the c-code. But, the following
    % more pratical solution is a good compromise for a reasonably fast
    % solution (e.g., under 20 minutes for 500 bootstrap samples on ~200K
    % voxels.) Unfortunately, this optimization makes the following code
    % hard to read...
    Xinv = repmat(Xinv,[1,1,stride]);
    faStd = zeros(1,nvox);
    mdStd = zeros(1,nvox);
    pddDisp = zeros(1,nvox);
    fprintf('   Multiplying log(DWI) by Xinv (%d voxel stride)...\n',stride);
    for(ii=1:stride:nvox)
        sInd = ii; eInd = min(ii+stride-1,nvox);
        n = eInd-sInd+1;
        tmp = reshape(data(sampInds(:),1,sInd:eInd),[numVols,1,bs.n*n]);
        t = zeros(7,size(tmp,3));
        for(ii=1:size(data,3)), A(:,ii) = Xinv(:,:,1:size(tmp,2))*tmp(:,:,ii); end
        %t = ndfun('mult', Xinv(:,:,1:size(tmp,2)), tmp);
        t = squeeze(t(2:7,:,:));
        t = reshape(t,6,bs.n,n);
        % We now have bs.n tensors- use them to estimate tensor fit
        % variances like FA, MD and PDD variance.
        %
        % dtiEig likes the 6 tensor vals to be in the 2nd (or 4th) dim.
        % we'll permute so that the n voxels for this stride are in the
        % first dim and the bs.n are in the 3rd dim.
        %
        % *** WORK HERE- insert better PDD dispersion fitting here (e.g.
        % Bingham distribution)
        [vec,val] = dtiEig(permute(t,[3 1 2]));
        % Convert vec to an Mx3xN array of PDD vectors where N is the
        % bootstrap dim- the dim along which we'll collapse to compute
        % dispersions.
        vec = permute(vec(:,:,1,:),[1 2 4 3]);
        %badVals = any(val<0,2);
        [fa,md] = dtiComputeFA(val);
        faStd(sInd:eInd) = std(fa,0,2);
        %         keyboard;
        %         tic
        %         for(jj=1:size(fa,1))
        %             [pdfY,pdfX] = ksdensity(fa(jj,:),'function','cdf');
        %             xi = interp1(pdfY+rand(size(pdfY))*1e-9,pdfX,[0.025 0.975]);
        %             faLb(sInd+jj-1) = xi(1); faUb(sInd+jj-1) = xi(2);
        %         end
        %         toc
        mdStd(sInd:eInd) = std(md,0,2);
        clear t val;
        [junk,pddDisp(sInd:eInd)] = dtiDirMean(vec);
    end
    clear Xinv tmp vec;
    % Convert dispersion to angle in degrees
    % We get a few values just below zero in edge voxels, so we clip.
    pddDisp(pddDisp<0) = 0;
    pddDisp = asin(sqrt(pddDisp))./pi.*180;
    fprintf('   Elapsed time: %f minutes.\n',toc/60);
    tmp = zeros(size(brainMask));
    tmp(brainInds) = faStd; faStd = tmp;
    tmp(brainInds) = mdStd; mdStd = tmp;
    tmp(brainInds) = pddDisp; pddDisp = tmp;
else
    faStd = [];
    mdStd = [];
    pddDisp = [];
end

tn = tempname;
disp(['saving temp data to ' tn '...']);
save(tn);

% Computing the mean b0 (in log space) is exactly equivalent to pulling the
% b0 from the model fit (A(1,:,:)). We use the log-mean b0 that we already
% computed since it saves us a little computation (one less exp) and it has
% no background voxels masked away.
%b0 = zeros(size(brainMask));
%b0(brainInds) = exp(squeeze(A(1,:,:)));
tmp = zeros(size(brainMask));
dt6 = zeros([size(brainMask),6]);
for(ii=1:6)
    tmp(brainInds) = squeeze(A(ii+1,:,:));
    dt6(:,:,:,ii) = tmp;
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
wmMask = brainMask & fa>.15 & (md<1.1 | fa>0.4);
wmMask = dtiCleanImageMask(wmMask,0,0);

%% Save all results
%
if(~exist(outBaseName,'dir'))
    mkdir(outBaseName);
end
if(~exist(binDirName,'dir'))
    mkdir(binDirName);
end
params.nBootSamps = bs.n;
params.buildDate = datestr(now,'yyyy-mm-dd HH:MM');
l = license('inuse');
params.buildId = sprintf('%s on Matlab R%s (%s)',l(1).user,version('-release'),computer);
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
[ppBinDir, pBinDir] = fileparts(fullParentDir);
pBinDir = fullfile(pBinDir,binDir);
files.b0 = fullfile(pBinDir,'b0.nii.gz');
files.brainMask = fullfile(pBinDir,'brainMask.nii.gz');
files.wmMask = fullfile(pBinDir,'wmMask.nii.gz');
files.tensors = fullfile(pBinDir,'tensors.nii.gz');
% description can have up to 80 chars
desc = [params.buildDate ' ' params.buildId];
if(length(desc)>80), disp('NOTE: description field clipped to 80 chars.'); end
dtiWriteNiftiWrapper(int16(round(b0)), xformToAcPc, fullfile(ppBinDir,files.b0), 1, desc, 'b0');
dtiWriteNiftiWrapper(uint8(brainMask), xformToAcPc, fullfile(ppBinDir,files.brainMask), 1, desc, 'brainMask');
dtiWriteNiftiWrapper(uint8(wmMask), xformToAcPc, fullfile(ppBinDir,files.wmMask), 1, desc, 'whiteMatterMask');
if(~isempty(gof))
    tmp = zeros(size(brainMask),'int16');
    tmp(brainInds) = gof;
    gof = tmp;
    tmpVol = zeros([size(brainMask),numVols],'uint8');
    tmp = zeros(size(brainMask),'uint8');
    for(ii=1:numVols)
        tmp(brainInds) = outliers(ii,:);
        tmpVol(:,:,:,ii) = tmp;
    end
    outliers = tmpVol;
    files.gof = fullfile(pBinDir,'gof.nii.gz');
    files.outliers = fullfile(pBinDir,'outliers.nii.gz');
    dtiWriteNiftiWrapper(gof, xformToAcPc, fullfile(ppBinDir,files.gof), 1, desc, 'GOF');
    dtiWriteNiftiWrapper(outliers, xformToAcPc, fullfile(ppBinDir,files.outliers), 1, desc, 'outlier mask');
    %Create summary image of outliers.nii.gz that can be viewed as an image
    % when loaded into DTIfiberUI.
    outlierImage=niftiRead(fullfile(ppBinDir,files.outliers));
    outlierImage.data=sum(outlierImage.data,4);
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
sz = size(dt6);
dt6 = reshape(dt6,[sz(1:3),1,sz(4)]);
dtiWriteNiftiWrapper(dt6, xformToAcPc, fullfile(ppBinDir,files.tensors), 1, desc, ['DTI ' adcUnits]);
if(~isempty(faStd))
    files.faStd = fullfile(pBinDir,'faStd.nii.gz');
    files.mdStd = fullfile(pBinDir,'mdStd.nii.gz');
    files.pddDisp = fullfile(pBinDir,'pddDispersion.nii.gz');
    dtiWriteNiftiWrapper(single(faStd), xformToAcPc, fullfile(ppBinDir,files.faStd), 1, desc, 'FA stdev');
    dtiWriteNiftiWrapper(single(mdStd), xformToAcPc, fullfile(ppBinDir,files.mdStd), 1, desc, 'MD stdev');
    dtiWriteNiftiWrapper(pddDisp, xformToAcPc, fullfile(ppBinDir,files.pddDisp), 1, desc, 'PDD disp (deg)');
end
save(dt6FileName,'adcUnits','params','files');
disp('Finished writing dt6 file--line634 of dtiRawFitTensor');
if(nargout<1), clear dt6; end

return;
% ------================================================

% To run this on a bunch of subjects
bd = '/biac3/wandell4/data/reading_longitude/dti_y1234';
rf = 'dti_g13_b800_aligned_trilin.'; 
of = 'dti06trilinrt';
d = dir(fullfile(bd,'*0*'));
%fp = fopen('/tmp/run.sh','w');
for(ii=1:numel(d))
    sd = fullfile(bd,d(ii).name);
    dwRaw = fullfile(sd,'raw',[rf 'nii.gz']);
    dwBvc = fullfile(sd,'raw',[rf 'bvecs']);
    dwBvl = fullfile(sd,'raw',[rf 'bvals']);
    out = fullfile(sd,of);
    if(exist(sd,'dir') && exist(dwRaw,'file') && exist(dwBvc,'file') && exist(dwBvl,'file') && ~exist(out,'dir'))
        fprintf('Processing %s (%d of %d)...\n',sd,ii,numel(d));
        dtiRawFitTensor(dwRaw, dwBvc, dwBvl, out, [], 'rt');
        %cmd = sprintf('matlabr2008a -nodisplay -nojvm -r "dtiRawFitTensor %s %s %s %s 0 rt ; exit;"',dwRaw, dwBvc, dwBvl, out);
        %if(mod(ii,10)==0), fprintf(fp,'%s\n', cmd); else, fprintf(fp,'%s &\n', cmd); end
        %[s w] = system(cmd);
%       if(s==0)
%            disp('Succesfully spawned matlab process.');
%        else
%            disp(['Spawn Failed: ' w]);
%        end

    end
end
%fclose(fp);


bd = '/biac3/wandell4/data/reading_longitude/dti_y1234';
of1 = 'dti06trilin';
of2 = 'dti06trilinrt';
d = dir(fullfile(bd,'*0*'));
f = {'faStd.nii.gz','mdStd.nii.gz','pddDispersion.nii.gz','wmProb.nii.gz','vectorRGB.nii.gz'};
for(ii=1:numel(d))
    sd = fullfile(bd,d(ii).name);
    src = fullfile(sd,of1,'bin');
    dst = fullfile(sd,of2,'bin');
    if(exist(src,'dir') && exist(dst,'dir'))
        for(jj=1:numel(f))
            cmd = sprintf('mv %s %s',fullfile(src,f{jj}),dst);
            unix(cmd);
        end
    end
end


