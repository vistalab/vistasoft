
% TO DO:
% * group comparisons (boys/girls, good/poor readers)
% 
%
%
%
%

sumFile = '/biac3/wandell4/data/reading_longitude/logNorm_analysis/avg.mat';

load(sumFile);

badSubs = [100];
goodSubs = setdiff([1:size(dt6,3)],badSubs);
dt6 = dt6(:,:,goodSubs);
datFiles = datFiles(goodSubs);
subs = unique({datFiles.sc});
N = size(dt6,3);
[bd,colNames,sc]=dtiGetBehavioralData(subs,'/biac3/wandell4/data/reading_longitude/read_behav_measures_longitude.csv');

[vec,val] = dtiEig(double(dt6));

% Remove bad voxels
badVox = any(any(val<=0,3),2);
badVoxImg = dtiIndToImg(badVox,brainMask)==1;
brainMask(badVoxImg) = 0;
dt6 = dt6(~badVox,:,:);
val = val(~badVox,:,:);
vec = vec(~badVox,:,:,:);
logDt6 = dtiEigComp(vec,log(val));
clear vec val badVox badVoxImg;

% Check for normality using the kstest
nvox = size(dt6,1);
logKStest = zeros(nvox,6);
step = round(nvox/100);
for(ii=1:nvox)
  if(mod(ii,step)==0) fprintf('%d%% finished...\n',round(ii/nvox*100)); end
  for(jj=1:6)
	[h,logKStest(ii,jj)] = kstest(zscore(squeeze(logDt6(ii,jj,:))));
  end
end
for(ii=1:6)
  showMontage(dtiIndToImg(-log10(logKStest(:,ii)),brainMask));
end

[n,sigInd]=fdr(logKStest(:,1),.05,'original','mean');
fdrThresh = -log10(max(logKStest(sigInd,1)))

% Check for orthogonal invariance of the variability.
% This means that the covariance matrix is the same even if we 
% rotate the axes of the tensor.
%
% Any 
[M, S, N, T, df] = dtiLogTensorMean2(logDt6,'rot-inv');
showMontage(dtiIndToImg(T,brainMask));

[M, Sfull] = dtiLogTensorMean2(logDt6,'full');

pval = 1-chi2cdf(T,df);
showMontage(dtiIndToImg(-log10(pval),brainMask));

% Select voxel
s = [44,45,39; 45,45,40]; % splenium
%s = [27,45,46]; % left arcuate
tmpIm = zeros(size(brainMask));
for(ii=1:size(s,1))
  tmpIm(s(ii,1),s(ii,2),s(ii,3)) = 1;
end

tmpInds = dtiImgToInd(tmpIm,brainMask);
ind = find(tmpInds);
sDt6 = squeeze(logDt6(ind(2),:,:));
%sDt6 = squeeze(dt6(ind,:,:));

% Histogram of voxel entries
dtVals = {'xx','yy','zz','xy','xz','yz'};
figure;
for(ii=1:6)
  subplot(2,3,ii);
  hist(sDt6(ii,:),20);
  title(sprintf('dt %s',dtVals{ii}));
end
% QQ plot of voxel entries
figure;
for(ii=1:6)
  subplot(2,3,ii);
  normplot(sDt6(ii,:));
  title(sprintf('dt %s',dtVals{ii}));
end

% Get the measurement noise error on mean diffusivity
% For FA, a better index of variability might be the beta distribution
binDir = '/biac3/wandell4/data/reading_longitude/dti_y4/mn070907/dti06/bin';
mdStd = niftiRead(fullfile(binDir,'mdStd.nii.gz'));
pddDisp = niftiRead(fullfile(binDir,'pddDispersion.nii.gz'));

AV = std(sDt6(:,:),1,2)'
MV = mdStd.data(s(1),s(2),s(3))*3
MV_pdd = pddDisp.data(s(1),s(2),s(3))./pi.*180
AVcov = cov(sDt6')
AVcor = corrcoef(sDt6')

AVcor_neig = corrcoef([squeeze(sDt6(1,:,:))' squeeze(sDt6(2,:,:))'])

% Compare anatomical variability (AV) with measurement noise (MV).
% In splenium, AV of tensor elements is ~2x MV.

% To Do:
%
% * Anatomical vs. measurement variability maps
%
% * Log vs. non-log- does log make distributions more normal?
%
% * Simulation of the tests, esp. wrt assumptions
%    * rotational invariance assumption violation
%    * normality assumption






