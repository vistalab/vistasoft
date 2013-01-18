%
% This script is applied to compare a single subject with epilepsy (an
% adult) with the template of comparable adults without epilepsy.  We are
% using the SIRL20 template for the moment.
%
%


%  Does the subject need to be spatially aligned with the template? Usually
%  this is done once for each dti scan.  If you haven't done it, you can
%  get it done here.
doSpatialNorm = false;

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
    % To avoid a memory paging error in windows, we copy the templates to a
    % local directory.
    copyfile(fullfile(templateDir,[templateName '_brain.img']), fullfile(tempdir,[templateName '_brain.img']));
    copyfile(fullfile(templateDir,[templateName '_brain.hdr']), fullfile(tempdir,[templateName '_brain.hdr']));
    copyfile(fullfile(templateDir,[templateName '_EPI.img']), fullfile(tempdir,[templateName '_EPI.img']));
    copyfile(fullfile(templateDir,[templateName '_EPI.hdr']), fullfile(tempdir,[templateName '_EPI.hdr']));
    copyfile(fullfile(templateDir,[templateName 'warp3_averageDataset'],'tensorSummary.mat'), fullfile(tempdir,['tensorSummary.mat']));
    copyfile(fullfile(templateDir,[templateName 'warp3_averageDataset'],'average_dt6.mat'), fullfile(tempdir,['average_dt6.mat']));
    templateDir = tempdir;
    avgdir = templateDir;
else
    dataDir = '/biac2/wandell2/data/Epilepsy';
    templateDir = '/biac2/wandell2/data/templates/adult';
    avgdir = fullfile(templateDir,[templateName 'warp3_averageDataset']);
end

%%% choose or enter single subject directory here
%%%%%%%%%%%%%
%%POST ICTAL

% % first epilepsy patient, AH
subjectDt6 = fullfile(dataDir, '1-ah','ahPI060114','ahPI060114_dt6');

% % second epilepsy patient, HP
% %first dti 
% subjectDt6 = '/biac2/wandell2/data/Epilepsy/2-hp/hpPI060304/hpPI060304-dti1/hpPI060304_dti1_dt6';
% % second dti - s/p seizure in scanner
%subjectDt6 = '/biac2/wandell2/data/Epilepsy/2-hp/hpPI060304/hpPI060304-dti2/hpPI060304_dti2_dt6';

% % third epilepsy patient, SK
% subjectDt6 = '/biac2/wandell2/data/Epilepsy/3-sk/skPI072706/skPI072706_dt6';
 
% % fourth epilepsy patient, JW
 %subjectDt6 = '/biac2/wandell2/data/Epilepsy/4-jw/jwPI073006/jwPI073006_dt6';

%%%%%%%%%%%%%%
%%INTER ICTAL

% % first epilepsy patient, AH
%subjectDt6 = '/biac2/wandell2/data/Epilepsy/1-ah/ahII060116/ahII060116_dt6';

% % second epilepsy patient, HP: two different DTI scans
% subjectDt6 = '/biac2/wandell2/data/Epilepsy/2-hp/hpII060307/hpII060307_dt6';
% subjectDt6 = '/biac2/wandell2/data/Epilepsy/2-hp/hpII060307/hpII060307_axial_dt6';

% % third epilepsy patient, SK - no interictal scan yet
% subjectDt6 = '/biac2/wandell2/data/Epilepsy/3-sk/';

% % fourth epilepsy patient, JW
% subjectDt6 = '/biac2/wandell2/data/Epilepsy/4-jw/jwII080906/jwII080906_dt6';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Needs further definition.
tensorSumFile = fullfile(avgdir,'tensorSummary.mat');


