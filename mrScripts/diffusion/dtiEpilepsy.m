% dtiEpilepsy
%
% This script is applied to compare a single subject with epilepsy (an
% adult) with the template of comparable adults without epilepsy.  We are
% using the SIRL20 template for the moment.
%
% To run this script you will need the statistics toolbox on your path.
% This toolbox is part of our normal lab Matlab and it is part of the Unix
% side.  We don't have it yet for license 11723 version.  We should get it.
% 

% Specify and load the subject data and the atlas data
%
%  Does the subject need to be spatially aligned with the template? Usually
%  this is done once for each dti scan.  If you haven't done it, you can
%  get it done here.
doSpatialNorm = true;

% Is there a warping needed for the B0 field?  Radiation necrosis needed
% this, but normally we don't.  See paragraph below.  The b0Norm is only
% invoked during the doSpatialNorm operation.
b0Norm = false;

% There are several possible templates.  They should be listed here.
templateName = 'SIRL20adult';

% Set up the files and directories.  We have had trouble reading across the
% network from time to time.  So on PCs, we copy the key files locally.  On
% Linux boxes, everything works in place.
if(ispc)
    dataDir = '\\white.stanford.edu\biac2-wandell2\data\Epilepsy';
    templateDir = '\\white.stanford.edu\biac2-wandell2\data\templates\adult';   
else
    dataDir = '/biac2/wandell2/data/Epilepsy';
    templateDir = '/biac2/wandell2/data/templates/adult';
end
avgdir = fullfile(templateDir,[templateName 'warp3_averageDataset']);
% Full path to the file
%subjectDt6 = epiSubjectFile(dataDir, 1,'postictal');   
subjectDt6 = epiSubjectFile(dataDir, 1,'control');   

% This normalization operation should be a integrated script, we think.  It
% requires SPM2.  It requires comments.
if(doSpatialNorm)
    if(ispc)
        % To avoid a memory paging error in windows, we copy the templates to a
        % local directory.
        copyfile(fullfile(templateDir,[templateName '_brain.img']), fullfile(tempdir,[templateName '_brain.img']));
        copyfile(fullfile(templateDir,[templateName '_brain.hdr']), fullfile(tempdir,[templateName '_brain.hdr']));
        copyfile(fullfile(templateDir,[templateName '_EPI.img']), fullfile(tempdir,[templateName '_EPI.img']));
        copyfile(fullfile(templateDir,[templateName '_EPI.hdr']), fullfile(tempdir,[templateName '_EPI.hdr']));
        copyfile(fullfile(templateDir,[templateName 'warp3_averageDataset'],'tensorSummary.mat'), fullfile(tempdir,['tensorSummary.mat']));
        copyfile(fullfile(templateDir,[templateName 'warp3_averageDataset'],'average_dt6.mat'), fullfile(tempdir,['average_dt6.mat']));

        % On the PC, we put all the files in one directory, the temp
        % directory for this user.
        templateDir = tempdir;
        avgdir = templateDir;
    end
    dtiSpatialNormalize;
else
    % No normalization needed
    subjectDt6 = [subjectDt6 '_' templateName '.mat'];
end

% Needs further definition.
tensorSumFile = fullfile(avgdir,'tensorSummary.mat');

% VOXELWISE ANALYSIS
% We are not sure about the difference between the template, the
% average and the tensor summary.
% We think that the 
if(exist(tensorSumFile,'file'))
    disp(['Loading control group tensor summary (' tensorSumFile ')']);
    % This loads various summary structures such as md, fa, logTensor,
    % meanB0 and notes.
    load(tensorSumFile);
else
    % Compute the tensor summary.  
    dtiTensorSummary;
end

% Load the atlas information
template = load(fullfile(avgdir,'average_dt6'));
xformDtToAcpc = template.xformToAcPc;

% Directory containing this subject's data
subDir = fileparts(subjectDt6);

% Single subject DTI data, spatially normalized
disp(['Loading dt6 file (' subjectDt6 ')']);
ssDt_sn = load(subjectDt6);
%mask = mask&ssDt_sn.dt6(:,:,:,1)>0;

%figure; imagesc(makeMontage(template.b0)); axis image; colormap gray;
%figure; imagesc(makeMontage(ssDt_sn.b0)); axis image; colormap gray;

%------------------------
% At this point the atlas data and the subject are loaded.
% We begin statistical analysis.  We begin with FA and MD analyses in this
% section. Then we move on to the full tensor analyses in the following
% section.

% The mask is the valid data mask computed  within dtiTensorSummary.
ssDt_ind = dtiImgToInd(ssDt_sn.dt6, mask);
[eigVec, eigVal] = dtiEig(ssDt_ind);

