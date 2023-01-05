% set mask parameters
faMaskThresh = 0.15;
b0MaskThresh = [400 800];

% set template pointers
templateDir   = '/biac2/wandell2/data/templates/adult';
templateName  = 'SIRL20adult';
averageDir    = fullfile(templateDir,[templateName,'warp3_averageDataset']);
tensorSumFile = fullfile(averageDir,'tensorSummary.mat');

% locate patient data directory
isPlasticityProject = false;
isControlGroup      = false;

% specify which patient in the group
whichPatient = 1;

% redo spatial normalization or not
doSpatialNormalization = true;

% locate subject dt6 file
if isPlasticityProject
    subjectPatientGroup = {'LCA','RP','Twins','Twins'};
    subjectID  = {'kp051022','dv051117','ls060717','ps060717'};
    subjectDir = '/biac2/wandell/data/Plasticity';
    subjectDt6 = fullfile(subjectDir,subjectPatientGroup{whichPatient},'dti',subjectID{whichPatient},sprintf('%s_dt6',subjectID{whichPatient}));
elseif isControlGroup
    snFiles    = findSubjects(averageDir, '*_sn*',{});
    subjectDt6 = snFiles{whichPatient};
else
    subjectID  = {'mm040325','ms040629','tm040220','wg031210'};
    subjectDir = '/biac2/wandell2/data/DTI_Blind';
    subjectDt6 = fullfile(subjectDir,subjectID{whichPatient},sprintf('%s_dt6',subjectID{whichPatient}));
end

% subjectID  = {'sc060523'};
% subjectDt6 = '/biac2/wandell2/data/reading_longitude/dti_adults/sc060523/sc060523_dt6_60dir';

if doSpatialNormalization

    % % % % % % % % % % % % %
    % SPATIAL NORMALIZATION %
    % % % % % % % % % % % % %

    % t1 template
    t1Template = fullfile(templateDir, [templateName,'_brain.img']);

    % load subject dt6
    dt = load(subjectDt6);

    % set spm defaults
    spm_defaults; global defaults; defaults.analyze.flip = 0;
    params = defaults.normalise.estimate;
    params.smosrc = 4;

    im                     = double(dt.anat.img);
    im                     = im./max(im(:));
    xform                  = dt.anat.xformToAcPc;
    im(~dt.anat.brainMask) = 0;

    t1Sn  = mrAnatComputeSpmSpatialNorm(im, xform, t1Template, params);
    t1Rng = [min(dt.anat.img(:)) max(dt.anat.img(:))];
    t1Dt  = dtiSpmDeformer(dt, t1Sn, 1, [1 1 1]);

    t1Dt.anat.img(t1Dt.anat.img<t1Rng(1)) = t1Rng(1);
    t1Dt.anat.img(t1Dt.anat.img>t1Rng(2)) = t1Rng(2);
    t1Dt.anat.img                         = int16(t1Dt.anat.img+0.5);

    t1Dt.xformToAcPc = t1Dt.anat.xformToAcPc * t1Dt.xformToAnat;

    t1Dt                   = rmfield(t1Dt, 't1NormParams');
    t1Dt.t1NormParams.name = templateName;

    subjectDt6Sn = sprintf('%s_%s',subjectDt6,templateName);

    dtiSaveStruct(t1Dt, subjectDt6Sn);

elseif isControlGroup
    subjectDt6Sn = subjectDt6;
else
    subjectDt6Sn = sprintf('%s_%s',subjectDt6,templateName);
end

% % % % % % % % % % % %
% VOXELWISE ANALYSIS  %
% % % % % % % % % % % %

if exist(tensorSumFile,'file')
    fprintf('Loading control group tensor summary (%s) ... \n',tensorSumFile);
    load(tensorSumFile);
