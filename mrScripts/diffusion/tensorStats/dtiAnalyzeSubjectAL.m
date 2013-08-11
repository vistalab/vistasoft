
% subjectDt6 = '/biac2/wandell2/data/reading_longitude/dti/mn041014/mn041014_dt6'; 
% youngest female subject, included in template (age 7)
% subjectDt6 = '/biac2/wandell2/data/reading_longitude/dti_adults/pp050208/pp050208_dt6';
% youngest female adult (age 23)
% subjectDt6 = '/biac2/wandell2/data/reading_longitude/dti_adults/mz040828/mz040828_dt6'; 
% youngest adult (age 19, male), shows differences to group
% subjectDt6 ='/biac2/wandell2/data/reading_longitude/dti_adults/gm050308/gm050308_dt6';
% next youngest male adult after MZ (age 23)
% subjectDt6 = '/biac2/wandell2/data/reading_longitude/dti/hy040602/hy040602_dt6'
% oldest child subject, included in template (age 12, female)

subjectDt6 = '/biac1/wandell/data/radiationNecrosis/dti/al060406_sn2/al060406_dt6_fatSat';
% radiation necrosis patient

tdir = '/biac3/wandell4/data/reading_longitude/templates/child/';
tname = 'SIRL54';
avgdir = fullfile(tdir,[tname 'warp3']);
inclusionCriteria={}; % try {'Sex','==0';'Basic reading','>=95'}
sumFileSuffix = '';
tensorSumFile = fullfile(avgdir,['tensorSummary' sumFileSuffix '.mat']);
doSpatialNorm = false;

if(doSpatialNorm)
    %% SPATIAL NORMALIZATION
    t1Template = fullfile(tdir, [tname '_brain.img']);
    b0Template = fullfile(tdir, [tname '_EPI.img']);

    dt = load(subjectDt6);

    spm_defaults; global defaults; defaults.analyze.flip = 0;
    params = defaults.normalise.estimate;
    params.smosrc = 4;

    im = double(dt.anat.img);
    im = im./max(im(:));
    im(~dt.anat.brainMask) = 0;
    t1Sn = mrAnatComputeSpmSpatialNorm(im, dt.anat.xformToAcPc, t1Template, params);
    t1Rng = [min(dt.anat.img(:)) max(dt.anat.img(:))];
    t1Dt = dtiSpmDeformer(dt, t1Sn, 1, [1 1 1]);
    t1Dt.anat.img(t1Dt.anat.img<t1Rng(1)) = t1Rng(1);
    t1Dt.anat.img(t1Dt.anat.img>t1Rng(2)) = t1Rng(2);
    t1Dt.anat.img = int16(t1Dt.anat.img+0.5);

    if(doB0Norm)
        % The dti data are quite distored from the titanium vertebrae fusion plate
        % in this subject's neck. So, we warp the B0 to the template B0 and then
        % replace the b0 and dt6 so that everything will be more closely aligned.
        im = double(dt.b0);
        im = im./max(im(:));
        b0Sn = mrAnatComputeSpmSpatialNorm(im, dt.xformToAcPc, b0Template, params);
        b0Rng = [min(dt.b0(:)) max(dt.b0(:))];
        b0Dt = dtiSpmDeformer(dt, b0Sn, 1, [1 1 1]);
        b0Dt.b0(b0Dt.b0<b0Rng(1)) = b0Rng(1);
        b0Dt.b0(b0Dt.b0>b0Rng(2)) = b0Rng(2);
        b0Dt.b0 = int16(b0Dt.b0+0.5);

        t1Dt.b0 = b0Dt.b0;
        t1Dt.dt6 = b0Dt.dt6;
    end
    
    t1Dt.b0 = int16(round(t1Dt.b0));
    %t1Dt.xformToAcPc = dt.xformToAcPc;
    t1Dt = rmfield(t1Dt, {'t1NormParams','xformToMrVista'});
    t1Dt.t1NormParams.name = tname;
    subjectDt6 = [subjectDt6 '_' tname '.mat'];
    dtiSaveStruct(t1Dt, subjectDt6);
else
    subjectDt6 = [subjectDt6 '_' tname '.mat'];
