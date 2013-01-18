bd = '/biac3/wandell4/data/reading_longitude/';
dd = {'dti_y1','dti_y2','dti_y3','dti_y4'};
inDir = 'dti06_smooth2_SIRL54';
exclude = {'mb070905_motionBad'};
outDir = '/biac3/wandell4/data/reading_longitude/logNorm_analysis';

% Gather all the files
n = 0;
for(jj=1:length(dd))
  d = dir(fullfile(bd,dd{jj},'*0*'));
  for(ii=1:length(d))
	if(isempty(strmatch(d(ii).name,exclude,'exact')))
	  tmp = fullfile(bd,dd{jj},d(ii).name,inDir,'dt6.mat');
	  if(exist(tmp,'file'))
		n = n+1;
		datFiles(n).subDir = d(ii).name;
		datFiles(n).dt6 = tmp;
		datFiles(n).sc = strtok(datFiles(n).subDir,'0');
		datFiles(n).year = jj;
	  end
	end
  end
end

% build a group brain mask and some quick summary images
[dt,t1] = dtiLoadDt6(datFiles(1).dt6,false);
avg.t1Xform = t1.xformToAcpc;
avg.dtXform = dt.xformToAcpc;
%t1Mask = int16(t1.brainMask);
avg.t1Img = zeros(size(t1.img));
sz = size(dt.brainMask);
avg.mask = zeros(sz,'int16');
avg.grpMask = true(sz);
avg.b0 = zeros(sz);
avg.fa = zeros(sz);
avg.md = zeros(sz);
avg.dt6 = zeros([sz 6]);
allDt6 = zeros([sz 6 n],'single');
allB0 = zeros([sz n],'single');
for(ii=1:n)
  fprintf('Processing %d of %d (%s)...\n',ii,n,datFiles(ii).subDir);
  [dt,t1] = dtiLoadDt6(datFiles(ii).dt6,false);
  allDt6(:,:,:,:,ii) = single(dt.dt6);
  allB0(:,:,:,ii) = dt.b0;
  avg.t1Img = avg.t1Img+double(t1.img);
  %t1Mask = t1Mask+int16(t1.brainMask);
  avg.mask = avg.mask+int16(dt.brainMask);
  avg.grpMask = avg.grpMask & any(dt.dt6~=0,4);
  avg.b0 = avg.b0+double(dt.b0);
  [faTmp,mdTmp] = dtiComputeFA(double(dt.dt6));
  % fill little holes in the fa map
  m = isnan(faTmp);
  faTmp(m) = 0;
  for(kk=1:sz(3))
	faTmp(:,:,kk) = roifill(faTmp(:,:,kk),m(:,:,kk)); 
  end
  avg.fa = avg.fa+faTmp;
  avg.md = avg.md+mdTmp;
  avg.dt6 = avg.dt6+dt.dt6;
end

avg.b0 = avg.b0./n;
avg.fa = avg.fa./n;
avg.md = avg.md./n;
avg.dt6 = avg.dt6./n;
showMontage(avg.mask);
showMontage(avg.b0);
showMontage(avg.fa);
showMontage(avg.md);
[vec,val] = dtiEig(avg.dt6);
avg.pdd = abs(squeeze(vec(:,:,:,1,:))).*repmat(dtiComputeFA(val),[1 1 1 3]);
makeMontage3(avg.pdd);

clear mdTmp faTmp m t1 vec val dt

% Now keep only the brain inds
%brainMask = avg.grpMask&avg.b0>200;
brainMask = avg.mask>=n/2;
dt6 = zeros([sum(double(brainMask(:))) 6 n],'single');
for(ii=1:n)
  fprintf('Processing %d of %d (%s)...\n',ii,n,datFiles(ii).subDir);
  %dt = dtiLoadDt6(datFiles(ii).dt6);
  dt6(:,:,ii) = dtiImgToInd(allDt6(:,:,:,:,ii),brainMask);
end

save(fullfile(outDir,'avg'),'avg','datFiles','brainMask','dt6');
clear allDt6 allB0;

binDir = fullfile(dataDir,'dti06','bin');
desc = 'average';
dtiWriteNiftiWrapper(int16(round(avg.t1Img./max(avg.t1Img(:)).*32767)), avg.t1Xform, fullfile(fileparts(binDir),'t1.nii.gz'), 1, desc, 't1');
dtiWriteNiftiWrapper(int16(round(avg.b0)), avg.dtXform, fullfile(binDir,'b0.nii.gz'), 1, desc, 'b0');
dtiWriteNiftiWrapper(avg.mask, avg.dtXform, fullfile(binDir,'brainMask.nii.gz'), 1, desc, 'brainMask');
dt6Im = avg.dt6(:,:,:,[1 4 2 5 6 3]);
sz = size(dt6Im);
dtiWriteNiftiWrapper(reshape(dt6Im,[sz(1:3),1,sz(4)]), avg.dtXform, fullfile(binDir,'tensors.nii.gz'), 1, desc, ['DTI']);

badVox = sum(squeeze(all(dt6==0,2)),1);
find(badVox>(mean(badVox)+2*std(badVox)))

clear avg;
[vec,val] = dtiEig(double(dt6));
minVal = max(val(:)).*.005;
val(val<minVal) = minVal;
logDt6 = dtiEigComp(vec,log(val));
clear vec val;
d = squeeze(sum(logDt6.^2,2));
