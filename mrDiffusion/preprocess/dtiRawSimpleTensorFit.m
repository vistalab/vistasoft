bn = '/biac3/wandell4/data/reading_longitude/dti_y4/zs070717/raw/dti_g13_b800';
bn = '/biac3/wandell4/data/reading_longitude/dti_y4/zs070717/raw/dti_g87_b800';

dwRaw = niftiRead([bn '.nii.gz']);
sz = size(dwRaw.data);
d = single(dwRaw.data);
clear dwRaw;
bvecs = dlmread([bn '.bvecs']);
bvals = dlmread([bn '.bvals']);

% Apply eddy/motion correction
load([bn '_ecXform.mat']);

[X,Y,Z] = ndgrid([1:sz(1)],[1:sz(2)],[1:sz(3)]);
x = [X(:)'; Y(:)'; Z(:)']; clear X Y Z;
% Run the first one separate to cache the voxel list (x).
d(:,:,:,1) = reshape(mrAnatFastInterp3(d(:,:,:,1), x, [xform(1).ecParams xform(1).phaseDir]),sz(1:3));
for(ii=2:sz(4))
    if(mod(ii,30)==0), fprintf('Processing vol %d of %d...\n',ii,sz(4)); end
    % Save a few cycles by not resending the voxel list (x) on each iteration.
    d(:,:,:,1) = reshape(mrAnatFastInterp3(d(:,:,:,ii), [], [xform(ii).ecParams xform(ii).phaseDir]),sz(1:3));
end
d = double(d);

bv = dtiRawReorientBvecs(bvecs,xform,false);
tau = 40;
q = [bv.*sqrt(repmat(bvals./tau,3,1))]';
X = [ones(size(q,1),1) -tau.*q(:,1).^2 -tau.*q(:,2).^2 -tau.*q(:,3).^2 -2*tau.*q(:,1).*q(:,2) -2*tau.*q(:,1).*q(:,3) -2*tau.*q(:,2).*q(:,3)];

[x,y,z]=meshgrid([5:10],[5:10],[30:40]); 
noiseRegion = sub2ind(sz(1:3),x,y,z);
for(ii=1:sz(4))
   tmp = d(:,:,:,ii);
   n(ii,:) = double(tmp(noiseRegion(:))); 
end
sd = std(n(:));
signalSigma = 1.5267*sd;

tic;[dt,pdd] = dtiFitTensor(d,X); toc
makeMontage3(abs(pdd));

[fa,md] = dtiComputeFA(dt(:,:,:,2:7));
md(md>5)=5; md(md<0)=0;
showMontage(md);
fa(fa<0)=0; fa(fa>1)=1;
showMontage(fa);

sl = squeeze(md(6,:,:));
figure;imagesc(sl);axis image; colormap gray; colorbar
roi = roipoly;
t = 25;
fprintf('Self-diffusion @ %0.1f C = %0.2f, measured diffusivity = %0.2f.\n',t,dtiSelfDiffusionOfWater(t),mean(sl(roi(:))));