end

%% VOXELWISE ANALYSIS
%
if(exist(tensorSumFile,'file'))
    disp(['Loading control group tensor summary (' tensorSumFile ')']);
    load(tensorSumFile);
else
    % compute the tensor summary
    [snFiles,sc] = findSubjects(avgdir, '*_sn*',{});
    [bd, colNames] = dtiGetBehavioralData(sc,'/biac3/wandell4/data/reading_longitude/read_behav_measures.csv');
    if(~isempty(inclusionCriteria))
        str = 'subs=';
        for(ii=1:size(inclusionCriteria,1))
            col = strmatch(inclusionCriteria{ii,1},colNames);
            str = [str 'bd(:,' num2str(col) ')' inclusionCriteria{ii,2} ' & '];
        end
        str = str(1:end-3);
        eval([str ';']);
        fprintf('Inclusion criteria "%s" included %d of %d subjects.\n',str,sum(subs),length(subs));
    else
        subs = ones(size(sc));
    end
    snFiles = snFiles(subs);
    sc = sc(subs);
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
    mask = meanB0>300 & all(squeeze(allDt6(:,:,:,1,:)),4)>0;
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
    [logTensor.mean, logTensor.stdev, logTensor.n] = dtiLogTensorMeanOrig(allDt6_ind);
    clear allDt6_ind;
    notes.createdOn = datestr(now);
    notes.sourceDataDir = avgdir;
    notes.sourceDataFiles = snFiles;
    save(tensorSumFile,'fa','md','logTensor','meanB0','mask','notes','snFiles','sc','inclusionCriteria');
end

template = load(fullfile(avgdir,'average_dt6'));
xformDtToAcpc = template.xformToAcPc;

subDir = fileparts(subjectDt6);
ssDt_sn = load(subjectDt6);
%mask = mask&ssDt_sn.dt6(:,:,:,1)>0;

%figure; imagesc(makeMontage(template.b0)); axis image; colormap gray;
%figure; imagesc(makeMontage(ssDt_sn.b0)); axis image; colormap gray;

ssDt_ind = dtiImgToInd(ssDt_sn.dt6, mask);
[eigVec, eigVal] = dtiEig(ssDt_ind);

showSlices = [20:60];

outDir = fullfile(subDir,['analysis' sumFileSuffix '_' datestr(now,'yyyymmdd')]);
if(~exist(outDir,'dir')) mkdir(outDir); end
logFile = fopen(fullfile(outDir,'log.txt'),'w');

%%%%%%%%%%%%%
% FA test
%%%%%%%%%%%%%
ss_fa = dtiComputeFA(eigVal);
[Tfa, DISTR, df] = dtiTTest(fa.mean, fa.stdev, fa.n, ss_fa);
TfaImg = dtiIndToImg(Tfa, mask, NaN);
tThresh = tinv(1-10^-4, df(1));
tMax = tinv(1-10^-12, df(1));
TfaImg(abs(TfaImg)>tMax) = tMax;
tMax = max(TfaImg(:));

% Simple FDR analysis for FA
%
fdrVal = 0.05; fdrType = 'general';
Tfa(isnan(Tfa)) = 0;
pvals = 1-tcdf(Tfa, df(1));
[n_signif,index_signif] = fdr(pvals,fdrVal,fdrType,'mean');
% Convert back to an fThreshold
tThreshFDR = tinv(1-max(pvals(index_signif)), df(1));
str = sprintf('FA TEST: t-threshold for FDR (%s) of %0.3f: %0.2f (%0.3f).\n',...
             fdrType,fdrVal,tThreshFDR,tThreshFDR/tMax);
fprintf(logFile,str); disp(str);
% Display FA test
figure; imagesc(makeMontage(TfaImg,showSlices)); axis image; colormap cool; colorbar; 
set(gcf,'Name','FA test'); title(sprintf('tthresh, no FDR (p<10^-^4) = %0.1f',tThresh));
dtiWriteNiftiWrapper(TfaImg, xformDtToAcpc, fullfile(outDir,['fa_' DISTR '-test_' num2str(df(1)) 'df.nii.gz']));
dtiWriteNiftiWrapper(dtiIndToImg(fa.stdev,mask), xformDtToAcpc, fullfile(outDir,'fa_variance.nii.gz'));

