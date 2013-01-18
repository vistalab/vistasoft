subjectDir = '/biac2/wandell2/data/reading_longitude/templates/child_new/SIRL54warp3';
fileFragment = '*sn*';
[s,subCode] = findSubjects(subjectDir,fileFragment,{'tk040817'});
N = length(s);
tdir = '/silver/scr1/data/templates/child_new';
tname = 'SIRL54';
avgdir = fullfile(tdir,[tname 'warp3']);
template = load(fullfile(avgdir,'average_dt6'));
xformDtToAcpc = template.xformToAcPc;
dtMmPerVox = template.mmPerVox;
avgBrain = template.anat.img;
avgBrain(template.anat.brainMask<0.25) = 0;
avgBrain(template.anat.brainMask<0.5) = avgBrain(template.anat.brainMask<0.5)*.5;
outDir = '/silver/scr1/readingGroupStats/';
if(~exist(outDir,'dir')) mkdir(outDir); end

[behData,colNames] = dtiGetBehavioralData(subCode);
readerType = strmatch('Type of Reader',colNames);
pr = find(behData(:,readerType)==-1);
gr = find(behData(:,readerType)==1);
npr = length(pr);
ngr = length(gr);

dt = load(s{pr(1)});
prDt6 = zeros([size(dt.dt6) npr]);
prDt6(:,:,:,:,1) = dt.dt6;
mnB0 =  double(dt.b0);
for(ii=2:npr)
  disp(['Loading ' s{pr(ii)} '...']);
  dt = load(s{pr(ii)});
  dt.dt6(isnan(dt.dt6)) = 0;
  prDt6(:,:,:,:,ii) = dt.dt6;
  mnB0 = mnB0 + double(dt.b0);
end
grDt6 = zeros([size(dt.dt6) ngr]);
for(ii=1:ngr)
  disp(['Loading ' s{gr(ii)} '...']);
  dt = load(s{gr(ii)});
  dt.dt6(isnan(dt.dt6)) = 0;
  grDt6(:,:,:,:,ii) = dt.dt6;
  mnB0 = mnB0 + double(dt.b0);
end
mnB0 = mnB0./(npr+ngr);
mask = mnB0>250 & all(squeeze(prDt6(:,:,:,1,:)),4)>0 & all(squeeze(grDt6(:,:,:,1,:)),4)>0;
prDt6_ind = dtiImgToInd(prDt6, mask);
clear prDt6;
grDt6_ind = dtiImgToInd(grDt6, mask);
clear grDt6;
% convert to log tensors
[prVec, prVal] = dtiEig(prDt6_ind);
prVal(prVal<0) = 0;
prLogDt6_ind = dtiEigComp(prVec, log(prVal));
[grVec, grVal] = dtiEig(grDt6_ind);
grVal(grVal<0) = 0;
grLogDt6_ind = dtiEigComp(grVec, log(grVal));

showSlices = [20:60];

% Watson test for principal eigenvector difference
[prDir.mean, prDir.stdev, prDir.n, prDir.sbar] = dtiDirMean(squeeze(prVec(:,:,1,:)));
[grDir.mean, grDir.stdev, grDir.n, grDir.sbar] = dtiDirMean(squeeze(grVec(:,:,1,:)));
[T, DISTR, df] = dtiDirTest(prDir.sbar, prDir.n, grDir.sbar, grDir.n);
Timg = dtiIndToImg(T, mask);
fThresh = finv(1-10^-4, df(1), df(2));
fMax = finv(1-10^-12, df(1), df(2));
Timg(Timg>fMax) = fMax;
fMax = max(Timg(:));
figure; imagesc(makeMontage(Timg,showSlices)); axis image; colormap hot; colorbar; 
set(gcf,'Name','Dir test'); title(sprintf('fthresh (p<10^-^4) = %0.1f',fThresh));
dtiWriteNiftiWrapper(Timg, xformDtToAcpc, fullfile(outDir,['dir_' DISTR '-test_' num2str(df(1)) ',' num2str(df(2)) 'df.nii.gz']));

% Simple FDR analysis for Watson test
%
fdrVal = 0.10; fdrType = 'original';
T(isnan(T)) = 0;
pvals = 1-fcdf(T, df(1), df(2));
[n_signif,index_signif] = fdr(pvals,fdrVal,fdrType,'mean');
pThreshFDR = max(pvals(index_signif));
% Convert back to an fThreshold
fThreshFDR = finv(1-pThreshFDR, df(1), df(2));
disp(sprintf('f-threshold for FDR (%s method) of %0.3f: %0.2f (%0.3f).\n',...
             fdrType,fdrVal,fThreshFDR,fThreshFDR/fMax));