% Compute a test comparing FA in this subject with the atlas. This is done
% by a t-test implemented in dtiTTest.
[ss_fa, ss_md]   = dtiComputeFA(eigVal);

% Create the T-test images and related data for FA
[Tfa, DISTR, df] = dtiTTest(fa.mean, fa.stdev, fa.n, ss_fa);
[TfaImg, tFDRfa, n_signif,index_signif, pvals] = dtiTTestImage(Tfa, DISTR, df, mask);

% showSlices = [15:62]; 
% figure; imagesc(makeMontage(TfaImg,showSlices)); axis image; colormap cool; colorbar;
% set(gcf,'Name','FA test'); title(sprintf('tthresh, no FDR (p<10^-^4) = %0.1f',tThresh));

% Save out images that can be viewed in dtiFiberUI
dtiWriteNiftiWrapper(TfaImg, xformDtToAcpc, fullfile(subDir,['fa_' DISTR '-test_' num2str(df(1)) 'df.nii.gz']));
dtiWriteNiftiWrapper(-1*TfaImg, xformDtToAcpc, fullfile(subDir,['negfa_' DISTR '-test_' num2str(df(1)) 'df.nii.gz']));
dtiWriteNiftiWrapper(dtiIndToImg(fa.stdev,mask), xformDtToAcpc, fullfile(subDir,'fa_variance.nii.gz'));

% Repeat the process for mean diffusivity
[Tmd, DISTR, df] = dtiTTest(md.mean, md.stdev, md.n, ss_md);
[TmdImg, tFDRmd, n_signif,index_signif, pvals] = dtiTTestImage(Tmd, DISTR, df, mask);

% showSlices = [15:62]; 
% figure; imagesc(makeMontage(TmdImg,showSlices)); axis image; colormap cool; colorbar;
% set(gcf,'Name','MD test'); title(sprintf('tthresh, no FDR (p<10^-^4) = %0.1f',tThresh));

% Save out images that can be viewed in dtiFiberUI.  Until we fix the
% dtiFiberUI, we can't really select out the negative values.  So we write
% the data out both positive and negative for the moment.  We need to
% amend dtiFiberUI so that it 
dtiWriteNiftiWrapper(TmdImg, xformDtToAcpc, fullfile(subDir,['md_' DISTR '-test_' num2str(df(1)) 'df.nii.gz']));
dtiWriteNiftiWrapper(-1*TmdImg, xformDtToAcpc, fullfile(subDir,['negmd_' DISTR '-test_' num2str(df(1)) 'df.nii.gz']));
dtiWriteNiftiWrapper(dtiIndToImg(md.stdev,mask), xformDtToAcpc, fullfile(subDir,'md_variance.nii.gz'));

% To view the locations of the significantly different voxels, use
% dtiFiberUI.  Load the file, say, fa_t-test_19df.nii.gz as a NIFTI image
% overlay into the program.  You can adjust the cutoff in the user
% interface.  You can use, say, the fdr threshold (tFDRxx) as the p < 0.05
% cutoff.

% clear TmdImg TfaImg Tmd Tfa

%--------------------------------------
% The next two analyses require log-space tensors.

% Log-transform the single subject data
eigVal(eigVal<0) = 0;
eigVal = log(eigVal);
ssDt_ind = dtiEigComp(eigVec, eigVal);

% Test for VECTOR differences
[T, DISTR, df] = dtiLogTensorTest('vec', logTensor.mean, logTensor.stdev, logTensor.n, ssDt_ind);

Timg = dtiIndToImg(T, mask);
fThresh = finv(1-10^-4, df(1), df(2));
fMax = finv(1-10^-12, df(1), df(2));
Timg(Timg>fMax) = fMax;
fMax = max(Timg(:));
Simg = dtiIndToImg(logTensor.stdev,mask);

% figure; imagesc(makeMontage(Timg,showSlices)); axis image; colormap hot; colorbar; 
% set(gcf,'Name','Vec test'); title(sprintf('fthresh (p<10^-^4) = %0.1f',fThresh));
%
% figure; imagesc(makeMontage(Simg,showSlices)); axis image; colormap hot; colorbar; 
% set(gcf,'Name','Vec test variance'); 

%
dtiWriteNiftiWrapper(Timg, xformDtToAcpc, fullfile(subDir,['vec_' DISTR '-test_' num2str(df(1)) ',' num2str(df(2)) 'df.nii.gz']));
dtiWriteNiftiWrapper(Simg, xformDtToAcpc, fullfile(subDir,'vec_variance.nii.gz'));
disp(['dtiFiberUI threshold: ' num2str(fThresh/fMax)]);

