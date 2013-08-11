function dw = dtiRawComputeAdc(dwRawFile, bvecsFile, bvalsFile, outBaseName)
%
% dw = dtiRawComputeAdc(dwRawFile, bvecsFile, bvalsFile, outBaseName)
%
% Computes the ADC values for each DW direction (saved to 
% [outBaseName 'ADC.nii.gz']) and the tensors (saved a dt6 file 
% [outBaseName 'dt6.mat']).
%
% 2007.01.25 RFD: wrote it, pulling code from a script. However, I've also
% determined that the resulting tensors aren't quite right (but they are
% close). Working on a better version... 

%% Load the raw DW data (in NIFTI format)
if(~exist('dwRawFile','var')|isempty(dwRawFile))
    [f,p] = uigetfile({'*.nii.gz';'*.*'},'Select a raw NIFTI file for input...');
    if(isnumeric(f)), disp('Conversion canceled.'); return; end
    dwRawFile = fullfile(p,f); 
end
[dataDir,inBaseName,ext] = fileparts(dwRawFile);
[junk,inBaseName,junk] = fileparts(inBaseName);
if(isempty(dataDir)) dataDir = pwd; end
if(~exist('bvecsFile','var')|isempty(bvecsFile))
  bvecsFile = fullfile(dataDir,[inBaseName '.bvecs']);
  if(~exist(bvecsFile,'file'))
    [f,p] = uigetfile({'*.bvecs';'*.*'},'Select the bvecs file...');
    if(isnumeric(f)), disp('User canceled.'); return; end
    bvecsFile = fullfile(p,f);
  end
end
if(~exist('bvalsFile','var')|isempty(bvalsFile))
  bvalsFile = fullfile(dataDir,[inBaseName '.bvals']);
  if(~exist(bvalsFile,'file'))
    [f,p] = uigetfile({'*.bvals';'*.*'},'Select the bvals file...');
    if(isnumeric(f)), disp('User canceled.'); return; end
    bvalsFile = fullfile(p,f);
  end
end
if(~exist('outBaseName','var')|isempty(outBaseName))
  outBaseName = fullfile(dataDir,inBaseName);
end

logMean = true;

disp(['Loading raw data ' dwRawFile '...']);
dwRaw = niftiRead(dwRawFile);
nvols = size(dwRaw.data,4);
dtMm = dwRaw.pixdim(1:3);
  
%% Load the bvecs & bvals
% NOTE: these are assumed to be specified in image space.
% If bvecs are in scanner space, use dtiReorientBvecs and
% dtiRawReorientBvecs.
%bvecs = dlmread(bvecsFile, ' ');
%bvals = dlmread(bvalsFile, ' ');
bvecs = dlmread(bvecsFile);
bvals = dlmread(bvalsFile);
if(size(bvecs,2)~=nvols || size(bvals,2)~=nvols)
  error(['bvecs/bvals: need one entry for each of the ' str2num(nvols) ' volumes.']);
end

%% Separate DW and non-DW images
disp('Averaging b=0 images...');
dwInds = bvals>0;
b0Ims = double(dwRaw.data(:,:,:,~dwInds));
if(logMean)
  nz = b0Ims>0;
  b0Ims(nz) = log(b0Ims(nz));
  dw.b0 = mean(b0Ims,4);
  nz = dw.b0>0;
  dw.b0(nz) = exp(dw.b0(nz));
else
  dw.b0 = mean(b0Ims,4);
end
clear b0Ims;

% Put some useful stuff in a struct
[b0,clipVals] = mrAnatHistogramClip(dw.b0,0.4,0.995);
b0 = int16(round(b0*clipVals(2)));
dw.brainMask = dtiCleanImageMask(b0>max(b0(:))*0.3);
dw.imgs = dwRaw.data(:,:,:,dwInds);
dw.bvecs = bvecs(:,dwInds);
dw.bvals = bvals(dwInds);
dw.acpcXform = dwRaw.qto_xyz;
dw.rawFile = dwRawFile;
dw.mmPerVox = dwRaw.pixdim(1:3);

