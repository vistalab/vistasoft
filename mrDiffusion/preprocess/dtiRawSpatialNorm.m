function dtiRawSpatialNorm(dwRawFile, outDir, maskThresh)
%
% dtiRawSpatialNorm(dwRawFile, outDir, maskThresh)
%
% generates spatially normalized scalars (b0, FA, MD, etc.) from a
% mrDiffusion raw dataset. Assumes data are in dwRawFile and that
% supporting files (like bvecs, bvals, etc) are in the same
% dir. Normalizes b0 to the MNI EPI template in
% mrDiffusion/templates. Saves output in outDir. 
%
% HISTORY: 
% 2008.01.22 RFD wrote it.
% 2008.01.25 RFD: b0 is now computed rather than loaded, to avoid
% confusion and error. We also now check to make sure the
% cannonical xform is applied if needed.

if(~exist('maskThresh','var')||isempty(maskThresh))
  maskThresh = 0.2;
end

%dwRawFile = '/biac3/wandell4/data/reading_longitude/dti_y1/rh040630/raw/dti_g13_b800.nii.gz';
[p,f,e] = fileparts(dwRawFile);
if(strfind(f,'.nii')) f = f(1:strfind(f,'.nii')-1); end
bn = fullfile(p,f);

tDir = fullfile(fileparts(which('mrDiffusion.m')),'templates');
tName = 'MNI_EPI';
template = fullfile(tDir,[tName '.nii.gz']);
%outDir = fullfile(dataDir,[tName '_sn']);
mkdir(outDir);

disp(['loading raw data (' bn '.nii.gz)...']);
bvecs = dlmread([bn '_aligned.bvecs']);
bvals = dlmread([bn '_aligned.bvals']);
ec = load([bn '_ecXform.mat']);
acpc = load([bn '_acpcXform.mat']);
dwRaw = niftiRead([bn '.nii.gz']);
% APply the cannonical xform to make sure data are unflipped axial
% (RAS) oriented. The acpc xform assumes this and our mrDiffusion
% tempalates are in this orientation.
dwRaw = niftiApplyCannonicalXform(dwRaw);

disp('Applying eddy correction...');
bb = [1 1 1; dwRaw.dim(1:3)];
sz = size(dwRaw.data);
d = zeros(sz(1:4));
udi = round(sz(4)/10);
for(ii=1:sz(4))
  if(mod(ii,udi)==0) fprintf('%d%% finished...\n',round(ii/udi*10)); end
  d(:,:,:,ii) = mrAnatResliceSpm(double(dwRaw.data(:,:,:,ii)), ec.xform(ii), bb, [1 1 1], [1 1 1 0 0 0], 0);
end
clear dwRaw;

disp('Generating mean b0...');
% average all b0's, taking care to avoid producing NANs in regions
% with some data. Using matlab's 'mean' will simply put a NAN in
% every voxel where there are NANs in *any* of the repeats. This
% code will leave NANs only where all repeats have NANs.
allB0 = d(:,:,:,bvals==0);
b0 = zeros(size(allB0(:,:,:,1)));
n = zeros(size(allB0(:,:,:,1)));
for(ii=1:size(allB0,4))
  tmp = allB0(:,:,:,ii);
  gv = ~isnan(tmp);
  b0(gv) = b0(gv)+tmp(gv);
  n = n+gv;
end
gv = n>0;
b0(gv) = b0(gv)./n(gv);
b0(~gv) = NaN;
clear tmp gv n;

disp(['Computing spatial normalization on b0...']);
b0_img = mrAnatHistogramClip(b0,0.4,0.98);
mask = uint8(dtiCleanImageMask(b0_img>maskThresh));
sn = mrAnatComputeSpmSpatialNorm(b0_img, acpc.acpcXform, template);
clear b0_img;
% Remove dat fields before saving
if isfield(sn.VF,'dat'), sn.VF = rmfield(sn.VF,'dat'); end;
if isfield(sn.VG,'dat'), sn.VG = rmfield(sn.VG,'dat'); end;
save(fullfile(outDir,'b0_sn.mat'),'-STRUCT','sn');

disp('Fitting tensors...');
q = [bvecs.*sqrt(repmat(bvals,3,1))]';
X = [ones(size(q,1),1) -q(:,1).^2 -q(:,2).^2 -q(:,3).^2 -2.*q(:,1).*q(:,2) -2.*q(:,1).*q(:,3) -2.*q(:,2).*q(:,3)];
% Tidy up the data a bit- replace any dw value > the min b0 with the min b0.
% Such data must be artifacts and fixing them reduces the # of non P-D tensors.
minB0 = min(d(:,:,:,bvals==0),[],4);
for(ii=find(bvals>0)) tmp=d(:,:,:,ii); bv=tmp>minB0; tmp(bv)=minB0(bv); d(:,:,:,ii)=tmp; end 
tic;[dt,pdd] = dtiFitTensor(d,X,0,[],mask); toc
dt = dt(:,:,:,2:7);
%makeMontage3(abs(pdd));
[vec,val] = dtiEig(dt);
[fa,md,rd] = dtiComputeFA(val);
ad = val(:,:,:,1);

disp('resampling and saving results...');
mm = diag(chol(sn.VG.mat(1:3,1:3)'*sn.VG.mat(1:3,1:3)))';
bb = mrAnatXformCoords(sn.VG.mat,[1 1 1;sn.VG.dim]);
[im,xform] = mrAnatResliceSpm(b0, sn, bb, mm, [1 1 1 0 0 0],0);
dtiWriteNiftiWrapper(single(im), xform, fullfile(outDir,'b0.nii.gz'), 1);
[im,xform] = mrAnatResliceSpm(fa, sn, bb, mm, [1 1 1 0 0 0], 0);
dtiWriteNiftiWrapper(single(im), xform, fullfile(outDir,'fa.nii.gz'), 1);
[im,xform] = mrAnatResliceSpm(md, sn, bb, mm, [1 1 1 0 0 0], 0);
dtiWriteNiftiWrapper(single(im), xform, fullfile(outDir,'md.nii.gz'), 1);
[im,xform] = mrAnatResliceSpm(rd, sn, bb, mm, [1 1 1 0 0 0], 0);
dtiWriteNiftiWrapper(single(im), xform, fullfile(outDir,'rd.nii.gz'), 1);
[im,xform] = mrAnatResliceSpm(ad, sn, bb, mm, [1 1 1 0 0 0], 0);
dtiWriteNiftiWrapper(single(im), xform, fullfile(outDir,'ad.nii.gz'), 1);


return;


if(1)
  % Save one slice to a movie
  dwSn = niftiRead(outFname);
  M = zeros(dwSn.dim([1,2,4]),'uint8');
  slNum = round(dwSn.dim(3)/2);
  for(ii=1:dwSn.dim(4))    
    M(:,:,ii) = uint8(round(mrAnatHistogramClip(double(dwSn.data(:,:,slNum,ii)),0.4,0.99)*255));
  end
  M = flipdim(permute(M,[2,1,3]),1);
  M = M./4; M(M>63) = 63;
  % The gif writer wants a 4d dataset (???)
  M = reshape(M,[size(M,1),size(M,2),1,size(M,3)]);
  imwrite(M,gray(64),['/home/bob/public_html/dw.gif'],'DelayTime',0.1,'LoopCount',65535);
end