logPimg = dtiIndToImg(-log10(pvals), mask);
cmap = autumn(256);
maxLogP = 10;
%minLogP = -log10(pThreshFDR);
minLogP = -log10(0.01);
sl = [-20:2:50];

mrAnatOverlayMontage(logPimg, xformDtToAcpc, avgBrain, template.anat.mmPerVox, cmap, [minLogP maxLogP], sl);


% Log-normal tensor tests
%
% Test for eigenvector differences
[prLogDt.mean, prLogDt.stdev, prLogDt.n] = dtiLogTensorMean(prLogDt6_ind);
[grLogDt.mean, grLogDt.stdev, grLogDt.n] = dtiLogTensorMean(grLogDt6_ind);

[T, DISTR, df] = dtiLogTensorTest('vec', prLogDt.mean, prLogDt.stdev, prLogDt.n, grLogDt.mean, grLogDt.stdev, grLogDt.n);

Timg = dtiIndToImg(T, mask);
fThresh = finv(1-10^-4, df(1), df(2));
fMax = finv(1-10^-12, df(1), df(2));
Timg(Timg>fMax) = fMax;
dtiWriteNiftiWrapper(Timg, xformDtToAcpc, fullfile(outDir,['vec_' DISTR '-test_' num2str(df(1)) ',' num2str(df(2)) 'df.nii.gz']));

% Sqrt(F) is the standardized distance between the groups.
%figure; imagesc(makeMontage(sqrt(Timg),[20:55])); axis image; colormap hot; colorbar; 
%set(gcf,'Name','Vec Standardized Distance');

% Simple FDR analysis for eigenvector differences
%
fdrVal = 0.05; fdrType = 'original';
T(isnan(T)) = 0;
pvals = 1-fcdf(T, df(1), df(2));
[n_signif,index_signif] = fdr(pvals,fdrVal,fdrType,'mean');
%pThreshFDR = max(pvals(index_signif));
% Convert back to an fThreshold
%fThreshFDR = finv(1-pThreshFDR, df(1), df(2));
%disp(sprintf('f-threshold for FDR (%s method) of %0.3f: %0.2f (%0.3f).\n',...
%             fdrType,fdrVal,fThreshFDR,fThreshFDR/fMax));

logPimg = dtiIndToImg(-log10(pvals), mask);
cmap = autumn(256);
maxLogP = 10;
%minLogP = -log10(pThreshFDR);
minLogP = -log10(0.01);
mrAnatOverlayMontage(logPimg, xformDtToAcpc, avgBrain, template.anat.mmPerVox, cmap, [minLogP maxLogP], sl);

% Test for eigenvalue differences
%
[T, DISTR, df] = dtiLogTensorTest('val', prLogDt.mean, prLogDt.stdev, prLogDt.n, grLogDt.mean, grLogDt.stdev, grLogDt.n);

T(isnan(T)) = 0;
pvals = 1-fcdf(T, df(1), df(2));
[n_signif,index_signif] = fdr(pvals,fdrVal,fdrType,'mean');
pThreshFDR = max(pvals(index_signif));
% Convert back to an fThreshold
fThreshFDR = finv(1-pThreshFDR, df(1), df(2));
disp(sprintf('f-threshold for FDR (%s method) of %0.3f: %0.2f (%0.3f).\n',...
             fdrType,fdrVal,fThreshFDR,fThreshFDR/fMax));
Timg = dtiIndToImg(T, mask);
fMax = finv(1-10^-12, df(1), df(2));
Timg(Timg>fMax) = fMax;
dtiWriteNiftiWrapper(Timg, xformDtToAcpc, fullfile(outDir,['val_' DISTR '-test_' num2str(df(1)) ',' num2str(df(2)) 'df.nii.gz']));
logPimg = dtiIndToImg(-log10(pvals), mask);
cmap = autumn(256);
maxLogP = 10;
minLogP = -log10(pThreshFDR);
%minLogP = -log10(0.001);
mrAnatOverlayMontage(logPimg, xformDtToAcpc, avgBrain, template.anat.mmPerVox, cmap, [minLogP maxLogP], sl);