%
% The next two analyses require log-space tensors.
%
% Log-transform
eigVal(eigVal<0) = 0;
eigVal = log(eigVal);
ssDt_ind = dtiEigComp(eigVec, eigVal);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test for eigenvector differences
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[T, DISTR, df] = dtiLogTensorTest('vec', logTensor.mean, logTensor.stdev, logTensor.n, ssDt_ind);
Timg = dtiIndToImg(T, mask);

if(0)
    %outDir = 'analysis_20080508';
    outDir = 'analysis_BR90_girls_20080508';
    d = dir(fullfile(outDir,'vec_f-test_*df.nii.gz'));
    df = sscanf(d.name,'vec_f-test_%d,%ddf.nii.gz');
    ni = niftiRead(fullfile(outDir,d.name));
    Timg = double(ni.data);
    mask = Timg~=0;
    T = Timg(mask(:));
    logFile = 1;
    ssDt_sn = load('al060406_dt6_fatSat_SIRL54.mat');
end

fThresh = finv(1-10^-4, df(1), df(2));
fMax = finv(1-10^-12, df(1), df(2));
Timg(Timg>fMax) = fMax;
fMax = max(Timg(:));
figure; imagesc(makeMontage(Timg,showSlices)); axis image; colormap hot; colorbar; 
set(gcf,'Name','Vec test'); title(sprintf('fthresh (p<10^-^4) = %0.1f',fThresh));
Simg = dtiIndToImg(logTensor.stdev,mask);
figure; imagesc(makeMontage(Simg,showSlices)); axis image; colormap hot; colorbar; 
set(gcf,'Name','Vec test variance'); 
dtiWriteNiftiWrapper(Timg, xformDtToAcpc, fullfile(outDir,['vec_' DISTR '-test_' num2str(df(1)) ',' num2str(df(2)) 'df.nii.gz']));
dtiWriteNiftiWrapper(Simg, xformDtToAcpc, fullfile(outDir,'vec_variance.nii.gz'));
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
str = sprintf('Log-Norm EigVec Test: f-threshold for FDR (%s method) of %0.3f: %0.2f (%0.3f).\n',...
             fdrType,fdrVal,fThreshFDR,fThreshFDR/fMax);
fprintf(logFile,str); disp(str);
logPimg = dtiIndToImg(-log10(pvals), mask);
cmap = autumn(256);
maxLogP = 10;
minLogP = -log10(pThreshFDR);

anatIm = mrAnatHistogramClip(double(ssDt_sn.anat.img),0.4,0.98);
anatXform = ssDt_sn.anat.xformToAcPc;
dtXform = ssDt_sn.xformToAcPc;
clusterThresh = 10;
imgRgb = mrAnatOverlayMontage(logPimg, dtXform, anatIm, anatXform, cmap, [minLogP,maxLogP], [2:2:40], [], 3, 1, true, 0, [], clusterThresh);

imwrite(imgRgb, fullfile(outDir,'ss_t1_vecSPM_nolabels.png'));
mrUtilPrintFigure(fullfile(outDir,'ss_t1_vecSPM'));
legendLabels = explode(',',sprintf('%0.1f,',[minLogP:1:maxLogP]));
legendLabels{end} = ['>=' num2str(maxLogP)];
mrUtilMakeColorbar(cmap, legendLabels, '-log10(p)', fullfile(outDir,'vecSPM_legend'));

anatIm = template.anat.img;
anatIm(template.anat.brainMask<0.25) = 0;
anatIm(template.anat.brainMask<0.5) = anatIm(template.anat.brainMask<0.5)*.5;
anatXform = template.anat.xformToAcPc;
imgRgb = mrAnatOverlayMontage(logPimg, dtXform, anatIm, anatXform, cmap, [minLogP,maxLogP], [2:2:40], [], 3, 1, true, 0, [], clusterThresh);

