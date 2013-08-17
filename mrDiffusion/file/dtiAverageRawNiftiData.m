inData = 'mbs_dwi_raw.nii.gz';
outData = 'mbs_dwi_mean.nii.gz';

bval = 800;
gradsFile = '/usr/local/dti/diffusion_grads/dwepi.65.grads';

%bvals = dlmread('bvals');
%bvecs = dlmread('bvecs');
%copyfile('bvals','bvals_orig');
%copyfile('bvecs','bvecs_orig');

figs = false;

ni = niftiRead(inData);
sz = size(ni.data);
nVols = sz(4);
%xform = dtiFiniteStrainDecompose(ni.qto_ijk);
b = ni.quatern_b; c = ni.quatern_c; d = ni.quatern_d;
a = sqrt(1.0-(b*b+c*c+d*d));
xform = quatR2mat([a b c d]);
% This xform rotates us from image coords to scanner coords. We
% want to apply the reverse, to rotate our bvecs from scanner
% coords to image coords.
xform = inv(xform);

grads = dlmread(gradsFile);
% *** WHY IS THIS NECESSARY?
%grads(:,3) = -grads(:,3);

if(size(grads,1)<nVols)
  % Assume that there are repeats
  grads = repmat(grads,floor(nVols/size(grads,1)),1);
end

rawBvecs = xform*grads';
for(ii=1:size(rawBvecs,2)) 
  n = norm(rawBvecs(:,ii)); 
  if(n~=0) rawBvecs(:,ii) = rawBvecs(:,ii)./n; end
end
bvecs = unique(rawBvecs','rows')';
bvals = repmat(bval,1,size(bvecs,2));
for(ii=1:size(bvecs,2)) n(ii) = norm(bvecs(:,ii)); end
% Put non-DWI first
ndwi = find(n==0);
if(length(ndwi)~=1) error('more than one non-DWI!'); end
if(ndwi~=1)
  bvecs(:,ndwi) = [];
  bvecs = [[0;0;0],bvecs];
  ndwi = 1;
end
% zero-out bvals corresponding to non-dw images
bvals(ndwi) = 0;

dlmwrite('bvecs',bvecs,' ');
dlmwrite('bvals',bvals,' ');

if(figs) fn = figure; end
newData = zeros([sz(1:3) length(bvals)]);
for(ii=1:length(bvals))
  curImgs = find(rawBvecs(1,:)==bvecs(1,ii)&rawBvecs(2,:)==bvecs(2,ii)&rawBvecs(3,:)==bvecs(3,ii));
  newData(:,:,:,ii) = mean(ni.data(:,:,:,curImgs),4);
  msg = sprintf('Im %d = mean([ %s ]); bvecs = [ %0.3f %0.3f %0.3f ]',ii,num2str(curImgs),bvecs(:,ii));
  if(figs)
    figure(fn);imagesc(makeMontage(newData(:,:,:,ii)));colormap gray;axis image off tight;colorbar;
    title(msg);
    pause(1);
  end
  disp(msg);
end

ni.data = newData;
ni.fname = outData;
writeFileNifti(ni);


% After this, try
% eddy_correct mbs_dwi_raw_means mbs_dwi_ec 0
% dtifit -k mbs_dwi_ec -o mbs_dti -m mbs_dwi_ec_bet_mask -r bvecs -b bvals