% Test for VALUE differences
[T, DISTR, df] = dtiLogTensorTest('val', logTensor.mean, logTensor.stdev, logTensor.n, ssDt_ind);

Timg = dtiIndToImg(T, mask);
fThresh = finv(1-10^-4, df(1), df(2));
fMax = finv(1-10^-12, df(1), df(2));
Timg(Timg>fMax) = fMax;
fMax = max(Timg(:));
Simg = dtiIndToImg(logTensor.stdev,mask);

% figure; imagesc(makeMontage(Timg,showSlices)); axis image; colormap hot; colorbar; 
% set(gcf,'Name','Values test'); title(sprintf('fthresh (p<10^-^4) = %0.1f',fThresh));
%
% figure; imagesc(makeMontage(Simg,showSlices)); axis image; colormap hot; colorbar; 
% set(gcf,'Name','Values test variance'); 

%
dtiWriteNiftiWrapper(Timg, xformDtToAcpc, fullfile(subDir,['val_' DISTR '-test_' num2str(df(1)) ',' num2str(df(2)) 'df.nii.gz']));
dtiWriteNiftiWrapper(Simg, xformDtToAcpc, fullfile(subDir,'val_variance.nii.gz'));
disp(['dtiFiberUI threshold: ' num2str(fThresh/fMax)]);

% figure; imagesc(makeMontage(sqrt(Timg),[20:55])); axis image; colormap hot; colorbar; 
% set(gcf,'Name','Vec Standardized Distance');

% Possible to test for 'full' also.  Need more comments in dtiLogTensorTest

% FDR analysis for eigenvector differences
%
% Sqrt(F) is the standardized distance between the groups.  Ask about this.
%
fdrVal = 0.05; fdrType = 'general';
T(isnan(T)) = 0;
pvals = 1-fcdf(T, df(1), df(2));
[n_signif,index_signif] = fdr(pvals,fdrVal,fdrType,'mean');
disp(n_signif);max(pvals(index_signif))

% Convert back to an fThreshold
pThreshFDR = max(pvals(index_signif));
fThreshFDR = finv(1-pThreshFDR, df(1), df(2));
disp(sprintf('f-threshold for FDR (%s method) of %0.3f: %0.2f (%0.3f).\n',...
    fdrType,fdrVal,fThreshFDR,fThreshFDR/fMax));


%---- Make locally viewable versions of the images ----
%
logPimg = dtiIndToImg(-log10(pvals), mask);
cmap = autumn(256); maxLogP = 10; minLogP = -log10(pThreshFDR);

anatRgb = repmat(mrAnatHistogramClip(double(ssDt_sn.anat.img),0.4,0.98),[1,1,1,3]);
tmp = mrAnatResliceSpm(logPimg, inv(ssDt_sn.xformToAcPc), [], ssDt_sn.anat.mmPerVox, [1 1 1 0 0 0]);
tmp(tmp>maxLogP) = maxLogP;
tmp = (tmp-minLogP)./(maxLogP-minLogP);
overlayMask = (tmp>=0);
tmp(~overlayMask) = 0;
overlayMask = repmat(overlayMask,[1 1 1 3]);
overlayRgb = reshape(cmap(round(tmp*255+1),:),[size(tmp) 3]);
anatRgb(overlayMask) = overlayRgb(overlayMask);

