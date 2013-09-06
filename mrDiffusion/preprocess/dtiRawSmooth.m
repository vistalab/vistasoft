
function [dwData,xform,X,brainMask] = dtiRawSmooth(dwRaw, bvecs, bvals, iter, pmDeltaT)
%
% [dwData,xform,X,brainMask] = dtiRawSmooth(dwRaw, bvecs, bvals, [iter=1], [peronaMalikDeltaT=0])
%
% Smooths the raw data in dwRaw using a tensor-based anisotropic
% kernel. The kernel is derived from the tensor itself and is
% applied to the raw data. The kernel is based on that described
% in:
%
% Lee, Chung, Oakes & Alexander (2005). Anisotropic Gaussian kernel
% smoothing of DTI data. ISMRM, 2253.
%
% And:
%
% Lee, Chung & Alexander (2006). Evaluation of anisotropic filters
% for diffusion tensor imaging. IEEE-ISBI, 1241.
%
% (Also see http://www.stat.wisc.edu/~mchung/softwares/dti/dti.html.)
%
% The smoothing parameter t is fixed at 0.08 and the tensor exponent
% (parameter 'p') is fixed at 3. The kernel is applied using a
% 27-voxel neighborhood. To achieve more smoothing, just do more
% iterations. The effective sigma of the gaussian kernel is: (FIND ME)
%
% If peronaMalikDeltaT>0, then a Perona-Malik image gradient-based
% anisotropic diffusion filter is applied to the raw data at the
% start of each iteration, before the tensor is computed for the
% tensor-based filter. This is what Lee, Chung & Alexander (2006)
% suggest as optimal. However, I found this produces too much
% smoothing, even with a very small deltaT. Note that
% peronaMalikDeltaT should be 0 - 3/44. 
%
% TO DO:
% * use mmPerVox when computing the tensor kernel
% * rewrite the Perona-Malik code to speed-up the convolution 
%
% NOTE:
% If you want to apply smoothing to a mrDiffusion dt6 dataset, use
% dtiTensorSmoothing, which is a convenient wrapper around this
% function.
%
% HISTORY:
% 2007.11.08 RFD: wrote it.

t = 0.005; % keep <= 0.1; .02?
p = 3;
if(~exist('pmDeltaT','var')||isempty(pmDeltaT))
  pmDeltaT = 0;
else
  if(pmDeltaT<0||pmDeltaT>3/44)
	error('pmDeltaT must be in the range (0,3/44).');
  end
end

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
[junk,inBaseName,junk] = fileparts(inBaseName);
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

if(~exist('iter','var')||isempty(iter))
   iter = 1;
end

if(ischar(dwRaw))
    % dwRaw can be a path to the file or the file itself
    disp(['Loading raw data ' dwRaw '...']);
    dwRaw = niftiRead(dwRaw);
end

nvols = size(dwRaw.data,4);
mmPerVox = dwRaw.pixdim(1:3);
xform = dwRaw.qto_xyz;
dwData = double(dwRaw.data);
clear dwRaw; 

%% Load the bvecs & bvals
% NOTE: these are assumed to be specified in image space.
% If bvecs are in scanner space, use dtiReorientBvecs and
% dtiRawReorientBvecs.
if(~isnumeric(bvecs))
  bvecs = dlmread(bvecs);
end
if(~isnumeric(bvals))
  bvals = dlmread(bvals);
end

if(size(bvecs,2)~=nvols || size(bvals,2)~=nvols)
  error(['bvecs/bvals: need one entry for each of the ' num2str(nvols) ' volumes.']);
end

minD = min(dwData(dwData(:)>0));

%% Compute a brain mask
% 
disp('Computing brain mask from average b0...');
dwInds = bvals>0;
b0Ims = dwData(:,:,:,~dwInds);
nz = b0Ims>0;
b0Ims(nz) = log(b0Ims(nz));
b0 = exp(mean(b0Ims,4));
clear b0Ims nz;
b0clip = mrAnatHistogramClip(b0,0.4,0.98);
b0 = int16(round(b0));
% We use a liberal brain mask for deciding which tensors to compute, but a
% more conservative mask will be saved so that that the junk outside the
% brain won't be displayed when we view the data.
brainMask = dtiCleanImageMask(b0clip>0.1&all(dwData>0,4),10,1,0.25,50);
% force the data to be physically plausible.
dwData(dwData<=0) = minD;
brainMask = uint8(brainMask);
clear b0clip badEdgeVox;

tau = 1;
q = [bvecs.*sqrt(repmat(bvals./tau,3,1))]';
X = [ones(size(q,1),1) -tau.*q(:,1).^2 -tau.*q(:,2).^2 -tau.*q(:,3).^2 -2*tau.*q(:,1).*q(:,2) -2*tau.*q(:,1).*q(:,3) -2*tau.*q(:,2).*q(:,3)];

%% Smooth the data
% 
sz = size(dwData);
for(ii=1:iter)
  fprintf('Iteration %d of %d...\n',ii,iter);
  if(pmDeltaT>0)
	disp('  Applying Perona-Malik gradient-based anisotropic filter...');
	tic;
	for(jj=1:sz(4))
	  dwData(:,:,:,jj) = dtiSmoothAnisoPM(dwData(:,:,:,jj), 1, pmDeltaT, 70, 1, mmPerVox);
	end
	toc
  end
  disp('  Applying tensor-based anisotropic filter...');
  tic;
  dt6 = dtiFitTensor(dwData,X,[],[],brainMask);
  dt6 = dt6(:,:,:,[2:7]);
  % Ensure PDness:
  [eigVec, eigVal] = dtiEig(dt6);
  clear dt6;
  eigVal(eigVal<0) = 0;
  % We'll clip the eigenvalues to be >=.5% of the max
  % eigenvalue. This should ensure that all the eigenvalues are
  % large enough to avoid singularity in the calculations below.
  % Note that this will also clip the FA to a max of 0.998.
  minVal = max(eigVal(:))*.005;
  eigVal(eigVal<minVal) = minVal;
  md = mean(eigVal,4);
  md = mean(md(logical(brainMask(:))));
  % fill air voxels with isotropic tensors of mean brain diffusivity
  eigVal(repmat(~brainMask,[1 1 1 3])) = md;
  dt6 = dtiEigComp(eigVec, eigVal);
  clear eigVal eigVec;
  D = dti6to33(dt6);
  clear dt6;
  if(p>1)
	% Raise D to the specified (INTEGER!) power 'p' (.^p, not ^p)
	for(jj=1:p)
	  D = D.*D;
	end
  end
  % Compute the determinant of D
  % det(D) for a 3x3 [a b c; d e f; g h i] is: (aei+bfg+cdh)-(gec+hfa+idb)
  % a=1,1; b=1,2; c=1,3; d=2,1; e=2,2; f=2,3; g=3,1; h=3,2; i=3,3;
  detD = (D(:,:,:,1,1).*D(:,:,:,2,2).*D(:,:,:,3,3) ...
          + D(:,:,:,1,2).*D(:,:,:,2,3).*D(:,:,:,3,1) ...
          + D(:,:,:,1,3).*D(:,:,:,2,1).*D(:,:,:,3,2)) ...
		 -(D(:,:,:,3,1).*D(:,:,:,2,2).*D(:,:,:,1,3) ...
		   + D(:,:,:,3,2).*D(:,:,:,2,3).*D(:,:,:,1,1) ...
		   + D(:,:,:,3,3).*D(:,:,:,2,1).*D(:,:,:,1,2));
  iD = shiftdim(ndfun('inv',shiftdim(D,3)),2);
  % normalize so sum(eigVal)==1
  tr = iD(:,:,:,1,1)+iD(:,:,:,2,2)+iD(:,:,:,3,3)+1e-12;
  for(jj=1:9)
	iD(:,:,:,jj) = iD(:,:,:,jj)./tr;
  end
  clear tr;
  scale = (4*pi*t)^1.5 .* sqrt(detD)+1e-12;
  % Compute the kernel for each voxel.
  for(xx=[-1:1])
	for(yy=[-1:1])
	  for(zz=[-1:1])
		x = [xx yy zz];
		%Kt(:,:,:,2+xx,2+yy,2+zz) = exp(-x*iD*x'./(4*t))/((4*pi*t)^(3/2)*(det(D))^0.5);
		s = shiftdim(ndfun('mult',ndfun('mult',x,shiftdim(iD,3)),x'),2);
		Kt(:,:,:,2+xx,2+yy,2+zz) = exp(-s./(4.*t)) ./ scale;
	  end
	end
  end
  clear scale s;
  % Normalize the kernel to have unit volume
  scale = sum(sum(sum(Kt,6),5),4);
  for(jj=1:27)
	Kt(:,:,:,jj) = Kt(:,:,:,jj)./scale;
  end
  clear scale;
  % Apply the kernel
  for(jj=1:sz(4))
	d = padarray(dwData(:,:,:,jj),[1 1 1],'replicate','both');
	tmp = zeros(sz(1:3));
	for(xx=[1:3])
	  for(yy=[1:3])
		for(zz=[1:3])
		  e = sz(1:3)+[xx yy zz]-1;
		  tmp = tmp+Kt(:,:,:,xx,yy,zz).*d(xx:e(1),yy:e(2),zz:e(3));
		end
	  end
	end
	dwData(:,:,:,jj) = tmp;
  end
  toc;
end
if(nargout==0)
  clear dwData;
end
return;

bd = '/biac3/wandell4/data/reading_longitude/dti_y2/';
iter = 2;
inDir = 'dti06';
inRaw = 'dti_g13_b800_aligned';
outDir = sprintf('%s_smooth%d',inDir,iter);

d = dir(fullfile(bd,'*0*'));
for(ii=1:length(d))
    s{ii} = fullfile(bd,d(ii).name);
end

for(ii=1:length(s))
  rawF = fullfile(s{ii},'raw',inRaw);
  if(~exist([rawF '.nii.gz'],'file'))
	disp(['skipping ' s{ii} '...']);
	continue;
  end
  [dw,xform,X,brainMask] = dtiRawSmooth([rawF '.nii.gz'],[rawF '.bvecs'],[rawF '.bvals'],iter);
  [dt6,pdd] = dtiFitTensor(dw,X,[],[],brainMask);
  clear dw; clear mex;
  b0 = exp(dt6(:,:,:,1));
  dt6 = dt6(:,:,:,[2:7]);
  out = fullfile(s{ii},outDir);
  mkdir(out);
  mkdir(out,'bin');
  dt6 = dt6(:,:,:,[1 4 2 5 6 3]);
  sz = size(dt6);
  dt6 = reshape(dt6,[sz(1:3),1,sz(4)]);
  desc = sprintf('tensor-smoothed (iter=%d) on %s',iter,datestr(now,'yyyy-mm-dd HH:MM'));
  fname = fullfile(out,'bin','tensors.nii.gz');
  dtiWriteNiftiWrapper(dt6, xform, fname, 1, desc, ['DTI']);
  fname = fullfile(out,'bin','b0.nii.gz');
  dtiWriteNiftiWrapper(int16(round(b0)), xform, fname, 1, desc, 'b0')
  copyfile(fullfile(s{ii},inDir,'bin','brainMask.nii.gz'),fullfile(out,'bin','brainMask.nii.gz'));
  copyfile(fullfile(s{ii},inDir,'dt6.mat'),fullfile(out,'dt6.mat'));
end
