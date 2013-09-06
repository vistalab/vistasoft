function xform = dtiRawRohdeEstimateEddyMotion(dwRaw, mnB0, bvals, outEddyCorrectXform, ecFlag)
% Estimate the Rohde 14-parameter motion/eddy-current deformation
% xform = dtiRawRohdeEstimateEddyMotion(dwRaw, mnB0, bvals, outEddyCorrectXform, [ecFlag==true])
%
% Estimates the 14-parameter motion and eddy-current deformation to unwarp
% diffusion-weighted images. The algorithm is an implementation of:
%
%   Rohde, Barnett, Basser, Marenco and Pierpaoli (2004). Comprehensive
%   Approach for Correction of Motion and Distortion in Diffusion-Weighted
%   MRI. MRM 51:103-114.
%
% Note that b=0 images are motion-corrected with a 6-param rigid-body
% realignment. If ecFlag==false, then all images are just motio corrected.
%
% HISTORY:
%
% 2007.05.02 RFD: started it.
% 2011.07.28 RFD: added noEcFlag.

%% PREP ARGUMENTS

% Load the raw DW data (in NIFTI format)
if(~exist('dwRaw','var')||isempty(dwRaw))
  [f,p] = uigetfile({'*.nii.gz;*.nii';'*.*'}, 'Select the raw DW NIFTI dataset...');
  if(isnumeric(f)) error('User cancelled.'); end
  dwRaw = fullfile(p,f);
end
if(ischar(dwRaw))
  % dwRaw can be a path to the file or the file itself
  [dataDir,inBaseName] = fileparts(dwRaw);
else
  [dataDir,inBaseName] = fileparts(dwRaw.fname);
end
[~,inBaseName,~] = fileparts(inBaseName);
if(isempty(dataDir)) dataDir = pwd; end

if(~exist('bvals','var')||isempty(bvals))
  bvals = fullfile(dataDir,'bvals');
  [f,p] = uigetfile({'*.bvals';'*.*'},'Select the bvals file...',bvals);
  if(isnumeric(f)), disp('User canceled.'); return; end
  bvals = fullfile(p,f);
end
if(ischar(bvals))
  %bvals = dlmread(bvals, ' ');
  bvals = dlmread(bvals);
end

% Load the b0 data (in NIFTI format)
if(~exist('mnB0','var')||isempty(mnB0))
  mnB0 = fullfile(dataDir, [inBaseName '_b0.nii.gz']);
  [f,p] = uigetfile({'*.nii.gz;*.nii';'*.*'}, 'Select the mean b0 NIFTI dataset...',mnB0);
  if(isnumeric(f)) error('User cancelled.'); end
  mnB0 = fullfile(p,f);
end
if(ischar(mnB0))
  disp(['Loading b0 data ' mnB0 '...']);
  mnB0 = niftiRead(mnB0);
end

% Check output file
if(~exist('outEddyCorrectXform','var')||isempty(outEddyCorrectXform))
  outEddyCorrectXform = fullfile(dataDir,[inBaseName '_ecXform']);
end

if(~exist('ecFlag','var')||isempty(ecFlag))
    ecFlag = true;
end

if(ischar(dwRaw))
  disp(['Loading raw data ' dwRaw '...']);
  dwRaw = niftiRead(dwRaw);
end

sz = size(dwRaw.data);
nvols = sz(4);
dtMm = dwRaw.pixdim(1:3);
% We hope that the phase-encoding dir is set correctly in the NIFTI header!
phaseDir = dwRaw.phase_dim; % 'e' in the Rohde paper
if(phaseDir==0)
  disp('NOTE: phase_dim in NIFTI header appears to have been set incorrectly- setting to 2.');
  phaseDir = 2;
end

if(size(bvals,2)<nvols)
  error(['bvals: need at least one entry for each of the ' num2str(nvols) ' volumes.']);
elseif(size(bvals,2)>nvols)
  warning('More bvals entries than volumes- clipping...');
  bvals = bvals(:,1:nvols);
end

%% LOOP OVER VOLS
% For each image, compute the deformation to remove motion and eddy-current
% distortions.

% Set-up rigid-body alignment for motion correction
% Initialize SPM default params
estParams        = spm_get_defaults('coreg.estimate');
estParams.params = [0 0 0 0 0 0];% Rigid-body (6-params)

% Multiresolution search control params. Specifies the histogram sampling
% density, in mm. Try [8 4], [6 3], [4 2]?
dwiSep = [6 3];

targetNoBlur.uint8 = uint8(round(mrAnatHistogramClip(double(mnB0.data),0.4,0.99)*255));
targetNoBlur.mat = eye(4);
source.mat = eye(4);
% Blur target image given the specified sampling densities
for(sr=1:numel(dwiSep))
  fwhm(sr,:) = sqrt(max([1 1 1]*dwiSep(sr)^2 - dtMm.^2, [0 0 0]))./dtMm;
  target(sr).uint8 = mrAnatSmoothUint8(targetNoBlur.uint8,fwhm);
