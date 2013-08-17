function [bvecs,bvals] = dtiRawBuildBvecs(nVols, xform, gradsFile, bval, outBaseName, assetFlag)
%
% dtiRawBuildBvecs(nvols, xform, [gradsFile=uigetfile], [bval=0.8], ... 
%                                 [outBaseName=[]], [assetFlag=false]);
%
% Creates "FSL-style" 'bvecs' and 'bvals' files given a Bammer/GE style
% 'grads' file of gradient directions. The bvecs are reoriented to image
% space given the xform (leave empty for no xform).
%
% xform should be the rotation component of the scanner-to-image xform.
% This transform should be in the NIFTI qto_ijk field, but sometimes it is
% set in sto_ijk. This transform maps scanner coordinates (x,y,z) to
% physical, image coordinates (i,j,k). In other words, it tells us how to
% rotate the scanner space to be aligned with the image space. The bvecs
% are usually specified in the scanner space coordinate frame, so we can
% use this transform to rotate them to the image frame. Note that some
% protocols might keep the directions in image (or 'logical') space, in
% which case the xform was applied at acquisition. For such protocols, you
% should not rotate the bvecs (xform=[] or xform=eye(3)).
%
% If xform is 4x4, it is assumed to be an affine xform and the rotation
% compoenent will be extracted.
%
% assetFlag is an idiosyncratic thing for the Hedehus/Bammer sequence used
% at Stanford. This sequence reorients the gradient directions specified in
% the dwepi.grads file to logical space rather than keeping the directions
% in scanner space. Thus, the bvecs do not need to be reoriented for
% oblique prescriptions as with some other DTI sequences. However, this
% sequence assumes that the 2nd column in dwepi.grads is the phase-encode
% dim. If your phase-enmcode is the usual '2', then this is fine. But, if
% you run ASSET and change the phase encode to L-R (dim 1), you need to
% swap the first and second columns of dwepi.grads. Also, there appears to
% be a flip in the phase-encode dim, so you also need to flip the sign on
% the phase-encode column.
% 
% WEB RESOURCES:
%   mrvBrowseSVN('dtiRawBuildBvecs');
%   http://white.stanford.edu/newlm/index.php/DTI_Preprocessing
%
% EXAMPLE USAGE:
%   dwRaw = niftiRead('rawDti.nii.gz');
%   nVols = size(dwRaw.data,4);
%   xform = affineExtractRotation(dwRaw.qto_ijk);
%   [bvecs,bvals] = dtiRawBuildBvecs(nVols, xform, gradsFile, bval, 'rawDti')
% 
% 
% 2006.12.11 RFD: wrote it with BAW & AJS.
% 2007.01.29 RFD: reverted to using qto_ijk to get rotation matrix rather
% than computing it directly from the quaternion. I think it is safer to
% let the NIFTI code build the matrix for us. Also, we were occasionally
% getting imaginary values in our rotation matrix.
% 2007.03.21 RFD: changed default bval to 0.8 (consistent with our
% preference for msec/micrometers^2 units) and renamed the file to be more
% consistent with the other dti pre-processing functions.
% 2009.05.20 RFD: we now adjust bvalues to reflect gradient strength for
% bvecs with norm != 1.
% 
% (C) Stanford University, VISTA 
% 

%% Check Inputs

if(~exist('outBaseName','var')), outBaseName = ''; end
if(nargout==0&&isempty(outBaseName))
    error('outBaseName must be specificed when nargout==0.');
end
if(~exist('gradsFile','var')||isempty(gradsFile))
  if(isunix)
    defaultDir = '/usr/local/dti/diffusion_grads/';
  else
    defaultDir = pwd;
  end
  [f,p] = uigetfile({'*.grads';'*.*'}, 'Select the GE grads file...',defaultDir);
  if(isnumeric(f)), error('User cancelled.'); end
  gradsFile = fullfile(p,f);
end

if(~exist('bval','var')) 
  bval = 0.8; 
  warning(sprintf('Using default b-value of %f msec/micrometers^2.',bval));
end

if(~exist('assetFlag','var')||isempty(assetFlag)), assetFlag = false; end

if(~exist('xform','var')); xform = []; end
if(isempty(xform))
  xform = eye(3);
elseif(size(xform,1)==4||size(xform,2)==4)
  xform = affineExtractRotation(xform);
end


%% Build the Bvecs/Bvals

% Read the grads file
grads = dlmread(gradsFile);

% We may need to transpose grads file
if size(grads,1)<size(grads,2)
    grads = grads';
end
if(size(grads,1)<nVols)
  % Assume that there are repeats and that the last repeat might not have
  % finished.
  grads = repmat(grads,ceil(nVols/size(grads,1)),1);
  grads = grads(1:nVols,:);
end

if(assetFlag)
    disp('Applying ASSET reorientation for Hedehus/Bammer sequence...');
    grads = grads*[0 -1 0; 1 0 0; 0 0 1];
end

% X-form the bvecs
bvecs       = xform*grads';
bvecNorm    = sqrt(sum(bvecs.^2));
nz          = bvecNorm~=0;
bvecs(:,nz) = bvecs(:,nz)./repmat(bvecNorm(nz),[3 1]);
bvals       = repmat(bval,1,size(bvecs,2));

% Zero-out non-dwi bvals
bvals(all(bvecs==0)) = 0;

% Scale the bvalues according to gradient magnitude. This assumes that the
% specified b-value is the max bvalue. Note that we only do this when all
% the bvec norms are 1 or less. If any of the bvec norms are >1, then we
% assume that the bvecs are just encoded sloppily and their norms do not
% really reflect the gradient amplitudes.
if(all(bvecNorm<=1))
    bvals = bvals.*bvecNorm.^2;
end

% Write out the bvals and bvecs
if(~isempty(outBaseName))
    dlmwrite([outBaseName '.bvecs'],bvecs,' ');
    dlmwrite([outBaseName '.bvals'],bvals,' ');
end

return;