% This normalization operation should be a separate script, we think.  It
% requires SPM2.  It requires comments.
if(doSpatialNorm)
    %% SPATIAL NORMALIZATION
    t1Template = fullfile(templateDir, [templateName '_brain.img']);
    b0Template = fullfile(templateDir, [templateName '_EPI.img']);

    dt = load(subjectDt6);

    % SPM2 section
    spm_defaults; 
    global defaults; defaults.analyze.flip = 0;
    params = defaults.normalise.estimate;
    params.smosrc = 4;

    im = double(dt.anat.img);
    im = im./max(im(:));
    xform = dt.anat.xformToAcPc;
    im(~dt.anat.brainMask) = 0;
    t1Sn = mrAnatComputeSpmSpatialNorm(im, xform, t1Template, params);
    t1Rng = [min(dt.anat.img(:)) max(dt.anat.img(:))];
    t1Dt = dtiSpmDeformer(dt, t1Sn, 1, [1 1 1]);
    t1Dt.anat.img(t1Dt.anat.img<t1Rng(1)) = t1Rng(1);
    t1Dt.anat.img(t1Dt.anat.img>t1Rng(2)) = t1Rng(2);
    t1Dt.anat.img = int16(t1Dt.anat.img+0.5);

    if(b0Norm)
        % If dti data are distored relative to the t1, try warping the B0 to
        % the template B0 and then replace the b0 and dt6 so that everything
        % will be more closely aligned.
        im = double(dt.b0);
        im = im./max(im(:));
        xform = dt.xformToAcPc;
        b0Sn = mrAnatComputeSpmSpatialNorm(im, xform, b0Template, params);
        b0Rng = [min(dt.b0(:)) max(dt.b0(:))];
        b0Dt = dtiSpmDeformer(dt, b0Sn, 1, [1 1 1]);
        b0Dt.b0(b0Dt.b0<b0Rng(1)) = b0Rng(1);
        b0Dt.b0(b0Dt.b0>b0Rng(2)) = b0Rng(2);
        b0Dt.b0 = int16(b0Dt.b0+0.5);
        t1Dt.b0 = b0Dt.b0;
        t1Dt.dt6 = b0Dt.dt6;
    end

    %t1Dt.xformToAcPc = xform;
    t1Dt = rmfield(t1Dt, 't1NormParams');
    t1Dt.t1NormParams.name = templateName;
    subjectDt6 = [subjectDt6 '_' templateName '.mat'];
    dtiSaveStruct(t1Dt, subjectDt6);
else
    % No normalization needed
    subjectDt6 = [subjectDt6 '_' templateName '.mat'];
    disp(['Loading dt6 file (' subjectDt6 ')']);
end


% VOXELWISE ANALYSIS
% We are not sure about the difference between the template, the
% average and the tensor summary.
% We think that the 
if(exist(tensorSumFile,'file'))
    disp(['Loading control group tensor summary (' tensorSumFile ')']);
    load(tensorSumFile);
else
    % compute the tensor summary.  This should be a separate script.
    snFiles = findSubjects(avgdir, '*_sn*',{});
    N = length(snFiles);
    disp(['Loading ' snFiles{1} '...']);
    dt = load(snFiles{1});
    allDt6 = zeros([size(dt.dt6) N]);
    allDt6(:,:,:,:,1) = dt.dt6;
    meanB0 =  double(dt.b0);
    %mask = allDt6(:,:,:,1,1)>0;
    for(ii=2:N)
        disp(['Loading ' snFiles{ii} '...']);
        dt = load(snFiles{ii});
        dt.dt6(isnan(dt.dt6)) = 0;
        allDt6(:,:,:,:,ii) = dt.dt6;
        meanB0 = meanB0 + double(dt.b0);
        %mask = mask & allDt6(:,:,:,1,ii)>0;
    end
    meanB0 = meanB0./N;
    mask = meanB0>250 & all(squeeze(allDt6(:,:,:,1,:)),4)>0;
    allDt6_ind = dtiImgToInd(allDt6, mask);
    [eigVec, eigVal] = dtiEig(allDt6_ind);
    eigVal(eigVal<0) = 0;
    [faImg,mdImg] = dtiComputeFA(eigVal);
    fa.mean = mean(faImg,2);
    fa.stdev = std(faImg,0,2);
    fa.n = N;
    md.mean = mean(mdImg,2);
    md.stdev = std(mdImg,0,2);
    md.n = N;
    clear faImg mdImg;
    eigVal = log(eigVal);
    allDt6_ind = dtiEigComp(eigVec, eigVal);
    clear eigVec eigVal;
    [logTensor.mean, logTensor.stdev, logTensor.n] = dtiLogTensorMean(allDt6_ind);
    clear allDt6_ind;
    notes.createdOn = datestr(now);
    notes.sourceDataDir = avgdir;
    notes.sourceDataFiles = snFiles;
    save(tensorSumFile,'fa','md','logTensor','meanB0','mask','notes');
end

% Load the template information
template = load(fullfile(avgdir,'average_dt6'));
xformDtToAcpc = template.xformToAcPc;

% Directory containing this subject's data
subDir = fileparts(subjectDt6);

% Single subject DTI data, spatially normalized
ssDt_sn = load(subjectDt6);
%mask = mask&ssDt_sn.dt6(:,:,:,1)>0;

%figure; imagesc(makeMontage(template.b0)); axis image; colormap gray;
%figure; imagesc(makeMontage(ssDt_sn.b0)); axis image; colormap gray;

ssDt_ind = dtiImgToInd(ssDt_sn.dt6, mask);
[eigVec, eigVal] = dtiEig(ssDt_ind);

%showSlices = [20:60];
%showSlices = [10:50];
showSlices = [15:62];  % All the brain containing slices

% Compute a test comparing FA in this subject with the atlas. This is done
% by a t-test implemented in dtiTTest.
[ss_fa, ss_md] = dtiComputeFA(eigVal);
[Tfa, DISTR, df] = dtiTTest(fa.mean, fa.stdev, fa.n, ss_fa);
% [Tfa, DISTR, df] = dtiTTest(md.mean, md.stdev, md.n, ss_md);