end

% Registration involves finding the coordinate transform (f_alpha) for each
% image volume (alpha) that transforms the target coordinates x into the
% source coordinates x_alpha. (We map target to source becasue for
% interpolation, we need to know from where in the source image we should
% pull the data to fill each voxel in the target image. Ie., for each
% target image voxel, we'll draw data from a point in the source image.)
%
if(ecFlag)
    % eddy-current correct the b>0 volumes
    ecVols = bvals>0;
else
    % no eddy-current correction for any volume
    ecVols = false(size(bvals));
end
etDw = []; etNdw = []; % timers for estimating run-time
ndw = sum(ecVols); nndw = sum(~ecVols);
tol = [2e-2 2e-2 2e-2, 1e-3 1e-3 1e-3, 3e-4 3e-4 3e-4, 1e-4 1e-4 1e-4 4e-5 2e-5];
prevNdwiParams = [0 0 0 0 0 0 0 0 0 0 0 0 0 0];
for(ii=1:nvols)
  fprintf('[%s] Aligning vol %d of %d to mean b=0 image\n', mfilename,ii, nvols);
  if(~isempty(etDw)&&~isempty(etNdw))
    et = (sum(etDw)+sum(etNdw))./60;
    estRemain = (mean(etDw)*ndw+mean(etNdw)*nndw)./60 - et;
    if(estRemain>90), estRemain = estRemain./60; et = et./60; estUnits = 'hours';
    else estUnits = 'minutes'; end
    fprintf('[%s] elapsed time %0.1f %s; %0.1f %s remaining...\n',mfilename, et,estUnits,estRemain,estUnits);
  end
  tic;
  srcIm = uint8(round(mrAnatHistogramClip(double(dwRaw.data(:,:,:,ii)),0.4,0.99)*255));
  xform(ii).phaseDir = phaseDir;
  if(~ecVols(ii))
    % Compute rigid-body motion correction
    fprintf('[%] Motion correction for non-DWI...\n',mfilename);
    source.uint8 = srcIm;
    % Wrap it in evalc to avoid the hundreds of lines of
    % print-out. This way, our output is cleaner which makes it
    % easier to track the progress.
    msg = evalc('m=spm_coreg(targetNoBlur,source,estParams);');
    % We could have used our Rohde estiamtor with non-linear params
    % fixed. It gives about the same answer as spm_coreg, but is a
    % bit slower. 
    m = m(end,:);
    xform(ii).ecParams = [m 0 0 0 0 0 0 0 0];
    prevNdwiParams = xform(ii).ecParams;
    etNdw(end+1) = toc;
  else
    % Compute Rohde deformation
    % Start with the rigid-body params from the most recent
    % non-dwi. That should be a solid estimate of the motion
    % correction needed for this region of the time series.
    mc = prevNdwiParams;
    startDirs = diag(tol*10);
    for(sr=1:numel(dwiSep))
      fprintf('[%s] Motion/eddy-current correction for DWI (resolution level %d of %d)\n',mfilename,sr,numel(dwiSep));
      sd = dwiSep(sr)./dtMm;
      srcImBlur = mrAnatSmoothUint8(srcIm,fwhm(sr,:));
      % Initialize the error function- it will cache the srcImg and
      % sample points (x) to save a little time.
      dtiRawRohdeEddyError(mc, phaseDir, srcImBlur, target(sr).uint8, sd);
      msg = evalc('[mc,f] = spm_powell(mc(:), startDirs, tol, ''dtiRawRohdeEddyError'', phaseDir, [], [], sd);');
	  %[mc,f] = spm_powell(mc(:), startDirs, tol, 'dtiRawRohdeEddyError', phaseDir, [], [], sd);
    end
    xform(ii).ecParams = mc';
    etDw(end+1) = toc;
  end
  %tmp = source; tmp.mat = target.mat*mc{ii}; dtiShowAlignFigure(99,target,tmp);
end
fprintf('[%s] Saving eddy/motion correction transforms to \n %s ...\n',mfilename, outEddyCorrectXform);
fprintf('[%s] These transforms map voxels in the reference image (usually the mean b=0) to each raw image.\n',mfilename);
save(outEddyCorrectXform, 'xform');
% Might switch to a simple text-format output?
% fn = [outEddyCorrectXform '.txt'];
% dlmwrite(fn,xform{1},'delimiter',' ','precision',6);
% for(ii=2:length(xform))
%     dlmwrite(fn,xform{ii},'delimiter',' ','roffset',1,'-append','precision',6);
% end

return;