imwrite(avgOverlay, fullfile(outDir,'group_t1_vecSPM_nolabels.png'));
mrUtilPrintFigure(fullfile(outDir,'group_t1_vecSPM'));



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test for eigenvalue differences
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[T, DISTR, df] = dtiLogTensorTest('val', logTensor.mean, logTensor.stdev, logTensor.n, ssDt_ind);
Timg = dtiIndToImg(T, mask);
fThresh = finv(1-10^-4, df(1), df(2));
fMax = finv(1-10^-12, df(1), df(2));
Timg(Timg>fMax) = fMax;
fMax = max(Timg(:));
figure; imagesc(makeMontage(Timg,showSlices)); axis image; colormap hot; colorbar; 
set(gcf,'Name','Val test'); title(sprintf('fthresh (p<10^-^4) = %0.1f',fThresh));
Simg = dtiIndToImg(logTensor.stdev,mask);
figure; imagesc(makeMontage(Simg,showSlices)); axis image; colormap hot; colorbar; 
set(gcf,'Name','Val test variance'); 
dtiWriteNiftiWrapper(Timg, xformDtToAcpc, fullfile(outDir,['val_' DISTR '-test_' num2str(df(1)) ',' num2str(df(2)) 'df.nii.gz']));
dtiWriteNiftiWrapper(Simg, xformDtToAcpc, fullfile(outDir,'val_variance.nii.gz'));
% Sqrt(F) is the standardized distance between the groups.
%figure; imagesc(makeMontage(sqrt(Timg),[20:55])); axis image; colormap hot; colorbar; 
%set(gcf,'Name','Vec Standardized Distance');

% Simple FDR analysis for eigenvalue differences
%
fdrVal = 0.05; fdrType = 'general';
T(isnan(T)) = 0;
pvals = 1-fcdf(T, df(1), df(2));
[n_signif,index_signif] = fdr(pvals,fdrVal,fdrType,'mean');
disp(n_signif);max(pvals(index_signif))
% Convert back to an fThreshold
pThreshFDR = max(pvals(index_signif));
fThreshFDR = finv(1-pThreshFDR, df(1), df(2));
str = sprintf('Log-Norm EigVal Test: f-threshold for FDR (%s method) of %0.3f: %0.2f (%0.3f).\n',...
             fdrType,fdrVal,fThreshFDR,fThreshFDR/fMax);
fprintf(logFile,str); disp(str);
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
sl = [2:2:40];
for(ii=1:length(sl)) slLabel{ii} = sprintf('Z = %d',sl(ii)); end
slImg = inv(ssDt_sn.anat.xformToAcPc)*[zeros(length(sl),2) sl' ones(length(sl),1)]';
slImg = round(slImg(3,:));
anatOverlay = makeMontage3(anatRgb, slImg, ssDt_sn.anat.mmPerVox(1), 0, slLabel);
imwrite(anatOverlay, fullfile(outDir,'ss_t1_valSPM_nolabels.png'));
mrUtilPrintFigure(fullfile(outDir,'ss_t1_valSPM'));
legendLabels = explode(',',sprintf('%0.1f,',[minLogP:1:maxLogP]));
legendLabels{end} = ['>=' num2str(maxLogP)];
mrUtilMakeColorbar(cmap, legendLabels, '-log10(p)', fullfile(outDir,'valSPM_legend'));

templateBrain = template.anat.img;
templateBrain(template.anat.brainMask<0.25) = 0;
templateBrain(template.anat.brainMask<0.5) = templateBrain(template.anat.brainMask<0.5)*.5;
avgRgb = repmat(templateBrain,[1,1,1,3]);
avgRgb(overlayMask) = overlayRgb(overlayMask);
% reorient so that the eyes point up
avgRgb = flipdim(permute(avgRgb,[2 1 3 4]),1);
avgOverlay = makeMontage3(avgRgb, slImg, ssDt_sn.anat.mmPerVox(1), 0, slLabel);
imwrite(avgOverlay, fullfile(outDir,'group_t1_valSPM_nolabels.png'));
mrUtilPrintFigure(fullfile(outDir,'group_t1_valSPM'));

fclose(logFile);

return;


%--------------------------------------------------------------------
% FDR Analysis (NOT USED)

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