% reorient so that the eyes point up
anatRgb = flipdim(permute(anatRgb,[2 1 3 4]),1);
%sl = [2:2:40];
sl = [-36:2:60];
for(ii=1:length(sl)) slLabel{ii} = sprintf('Z = %d',sl(ii)); end
slImg = inv(ssDt_sn.anat.xformToAcPc)*[zeros(length(sl),2) sl' ones(length(sl),1)]';
slImg = round(slImg(3,:));
anatOverlay = makeMontage3(anatRgb, slImg, ssDt_sn.anat.mmPerVox(1), 0, slLabel);
mrUtilPrintFigure(fullfile(subDir,'ss_t1_vecSPM'));
legendLabels = explode(',',sprintf('%0.1f,',[minLogP:1:maxLogP]));
legendLabels{end} = ['>=' num2str(maxLogP)];
mrUtilMakeColorbar(cmap, legendLabels, '-log10(p)', fullfile(subDir,'vecSPM_legend'));

templateBrain = template.anat.img;
templateBrain(template.anat.brainMask<0.25) = 0;
templateBrain(template.anat.brainMask<0.5) = templateBrain(template.anat.brainMask<0.5)*.5;
avgRgb = repmat(templateBrain,[1,1,1,3]);
avgRgb(overlayMask) = overlayRgb(overlayMask);

% reorient so that the eyes point up
avgRgb = flipdim(permute(avgRgb,[2 1 3 4]),1);
avgOverlay = makeMontage3(avgRgb, slImg, ssDt_sn.anat.mmPerVox(1), 0, slLabel);


slImg = inv(ssDt_sn.xformToAcPc)*[zeros(length(sl),2) sl' ones(length(sl),1)]';
slImg = round(slImg(3,:));
overlayRgb = flipdim(permute(overlayRgb,[2 1 3 4]),1);
overlay = makeMontage3(overlayRgb, slImg, [], 2);

% figure; imagesc(makeMontage(logPimg,showSlices)); axis image; colormap hot; colorbar;
threshMask = zeros(size(pvals));
threshMask(index_signif) = 1;
threshMask = dtiIndToImg(threshMask, mask);
img = logPimg; img(threshMask<1) = 0;
%  figure; imagesc(makeMontage(img,showSlices)); axis image; colormap hot; colorbar;


%%%END HERE%%%


%--------------------------------------------------------------------
% FDR Analysis

% Quantile transformation
Tchisq = chi2inv(cdf(DISTR, T, df(1), df(2)), df(1));
DISTR = 'chi2';
% Histograms
H = fdrHist(Tchisq,0.2,1);

% Empirical null
Tmax = prctile(Tchisq,90);
w = (H.x < Tmax);
[params, paramsCov, H0hat] = fdrEmpNull(H, w, DISTR, {}, df);
[p0, s0, df0] = deal(params(1), params(2), params(3));
paramsConf = [[log(p0), s0, df0] + 1.95*sqrt(diag(paramsCov))';
    [log(p0), s0, df0] - 1.95*sqrt(diag(paramsCov))'];

% p0 adjustment for theoretical null
[params, paramsCov, H0] = fdrEmpNull(H, w, DISTR, {'df','s'}, df);
p0H0 = params(1);

% FDR curves
[fdrH0, t] = fdrCurveHist('FDR', H0, 1);
[fdrH0hat, t] = fdrCurveHist('FDR', H0hat, 1);

% Threshold
thr = fdrThresh(1, fdrH0(:,1), t, level);
thr = fdrThresh(1, fdrH0hat(:,1), t, level);


%-----------------------------------------------------------------------
% FDR Plots

% Histogram of test stats
figure, set(gcf, 'name', 'Histograms'), hold on
h = bar(H.x, H.hist, 1, 'w');
h0 = plot(H0.x, H0.yhat, 'b');
h1 = plot(H0hat.x, H0hat.yhat, 'r');
hold off, legend([h0 h1], 'theo null','emp null',1)
xlabel('T'); ylabel('voxel count');
a=axis; axis([0 prctile(T,99) a(3:4)]);

% FDR curves
figure,	set(gcf, 'name', 'FDR'), hold on
plot(t, fdrH0(:,1), 'b')
plot(t, fdrH0hat(:,1), 'r')
legend('theo null','emp null')
plot(t, fdrH0(:,2), 'b:', t, fdrH0(:,3), 'b:')
plot(t, fdrH0hat(:,2), 'r:', t, fdrH0hat(:,3), 'r:')
hold off, axis([0 prctile(Tchisq,99.99) 0 1]);
xlabel('threshold'); ylabel('FDR');

pthresh = 1-chi2cdf(t,df(1));
figure;plot(log10(pthresh), fdrH0(:,1), 'b')
xlabel('log10(p-value)'); ylabel('FDR');


% Test for eigenvalue differences
[T, M, S, DISTR, df] = dtiLogTensorTest(1, [2:size(allDt6_ind,3)], allDt6_ind, 'val');
Timg = dtiIndToImg(T, mask);
fThresh = finv(1-10^-4, df(1), df(2));
fMax = finv(1-10^-12, df(1), df(2));
Timg(Timg>fMax) = fMax;
fMax = max(Timg(:));
figure; imagesc(makeMontage(Timg,[20:55])); axis image; colormap hot; colorbar;
set(gcf,'Name','Val test'); title(sprintf('fthresh (p<10^-^4) = %0.1f',fThresh));
dtiWriteNiftiWrapper(Timg, xformDtToAcpc, fullfile(subDir,['val_' DISTR '-test_' num2str(df(1)) ',' num2str(df(2)) 'df.nii.gz']));
dtiWriteNiftiWrapper(dtiIndToImg(S,mask), xformDtToAcpc, fullfile(subDir,'val_variance.nii.gz'));
