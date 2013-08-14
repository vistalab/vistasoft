function bvecs = dtiRawCheckBvecs(dwRawFile, gradsFile, bval)
%
% bvecs = dtiRawCheckBvecs(dwrawFile, gradsFile)
%
%
% HISTORY:
% 2008.05.16 RFD wrote it.

dwRawFile = 'avg_set_nii.nii.gz';
gradsFile = '1718.grads';
bval = 1.0;

dwRaw = niftiRead(dwRawFile);
xform = eye(4);
nvols = size(dwRaw.data,4);
if(isnumeric(bval))
   [bvecs,bvals] = dtiRawBuildBvecs(nvols, xform, gradsFile, bval);
else
   bvecs = dlmread(gradsFile);
   bvals = dlmread(bval);
end

sz = size(dwRaw.data);
d = double(dwRaw.data);
xform = dwRaw.qto_xyz;
% Make a simple brain mask
b0 = mean(d(:,:,:,bvals==0),4);
% Tidy up the data a bit- replace any dw value > the mean b0 with the mean b0.
% Such data must be artifacts and fixing them reduces the # of non P-D tensors.
for(ii=find(bvals>0)) tmp=d(:,:,:,ii); bv=tmp>b0; tmp(bv)=b0(bv); d(:,:,:,ii)=tmp; end 
[b0,clipVal] = mrAnatHistogramClip(b0, 0.4, 0.99, false);
% Mask out the bottom 20% or b0 intensities
maskThresh = 0.2*diff(clipVal)+clipVal(1);
mask = uint8(dtiCleanImageMask(b0>maskThresh));
q = [bvecs.*sqrt(repmat(bvals,3,1))]';
X = [ones(size(q,1),1) -q(:,1).^2 -q(:,2).^2 -q(:,3).^2 -2*q(:,1).*q(:,2) -2*q(:,1).*q(:,3) -2*q(:,2).*q(:,3)];
[dt6,pdd] = dtiFitTensor(d,X,[],[],mask);
% log(b0) is stored in dt6(:,:,:,1)
dt6 = dt6(:,:,:,2:7);
makeMontage3(abs(pdd));

[eigVec,eigVal] = dtiEig(dt6);
v1 = squeeze(eigVec(:,:,:,[1 2 3],1));
[fa,md,rd] = dtiComputeFA(eigVal);
showMontage(b0);
showMontage(fa);
showMontage(md);
showMontage(rd);

%dtiRawPreprocess('avg_set_nii.nii.gz','T1_avg_nifti_output.nii.gz',1.0,'1718.grads',false,[],false,0,false) 