else
    % compute the tensor summary
    % get a list of all subjects in the average directory
    snFiles = findSubjects(averageDir, '*_sn*',{});
    N       = length(snFiles);

    % load dt6 files from each subject
    fprintf('Loading %s ... \n',snFiles{1});
    dt = load(snFiles{1});
    allDt6 = zeros([size(dt.dt6) N]);
    allDt6(:,:,:,:,1) = dt.dt6;
    meanB0 =  double(dt.b0);
    for ii=2:N
        fprintf('Loading %s ... \n',snFiles{ii});
        dt = load(snFiles{ii});
        dt.dt6(isnan(dt.dt6)) = 0;
        allDt6(:,:,:,:,ii) = dt.dt6;
        meanB0 = meanB0 + double(dt.b0);
    end

    % mean B0
    meanB0 = meanB0./N;

    % extract eigenvectors and eigenvalues from the dt6 data
    [eigVec, eigVal] = dtiEig(allDt6);
    eigVal(eigVal<0) = 0;

    % compute fa for mask
    faImg = dtiComputeFA(eigVal);
    faImg = mean(faImg,4);

    % compute mask
    mask = meanB0>b0MaskThresh(1) & meanB0<b0MaskThresh(2) & faImg>faMaskThresh & all(squeeze(allDt6(:,:,:,1,:)),4)>0;

    % convert x,y,z to indices
    allDt6_ind = dtiImgToInd(allDt6, mask);

    % extract eigenvectors and eigenvalues from the dt6 data
    [eigVec, eigVal] = dtiEig(allDt6_ind);
    eigVal(eigVal<0) = 0;

    % compute fa and md group summaries
    [faInd,mdInd] = dtiComputeFA(eigVal);
    fa.mean = mean(faInd,2);
    fa.stdev = std(faInd,0,2);
    fa.n = N;
    md.mean = mean(mdInd,2);
    md.stdev = std(mdInd,0,2);
    md.n = N;
    clear faImg faInd mdInd;

    % log-transform
    eigVal = log(eigVal);
    allDt6_ind = dtiEigComp(eigVec, eigVal);
    clear eigVec eigVal;

    % computer tensor group summary
    [logTensor.mean, logTensor.stdev, logTensor.n] = dtiLogTensorMean(allDt6_ind);
    clear allDt6_ind;

    % notes
    notes.createdOn = datestr(now);
    notes.sourceDataDir = averageDir;
    notes.sourceDataFiles = snFiles;

    % save file
    save(tensorSumFile,'fa','md','logTensor','meanB0','mask','notes');
end

% load template dt6
templateDt6   = load(fullfile(averageDir,'average_dt6'));
xformDtToAcpc = templateDt6.xformToAcPc;

% load subject dt6
subDir  = fileparts(subjectDt6Sn);
ssDt_sn = load(subjectDt6Sn);

% [eigVec,eigVal] = dtiEig(ssDt_sn.dt6);
% ss_fa           = dtiComputeFA(eigVal);

% mask = mask & ssDt_sn.b0>200 & ssDt_sn.b0<450 & ss_fa>0.2 & ssDt_sn.dt6(:,:,:,1)>0;

% create montage of template and subject B0 and mask
figure; imagesc(makeMontage(templateDt6.b0)); axis image; colormap gray;
figure; imagesc(makeMontage(ssDt_sn.b0)); axis image; colormap gray;
figure; imagesc(makeMontage(double(mask))); axis image; colormap gray;

% convert x,y,z to indices
ssDt_sn_ind = dtiImgToInd(ssDt_sn.dt6, mask);

% extract eigenvectors and eigenvalues from the dt6 data
[eigVec,eigVal] = dtiEig(ssDt_sn_ind);

showSlices = [20:60];

% ======= %
% FA test %
% ======= %

% computer subject FA from the eigenvalues
ss_fa = dtiComputeFA(eigVal);

% perform t-test on FA
[faTInd, faDISTR, faDF] = dtiTTest(fa.mean, fa.stdev, fa.n, ss_fa);