clear dwRaw;

averageAdc = false;
%% Compute ADC for each direction.
% Average repeats. This should be done in log space (ie. geometric mean)
if(averageAdc)
    disp('Averaging DW direction repeats...');
    [dw.adc_bvecs,ii,jj] = unique(dw.bvecs','rows');
    dw.adc_bvecs = dw.adc_bvecs';
    dw.adc_bvals = dw.bvals(ii);
    for(ii=1:length(dw.adc_bvals))
        reps = find(jj==ii);
        tmp = double(dw.imgs(:,:,:,reps));
        nz = tmp>0;
        tmp(nz) = log(tmp(nz));
        avgImgs(:,:,:,ii) = mean(tmp,4);
    end
    nz = avgImgs>0;
    avgImgs(nz) = exp(avgImgs(nz));
    dw.imgs = avgImgs;
    clear avgImgs;
else
    dw.adc_bvecs = dw.bvecs;
    dw.adc_bvals = dw.bvals;
end

% Fit the Stejskal-Tanner equation: S(b) = S(0) exp(-b ADC), 
% where S(b) is the image acquired at non-zero b-value, and S(0) is
% the image acquired at b=0. Thus, we can find ADC with the
% following: 
%   ADC = -1/b * log( S(b) / S(0) 
% But, to avoid divide-by-zero, we need to add a small offset to
% S(0). We also need to add a small offset to avoid log(0).
disp('Computing ADC maps for each DW direction...');
offset = 0.000001;
ndw = size(dw.imgs,4);
brainInds = find(dw.brainMask);
dw.adc = zeros(size(dw.imgs));
% *** TO DO: check this calculation.
for(ii=1:ndw)
  tmp = double(dw.imgs(:,:,:,ii));
  tmp(~dw.brainMask) = 0;
  tmp(brainInds) = -1./dw.adc_bvals(ii)*log(tmp(brainInds)./(dw.b0(brainInds)+offset)+offset);
  dw.adc(:,:,:,ii) = tmp;
end
% Now, our image intensities should have real units! They should be
% the same units as 1/b. For our data, this will convert to um^2/msec:
dw.adc = dw.adc.*1000;
% This can happen due to noise and spline interpolation
dw.adc(dw.adc<0) = 0;

%% Save ADC and B0 maps in NIFTI format
fn = [outBaseName 'Adc.'];
dtiWriteNiftiWrapper(single(dw.adc), dw.acpcXform, [fn 'nii.gz'], 1, 'ADC', 'ADC');
dlmwrite([fn 'bvecs'],dw.adc_bvecs,' ');
dtiWriteNiftiWrapper(int16(round(dw.b0)), dw.acpcXform, [outBaseName 'B0.nii.gz'], 1, 'non-diffusion-weighted image','b0');

%% Fit and save the tensor maps.
% We compute the diffusion tensor using a simple least-squares fit.
disp('Fitting the tensor model...');
dt6 = zeros([size(dw.b0) 6]);
bv = dw.adc_bvecs';
% this is the key matrix- the list of grad dirs in xx,yy,zz,xy,xz,yz format.
m = [bv(:,1).^2 bv(:,2).^2 bv(:,3).^2 bv(:,1).*bv(:,2) bv(:,1).*bv(:,3) bv(:,2).*bv(:,3)];
nadc = size(dw.adc,4);
tmpAdc = zeros(nadc,length(brainInds));
for(ii=1:nadc)
  tmp = double(dw.adc(:,:,:,ii));
  tmpAdc(ii,:) = tmp(brainInds);
end
% least-squares solution to the six unknowns (xx,yy,zz,xy,xz,yz)
coef = pinv(m)*tmpAdc;
for(ii=1:6)
   tmp = zeros(size(dw.b0));
   tmp(brainInds) = coef(ii,:);
   dt6(:,:,:,ii) = tmp;
end
xformToAcPc = dw.acpcXform;
mmPerVox = dw.mmPerVox;
save([outBaseName '_dt6'],'dt6','b0','xformToAcPc','mmPerVox');

return;
