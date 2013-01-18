%function dtiGenerateNormalizedData
% Generate a spatially-normalized set of summary data for two groups (boys
% and girls).

bd = '/biac3/wandell4/data/reading_longitude/dti_y1234/';
[sd,sc] = findSubjects([bd '*'],'dti06trilinrt');
behaveData = dtiGetBehavioralDataStruct(sc, '/biac3/wandell4/data/reading_longitude/read_behav_measures_longitude.csv', sd);
clear sd sc;
outDir = '/biac3/wandell4/data/reading_longitude/logNorm_analysis';
sumFile = fullfile(outDir,'sum_090715');

n = numel(behaveData);
templateName = 'SIRL54';
templateDir = fullfile(fileparts(which('mrDiffusion.m')),'templates');
template = fullfile(templateDir, [templateName '_EPI.nii.gz']);
t1Template = fullfile(templateDir, [templateName '_T1.nii.gz']);
desc = ['Normalized to ' templateName ' using B0.'];
clear templateName templateDir;
mT1 = 0;
mB0 = 0;
mBm = 0;
mDt6 = 0;
clear sn t1Sn;
for(ii=116:n)
    tic;
    fprintf('Processing %d of %d (%s)...\n',ii, n, behaveData(ii).dataDir);
    dtiRawFixDt6File(behaveData(ii).dataDir);
    [dt,t1] = dtiLoadDt6(behaveData(ii).dataDir);
    im = mrAnatHistogramClip(double(dt.b0),0.4,0.98);
    dt.b0 = im;
    im(bwareaopen(im==0,10000,6)) = NaN;
    evalc('sn{ii} = mrAnatComputeSpmSpatialNorm(im, dt.xformToAcpc, template);');
    evalc('dt_sn = dtiSpmDeformer(dt,sn{ii});');
    sn{ii}.VG.dat = [];
    dtXformToAcpc = dt_sn.xformToAcpc;
    adcUnits = dt_sn.adcUnits;
    mB0 = mB0 + dt_sn.b0;
    % We'll exclude non-PD tensors by removing them from the brain mask
    [vec,val] = dtiEig(dt_sn.dt6);
    mBm = mBm + double(dt_sn.brainMask & all(val>0,4));
    mDt6 = mDt6 + dt_sn.dt6;
    dt6(:,:,:,:,ii) = single(dt_sn.dt6);
    b0(:,:,:,ii) = single(dt_sn.b0);
    clear dt im dt_sn vec val;
    im = mrAnatHistogramClip(double(t1.img),0.4,0.98);
    evalc('t1Sn{ii} = mrAnatComputeSpmSpatialNorm(im, t1.xformToAcpc, t1Template);');
    t1Sn{ii}.VG.dat = [];
    [im,t1XformToAcpc] = mrAnatResliceSpm(im, t1Sn{ii}, mrAnatXformCoords(t1Sn{ii}.VG.mat,[1 1 1; t1Sn{ii}.VG.dim]), [1 1 1], 7, false);
    % mrAnatOverlayMontage(dt_sn.b0,dt_sn.xformToAcpc, im, t1Sn.VG.mat, autumn(256), [.8 1], [-20:2:60])
    mT1 = mT1 + im;
    clear im t1;
    toc
end
tmpFile = [tempname '.mat'];
save(tmpFile,'-v7.3');

clear vec val im ii tmpFile;
brainMask = mBm>=ceil(n*.95) & all(dt6(:,:,:,1,:)~=0,5);
b0 = dtiImgToInd(b0,brainMask);
dt6 = dtiImgToInd(dt6, brainMask);
mBm = single(mBm);
mB0 = single(mB0);
mDt6 = single(mDt6);
mT1 = single(mT1);
clear ans;

save(sumFile);

%return

dtiWriteTensorsToNifti(mDt6, dtXformToAcpc, desc, adcUnits, fullfile(outDir,'dti06','bin','tensors.nii.gz'));
dtiWriteNiftiWrapper(mB0, dtXformToAcpc, fullfile(outDir,'dti06','bin','b0.nii.gz'), 1, desc);
dtiWriteNiftiWrapper(uint8(brainMask), dtXformToAcpc, fullfile(outDir,'dti06','bin','brainMask.nii.gz'), 1, desc);
dtiWriteNiftiWrapper(mT1, t1XformToAcpc, fullfile(outDir,'dti06','t1.nii.gz'), 1, desc);