% convert test statistics from index format to image format
faTImg  = dtiIndToImg(faTInd, mask, NaN);

% get the threshold t-statistics for 10^-4
faTThresh = tinv(1-10^-4, faDF(1));

% clip extremely large t values to t-statistics corresponding to 10^-12
faTMax = tinv(1-10^-12, faDF(1));
faTImg(abs(faTImg)>faTMax) = faTMax;
faTMax = max(faTImg(:));

% create montage for FA t-test results
figure; imagesc(makeMontage(abs(faTImg),showSlices)); axis image; colormap hot; colorbar;
set(gcf,'Name','FA test'); title(sprintf('t-thresh(p<10^-^4) = %0.1f (no FDR correction)',faTThresh));
dtiWriteNiftiWrapper(abs(faTImg), xformDtToAcpc, fullfile(subDir,['fa_' faDISTR '-test_' num2str(faDF(1)) 'df.nii.gz']));
dtiWriteNiftiWrapper(dtiIndToImg(fa.stdev,mask), xformDtToAcpc, fullfile(subDir,'fa_variance.nii.gz'));
fprintf('dtiFiberUI threshold: %0.3f\n',faTThresh/faTMax);

% ============================================ %
% FDR analysis for FA results (Armin's method) %
% ============================================ %

% set FDR threshold
fdrVal = 0.05;

% quantile transformation
faFdrZ     = norminv(cdf(faDISTR, faTInd, faDF(1), faDF(2)));
faFdrDISTR = 'norm';

faFdrHistogram = fdrHist(faFdrZ,0.2);

% set the weights for fitting FDR null model
faFdrZMax    = prctile(faFdrZ,[10 90]);
faFdrWeights = (faFdrHistogram.x > faFdrZMax(1)) & (faFdrHistogram.x < faFdrZMax(2));

% FDR calculation based on theoretical null
[faFdrParams,faFdrParamsCov,faFdrH0] = fdrEmpNull(faFdrHistogram,faFdrWeights,faFdrDISTR,{'mu','s'});
[faFdrCurveVal,faFdrCurveZ]          = fdrCurveHist('FDR', faFdrH0, 1);
faFdrThreshZ                         = fdrThresh(1, faFdrCurveVal(:,1), faFdrCurveZ, fdrVal);
faFdrThreshT                         = tinv(cdf('norm',faFdrThreshZ,0,1),faDF(1));
fprintf('t-threshold for FDR (Armin''s) of %0.3f: %0.5f\n',fdrVal,faFdrThreshT);
fprintf('FDR adjusted dtiFiberUI threshold: %0.3f\n',faFdrThreshT/faTMax);

% histogram of test stats
figure; set(gcf, 'name', 'Histograms'); hold on;
faEmpiricalDataHistogram   = bar(faFdrHistogram.x, faFdrHistogram.hist, 1, 'w');
faTheoreticalNullHistogram = plot(faFdrH0.x, faFdrH0.yhat, 'b');
hold off; legend(faTheoreticalNullHistogram, 'Theoretical null',1);
xlabel('z-score'); ylabel('voxel count');

% FDR curves
figure;	set(gcf, 'name', 'FDR'); hold on;
plot(faFdrCurveZ, faFdrCurveVal(:,1), 'b');
plot(faFdrCurveZ, faFdrCurveVal(:,2), 'b:', faFdrCurveZ, faFdrCurveVal(:,3), 'b:');
hold off;
xlabel('z-score'); ylabel('FDR');

% ==================================== %
% 'Simple' FDR analysis for FA results %
% ==================================== %

% set FDR method
fdrType = 'original';

faTInd(isnan(faTInd)) = 0;

% convert FA t-statistics to p-values
% this is for two-tailed test
pvals = 1-tcdf(faTInd,faDF(1));

% calculate FDR
[nSignificantTests,indexSignificanceTests] = fdr(pvals,fdrVal,fdrType,'mean');

% convert back to a threshold for t-statistics
faPThreshFDR = max(pvals(indexSignificanceTests));
faTThreshFDR = tinv(1-faPThreshFDR, faDF(1));
fprintf('t-threshold for FDR (%s) of %0.3f: %0.5f\n',fdrType,fdrVal,faTThreshFDR);
fprintf('FDR adjusted dtiFiberUI threshold: %0.3f\n',faTThreshFDR/faTMax);

% ======================= %
% Create significance map %
% ======================= %

% convert p-values to log10 scale
logPImg = dtiIndToImg(-log10(pvals), mask);

% overlay p-value map on t1 images
cmap    = autumn(256);
maxLogP = 10;
minLogP = -log10(faPThreshFDR);

% create rgb version of t1
anatRgb = repmat(mrAnatHistogramClip(double(ssDt_sn.anat.img),0.4,0.98),[1,1,1,3]);

% reslice p-value map to t1 space
tmp = mrAnatResliceSpm(logPImg, inv(ssDt_sn.xformToAcPc), [], ssDt_sn.anat.mmPerVox, [1 1 1 0 0 0]);

% scale the range of p-value map to 0-1
tmp(tmp>maxLogP) = maxLogP;
tmp = (tmp-minLogP)./(maxLogP-minLogP);
overlayMask = tmp>=0;
tmp(~overlayMask) = 0;

% create rgb version of p-value map
overlayMask = repmat(overlayMask,[1 1 1 3]);
overlayRgb = reshape(cmap(round(tmp*255+1),:),[size(tmp) 3]);

% overlay p-value map onto t1
anatRgb(overlayMask) = overlayRgb(overlayMask);

% reorient so that the eyes point up
anatRgb = flipdim(permute(anatRgb,[2 1 3 4]),1);

% add slice labels
sl = [2:2:40];
for ii=1:length(sl), slLabel{ii} = sprintf('Z = %d',sl(ii)); end
slImg = inv(ssDt_sn.anat.xformToAcPc)*[zeros(length(sl),2) sl' ones(length(sl),1)]';
slImg = round(slImg(3,:));
anatOverlay = makeMontage3(anatRgb, slImg, ssDt_sn.anat.mmPerVox(1), 0, slLabel);
mrUtilPrintFigure(fullfile(subDir,sprintf('%s_t1_faSPM',subjectID{whichPatient})));

% create color bar
legendLabels = explode(',',sprintf('%0.1f,',[minLogP:1:maxLogP]));
legendLabels{end} = ['>=' num2str(maxLogP)];
mrUtilMakeColorbar(cmap, legendLabels, '-log10(p)', fullfile(subDir,'faSPM_legend'));

% =========================== %
% logNormal tensor statistics %
% =========================== %

% Log-transform
eigVal(eigVal<0) = 0;
eigVal           = log(eigVal);
ssDt_sn_ind      = dtiEigComp(eigVec, eigVal);

% ================ %
% Eigenvector test %
% ================ %

% Test for eigenvector differences
[eigVecTInd, eigVecDISTR, eigVecDF] = dtiLogTensorTest('vec', logTensor.mean, logTensor.stdev, logTensor.n, ssDt_sn_ind);

% convert test statistics from index format to image format
eigVecTImg = dtiIndToImg(eigVecTInd, mask);

% get the threshold F-statistics for 10^-4
eigVecFThresh = finv(1-10^-4, eigVecDF(1), eigVecDF(2));

% clip extremely large F values to F-statistics corresponding to 10^-12
eigVecFMax = finv(1-10^-12, eigVecDF(1), eigVecDF(2));
eigVecTImg(eigVecTImg>eigVecFMax) = eigVecFMax;
eigVecFMax = max(eigVecTImg(:));

% create montage for eigenvector F-test results
figure; imagesc(makeMontage(eigVecTImg,showSlices)); axis image; colormap hot; colorbar;
set(gcf,'Name','Eigenvector test'); title(sprintf('F-thresh(p<10^-^4) = %0.1f',eigVecFThresh));
dtiWriteNiftiWrapper(eigVecTImg, xformDtToAcpc, fullfile(subDir,['eigvec_' eigVecDISTR '-test_' num2str(eigVecDF(1)) ',' num2str(eigVecDF(2)) 'df.nii.gz']));
dtiWriteNiftiWrapper(dtiIndToImg(logTensor.stdev,mask), xformDtToAcpc, fullfile(subDir,'eigvec_variance.nii.gz'));
fprintf('dtiFiberUI threshold: %0.3f\n',eigVecFThresh/eigVecFMax);

% ========================================================== %
% FDR analysis for Eigenvector test results (Armin's method) %
% ========================================================== %

% set FDR threshold
fdrVal = 0.05;

% quantile transformation
eigVecTInd(isnan(eigVecTInd)) = 0;

eigVecFdrChi2  = chi2inv(cdf(eigVecDISTR, eigVecTInd, eigVecDF(1), eigVecDF(2)),eigVecDF(1));
eigVecFdrDISTR = 'chi2';

eigVecFdrHistogram = fdrHist(eigVecFdrChi2,0.2,1);

% set the weights for fitting FDR null model
eigVecFdrChi2Max = prctile(eigVecFdrChi2,90);
eigVecFdrWeights = (eigVecFdrHistogram.x < eigVecFdrChi2Max);

% FDR calculation based on theoretical null
[eigVecFdrParams,eigVecFdrParamsCov,eigVecFdrH0] = fdrEmpNull(eigVecFdrHistogram,eigVecFdrWeights,eigVecFdrDISTR,{'df','s'},eigVecDF);
[eigVecFdrCurveVal,eigVecFdrCurveChi2]           = fdrCurveHist('FDR', eigVecFdrH0, 1);
eigVecFdrCurvePval                               = 1-cdf('chi2',eigVecFdrCurveChi2,eigVecDF(1));
eigVecFdrThreshChi2                              = fdrThresh(1, eigVecFdrCurveVal(:,1), eigVecFdrCurveChi2, fdrVal);
eigVecFdrThreshPval                              = 1-cdf('chi2',eigVecFdrThreshChi2,eigVecDF(1));
eigVecFdrThreshF                                 = finv(1-eigVecFdrThreshPval,eigVecDF(1),eigVecDF(2));
fprintf('F-threshold for FDR (Armin''s) of %0.3f: %0.5f\n',fdrVal,eigVecFdrThreshF);
fprintf('FDR adjusted dtiFiberUI threshold: %0.3f\n',eigVecFdrThreshF/eigVecFMax);

% histogram of test stats
figure; set(gcf, 'name', 'Histograms'); hold on;
eigVecEmpiricalDataHistogram   = bar(eigVecFdrHistogram.x, eigVecFdrHistogram.hist, 1, 'w');
eigVecTheoreticalNullHistogram = plot(eigVecFdrH0.x, eigVecFdrH0.yhat, 'b');
hold off; legend(eigVecTheoreticalNullHistogram, 'Theoretical null',1);
xlabel('chi-square score'); ylabel('voxel count');

% FDR curves
figure;	set(gcf, 'name', 'FDR'); hold on;
plot(eigVecFdrThreshChi2, eigVecFdrCurveVal(:,1), 'b');
plot(eigVecFdrThreshChi2, eigVecFdrCurveVal(:,2), 'b:', eigVecFdrThreshChi2, eigVecFdrCurveVal(:,3), 'b:');
hold off;
xlabel('chi-square score'); ylabel('FDR');

figure;	set(gcf, 'name', 'FDR'); hold on;
plot(eigVecFdrCurvePval, eigVecFdrCurveVal(:,1), 'b');
plot(eigVecFdrCurvePval, eigVecFdrCurveVal(:,2), 'b:', eigVecFdrCurvePval, eigVecFdrCurveVal(:,3), 'b:');
hold off;
xlabel('p-value'); ylabel('FDR');

% ================================================== %
% 'Simple' FDR analysis for Eigenvector test results %
% ================================================== %

% set FDR method
fdrType = 'general';

eigVecTInd(isnan(eigVecTInd)) = 0;

% convert eigenvector F-statistics to p-values
pvals = 1-fcdf(eigVecTInd,eigVecDF(1),eigVecDF(2));

% calculate FDR
[nSignificantTests,indexSignificanceTests] = fdr(pvals,fdrVal,fdrType,'mean');

% convert back to a threshold for F-statistics
eigVecPThreshFDR = max(pvals(indexSignificanceTests));
eigVecFThreshFDR = finv(1-eigVecPThreshFDR, eigVecDF(1), eigVecDF(2));
fprintf('eigenvector F-threshold for FDR (%s) of %0.3f: %0.5f\n',fdrType,fdrVal,eigVecFThreshFDR);
fprintf('FDR adjusted dtiFiberUI threshold: %0.3f\n',eigVecFThreshFDR/eigVecFMax);

% ======================= %
% Create significance map %
% ======================= %

% convert p-values to log10 scale
logPImg = dtiIndToImg(-log10(pvals), mask);

% overlay p-value map on t1 images
cmap    = autumn(256);
maxLogP = 10;
minLogP = -log10(eigVecPThreshFDR);

% create rgb version of t1
anatRgb = repmat(mrAnatHistogramClip(double(ssDt_sn.anat.img),0.4,0.98),[1,1,1,3]);

% reslice p-value map to t1 space
tmp = mrAnatResliceSpm(logPImg, inv(ssDt_sn.xformToAcPc), [], ssDt_sn.anat.mmPerVox, [1 1 1 0 0 0]);

% scale the range of p-value map to 0-1
tmp(tmp>maxLogP) = maxLogP;
tmp = (tmp-minLogP)./(maxLogP-minLogP);
overlayMask = tmp>=0;
tmp(~overlayMask) = 0;

% create rgb version of p-value map
overlayMask = repmat(overlayMask,[1 1 1 3]);
overlayRgb = reshape(cmap(round(tmp*255+1),:),[size(tmp) 3]);

% overlay p-value map onto t1
anatRgb(overlayMask) = overlayRgb(overlayMask);

% reorient so that the eyes point up
anatRgb = flipdim(permute(anatRgb,[2 1 3 4]),1);

% add slice labels
sl = [2:2:40];
for ii=1:length(sl), slLabel{ii} = sprintf('Z = %d',sl(ii)); end
slImg = inv(ssDt_sn.anat.xformToAcPc)*[zeros(length(sl),2) sl' ones(length(sl),1)]';
slImg = round(slImg(3,:));
anatOverlay = makeMontage3(anatRgb, slImg, ssDt_sn.anat.mmPerVox(1), 0, slLabel);
mrUtilPrintFigure(fullfile(subDir,sprintf('%s_t1_vecSPM',subjectID{whichPatient})));

% create color bar
legendLabels = explode(',',sprintf('%0.1f,',[minLogP:1:maxLogP]));
legendLabels{end} = ['>=' num2str(maxLogP)];
mrUtilMakeColorbar(cmap, legendLabels, '-log10(p)', fullfile(subDir,'vecSPM_legend'));


% =============== %
% Eigenvalue test %
% =============== %

% Test for eigenvalue differences
[eigValTInd, eigValDISTR, eigValDF] = dtiLogTensorTest('val', logTensor.mean, logTensor.stdev, logTensor.n, ssDt_sn_ind);
eigValTInd(ss_fa<0.2) = 0;

% convert test statistics from index format to image format
eigValTImg = dtiIndToImg(eigValTInd, mask);

% get fa map
ss_faImg  = dtiIndToImg(ss_fa, mask, NaN);
figure; imagesc(makeMontage(ss_faImg,showSlices)); axis image; colormap gray;

% get the threshold F-statistics for 10^-4
eigValFThresh = finv(1-10^-4, eigValDF(1), eigValDF(2));

% clip extremely large F values to F-statistics corresponding to 10^-12
eigValFMax = finv(1-10^-12, eigValDF(1), eigValDF(2));
eigValTImg(eigValTImg>eigValFMax) = eigValFMax;
eigValFMax = max(eigValTImg(:));

% create montage for eigenvalue F-test results
figure; imagesc(makeMontage(eigValTImg,showSlices)); axis image; colormap hot; colorbar;
set(gcf,'Name','Eigenvalue test'); title(sprintf('F-thresh(p<10^-^4) = %0.1f',eigValFThresh));
dtiWriteNiftiWrapper(eigValTImg, xformDtToAcpc, fullfile(subDir,['eigval_' eigVecDISTR '-test_' num2str(eigValDF(1)) ',' num2str(eigValDF(2)) 'df.nii.gz']));
dtiWriteNiftiWrapper(dtiIndToImg(logTensor.stdev,mask), xformDtToAcpc, fullfile(subDir,'eigval_variance.nii.gz'));
fprintf('dtiFiberUI threshold: %0.3f\n',eigValFThresh/eigValFMax);

% ========================================================= %
% FDR analysis for Eigenvalue test results (Armin's method) %
% ========================================================= %

% set FDR threshold
fdrVal = 0.05;

% quantile transformation
eigValTInd(isnan(eigValTInd)) = 0;

eigValFdrChi2  = chi2inv(cdf(eigValDISTR, eigValTInd, eigValDF(1), eigValDF(2)),eigValDF(1));
eigValFdrDISTR = 'chi2';

eigValFdrHistogram = fdrHist(eigValFdrChi2,0.2,1);

% set the weights for fitting FDR null model
eigValFdrChi2Max = prctile(eigValFdrChi2,90);
eigValFdrWeights = (eigValFdrHistogram.x < eigValFdrChi2Max);

% FDR calculation based on theoretical null
[eigValFdrParams,eigValFdrParamsCov,eigValFdrH0] = fdrEmpNull(eigValFdrHistogram,eigValFdrWeights,eigValFdrDISTR,{'df','s'},eigValDF);
[eigValFdrCurveVal,eigValFdrCurveChi2]           = fdrCurveHist('FDR', eigValFdrH0, 1);
eigValFdrCurvePval                               = 1-cdf('chi2',eigValFdrCurveChi2,eigValDF(1));
eigValFdrThreshChi2                              = fdrThresh(1, eigValFdrCurveVal(:,1), eigValFdrCurveChi2, fdrVal);
eigValFdrThreshPval                              = 1-cdf('chi2',eigValFdrThreshChi2,eigValDF(1));
eigValFdrThreshF                                 = finv(1-eigValFdrThreshPval,eigValDF(1),eigValDF(2));
fprintf('F-threshold for FDR (Armin''s) of %0.3f: %0.5f\n',fdrVal,eigValFdrThreshF);
fprintf('FDR adjusted dtiFiberUI threshold: %0.3f\n',eigValFdrThreshF/eigValFMax);

% histogram of test stats
figure; set(gcf, 'name', 'Histograms'); hold on;
eigValEmpiricalDataHistogram   = bar(eigValFdrHistogram.x, eigValFdrHistogram.hist, 1, 'w');
eigValTheoreticalNullHistogram = plot(eigValFdrH0.x, eigValFdrH0.yhat, 'b');
hold off; legend(eigValTheoreticalNullHistogram, 'Theoretical null',1);
xlabel('chi-square score'); ylabel('voxel count');

% FDR curves
figure;	set(gcf, 'name', 'FDR'); hold on;
plot(eigValFdrCurveChi2, eigValFdrCurveVal(:,1), 'b');
plot(eigValFdrCurveChi2, eigValFdrCurveVal(:,2), 'b:', eigValFdrCurveChi2, eigValFdrCurveVal(:,3), 'b:');
hold off;
xlabel('chi-square score'); ylabel('FDR');

figure;	set(gcf, 'name', 'FDR'); hold on;
plot(eigValFdrCurvePval, eigValFdrCurveVal(:,1), 'b');
plot(eigValFdrCurvePval, eigValFdrCurveVal(:,2), 'b:', eigValFdrCurvePval, eigValFdrCurveVal(:,3), 'b:');
hold off;
xlabel('p-value'); ylabel('FDR');

% ================================================= %
% 'Simple' FDR analysis for Eigenvalue test results %
% ================================================= %

% set FDR method
fdrType = 'general';

eigValTInd(isnan(eigValTInd)) = 0;

% convert eigenvalue F-statistics to p-values
pvals = 1-fcdf(eigValTInd,eigValDF(1),eigValDF(2));

% calculate FDR
[nSignificantTests,indexSignificanceTests] = fdr(pvals,fdrVal,fdrType,'mean');

% convert back to a threshold for F-statistics
eigValPThreshFDR = max(pvals(indexSignificanceTests));
eigValFThreshFDR = finv(1-eigValPThreshFDR, eigValDF(1), eigValDF(2));
fprintf('eigenvalue F-threshold for FDR (%s) of %0.3f: %0.5f\n',fdrType,fdrVal,eigValFThreshFDR);
fprintf('FDR adjusted dtiFiberUI threshold: %0.3f\n',eigValFThreshFDR/eigValFMax);

% ======================= %
% Create significance map %
% ======================= %

% convert p-values to log10 scale
logPImg = dtiIndToImg(-log10(pvals), mask);

% overlay p-value map on t1 images
cmap    = autumn(256);
maxLogP = 10;
minLogP = -log10(eigValPThreshFDR);

% create rgb version of t1
anatRgb = repmat(mrAnatHistogramClip(double(ssDt_sn.anat.img),0.4,0.98),[1,1,1,3]);

% reslice p-value map to t1 space
tmp = mrAnatResliceSpm(logPImg, inv(ssDt_sn.xformToAcPc), [], ssDt_sn.anat.mmPerVox, [1 1 1 0 0 0]);

% scale the range of p-value map to 0-1
tmp(tmp>maxLogP) = maxLogP;
tmp = (tmp-minLogP)./(maxLogP-minLogP);
overlayMask = tmp>=0;
tmp(~overlayMask) = 0;

% create rgb version of p-value map
overlayMask = repmat(overlayMask,[1 1 1 3]);
overlayRgb = reshape(cmap(round(tmp*255+1),:),[size(tmp) 3]);

% overlay p-value map onto t1
anatRgb(overlayMask) = overlayRgb(overlayMask);

% reorient so that the eyes point up
anatRgb = flipdim(permute(anatRgb,[2 1 3 4]),1);

% add slice labels
sl = [2:2:40];
for ii=1:length(sl), slLabel{ii} = sprintf('Z = %d',sl(ii)); end
slImg = inv(ssDt_sn.anat.xformToAcPc)*[zeros(length(sl),2) sl' ones(length(sl),1)]';
slImg = round(slImg(3,:));
anatOverlay = makeMontage3(anatRgb, slImg, ssDt_sn.anat.mmPerVox(1), 0, slLabel);
mrUtilPrintFigure(fullfile(subDir,sprintf('%s_t1_valSPM',subjectID{whichPatient})));

% create color bar
legendLabels = explode(',',sprintf('%0.1f,',[minLogP:1:maxLogP]));
legendLabels{end} = ['>=' num2str(maxLogP)];
mrUtilMakeColorbar(cmap, legendLabels, '-log10(p)', fullfile(subDir,'valSPM_legend'));