% Create an image of the results
TfaImg = dtiIndToImg(Tfa, mask, NaN);
tThresh = tinv(1-10^-4, df(1));
tMax = tinv(1-10^-12, df(1));
TfaImg(abs(TfaImg)>tMax) = tMax;
tMax = max(TfaImg(:));

% Perform an FDR analysis for the FA test
%
fdrVal = 0.05;   % This is the p-value we are using.
fdrType = 'general';
Tfa(isnan(Tfa)) = 0;
pvals = 1-tcdf(Tfa, df(1));
[n_signif,index_signif] = fdr(pvals,fdrVal,fdrType,'mean');

% Convert back to an fThreshold.  Needs more comments.  We think that this
% function returns the t-value needed to achieve a significance fdrVal, say
% 0.05 or 0.01.
tThreshFDR = tinv(1-max(pvals(index_signif)), df(1));
disp(sprintf('t-threshold for FDR (%s) of %0.3f: %0.2f (%0.3f).\n',...
    fdrType,fdrVal,tThreshFDR,tThreshFDR/tMax));

% Display FA test.  We need to improve this somehow.  Perhaps we should be
% showing color maps where the FA is significant on top of the template?
figure; imagesc(makeMontage(TfaImg,showSlices)); axis image; colormap cool; colorbar;
set(gcf,'Name','FA test'); title(sprintf('tthresh, no FDR (p<10^-^4) = %0.1f',tThresh));
dtiWriteNiftiWrapper(TfaImg, xformDtToAcpc, fullfile(subDir,['fa_' DISTR '-test_' num2str(df(1)) 'df.nii.gz']));
dtiWriteNiftiWrapper(dtiIndToImg(fa.stdev,mask), xformDtToAcpc, fullfile(subDir,'fa_variance.nii.gz'));

% The next two analyses require log-space tensors.
%
% Log-transform
eigVal(eigVal<0) = 0;
eigVal = log(eigVal);
ssDt_ind = dtiEigComp(eigVec, eigVal);

% Test for eigenvector differences
% [T, DISTR, df] = dtiLogTensorTest('vec', logTensor.mean, logTensor.stdev, logTensor.n, ssDt_ind);
[T, DISTR, df] = dtiLogTensorTest('val', logTensor.mean, logTensor.stdev, logTensor.n, ssDt_ind);

Timg = dtiIndToImg(T, mask);
fThresh = finv(1-10^-4, df(1), df(2));
fMax = finv(1-10^-12, df(1), df(2));
Timg(Timg>fMax) = fMax;
fMax = max(Timg(:));
figure; imagesc(makeMontage(Timg,showSlices)); axis image; colormap hot; colorbar; 
set(gcf,'Name','Vec test'); title(sprintf('fthresh (p<10^-^4) = %0.1f',fThresh));
Simg = dtiIndToImg(logTensor.stdev,mask);
figure; imagesc(makeMontage(Simg,showSlices)); axis image; colormap hot; colorbar; 
set(gcf,'Name','Vec test variance'); 
dtiWriteNiftiWrapper(Timg, xformDtToAcpc, fullfile(subDir,['vec_' DISTR '-test_' num2str(df(1)) ',' num2str(df(2)) 'df.nii.gz']));
dtiWriteNiftiWrapper(Simg, xformDtToAcpc, fullfile(subDir,'vec_variance.nii.gz'));
disp(['dtiFiberUI threshold: ' num2str(fThresh/fMax)]);
% Sqrt(F) is the standardized distance between the groups.
%figure; imagesc(makeMontage(sqrt(Timg),[20:55])); axis image; colormap hot; colorbar; 
%set(gcf,'Name','Vec Standardized Distance');

% Simple FDR analysis for eigenvector differences
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
         
logPimg = dtiIndToImg(-log10(pvals), mask);
cmap = autumn(256);
maxLogP = 10;
minLogP = -log10(pThreshFDR);

anatRgb = repmat(mrAnatHistogramClip(double(ssDt_sn.anat.img),0.4,0.98),[1,1,1,3]);
tmp = mrAnatResliceSpm(logPimg, inv(ssDt_sn.xformToAcPc), [], ssDt_sn.anat.mmPerVox, [1 1 1 0 0 0]);
tmp(tmp>maxLogP) = maxLogP;
tmp = (tmp-minLogP)./(maxLogP-minLogP);
overlayMask = tmp>=0;
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


figure; imagesc(makeMontage(logPimg,showSlices)); axis image; colormap hot; colorbar; 
threshMask = zeros(size(pvals));
threshMask(index_signif) = 1;
threshMask = dtiIndToImg(threshMask, mask);
img = logPimg; img(threshMask<1) = 0;
figure; imagesc(makeMontage(img,showSlices)); axis image; colormap hot; colorbar; 


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
