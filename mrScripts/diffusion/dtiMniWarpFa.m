baseDir = '/biac2/wandell2/data/reading_longitude/';
dataDir = 'dti';
subDir = fullfile(baseDir,dataDir,'*0*');
outFileName = ['mniWarpAnalysis_' dataDir];
outDir = fullfile('/silver','scr1','mniWarpAnalysis');
if(~exist(outDir,'dir')) mkdir(outDir); end
outDir = fullfile(outDir,'data')
if(~exist(outDir,'dir')) mkdir(outDir); end
dataSumFile = fullfile(outDir,[outFileName '_sum.mat']);
logFileName = fullfile(outDir,[outFileName '_log_' datestr(now,'yymmdd_HHMM') '.txt']);

excludeSubs = {'dh040607','an041018','hy040602','lg041019','mh040630','tk040817'};
[f,sc] = findSubjects(subDir,'*_dt6_noMask',excludeSubs);
N = length(f);
spm_defaults; global defaults;
bb = defaults.normalise.write.bb;
mm = defaults.normalise.write.vox;
spmDir = fileparts(which('spm_defaults'));
mniTemplate = fullfile(spmDir,'templates','EPI.nii')

for(ii=1:N)
    disp(['Processing ' sc{ii} '...']);
    subDir = fileparts(f{ii});
    dtDir = fullfile(subDir,'dti');
    unix(['cp -r ' dtDir ' /tmp/']);
    unix(['gunzip /tmp/dti/*.gz']);
    [b0.cannonical, b0.baseFname, b0.mmPerVox, b0.imDim, b0.notes] = computeCannonicalXformFromIfile('/tmp/dti/B0_001');
    b0.img = makeCubeIfiles(b0.baseFname, b0.imDim(1:2));
    [b0.cannonical_img, b0.cannonical_mmPerVox] = applyCannonicalXform(b0.img, b0.cannonical, b0.mmPerVox);
    b0.acpcXform = [diag(b0.cannonical_mmPerVox), -[size(b0.cannonical_img)./2.*b0.cannonical_mmPerVox]'; [0 0 0 1]];
    [b0.cannonical_img,b0.clipVals] = mrAnatHistogramClip(b0.cannonical_img,0.4,0.99);
    dtBrainMask = dtiCleanImageMask(b0.cannonical_img>0.2, 6);
    b0.cannonical_img = b0.cannonical_img.*b0.clipVals(2);
    dt6_tmp = dtiLoadTensorElements(fullfile(fileparts(b0.baseFname), 'TensorElements.float.'));
    unix(['rm -rf /tmp/dti']);
    dt6_tmp = permute(dt6_tmp,[2 1 3 4]);
    for(jj=1:6)
        tmp = applyCannonicalXform(dt6_tmp(:,:,:,jj), b0.cannonical, b0.mmPerVox);
        tmp(~dtBrainMask) = 0;
        dt6(:,:,:,jj) = tmp;
    end
    clear dt6_tmp;
    [fa,md,rd] = dtiComputeFA(dt6);
    clear dt6;
    sn = mrAnatComputeSpmSpatialNorm(b0.cannonical_img, b0.acpcXform, mniTemplate);
    [b0_sn,xform] = mrAnatResliceSpm(b0.cannonical_img, sn, bb, mm, [1 1 1 0 0 0], 0);
    b0_sn(b0_sn<0|isnan(b0_sn)) = 0;
    fa_sn = mrAnatResliceSpm(fa, sn, bb, mm, [1 1 1 0 0 0], 0);
    fa_sn(fa_sn<0|isnan(fa_sn)) = 0;
    fa_sn(fa_sn>1) = 1;
    md_sn = mrAnatResliceSpm(md, sn, bb, mm, [1 1 1 0 0 0], 0);
    md_sn(md_sn<0|isnan(md_sn)) = 0;
    rd_sn = mrAnatResliceSpm(rd, sn, bb, mm, [1 1 1 0 0 0], 0);
    rd_sn(rd_sn<0|isnan(rd_sn)) = 0;
    dtiWriteNiftiWrapper(b0_sn,xform,fullfile(outDir,[sc{ii} '_B0_sn.nii.gz']));
    dtiWriteNiftiWrapper(fa_sn,xform,fullfile(outDir,[sc{ii} '_FA_sn.nii.gz']));
    dtiWriteNiftiWrapper(md_sn,xform,fullfile(outDir,[sc{ii} '_MD_sn.nii.gz']));
    dtiWriteNiftiWrapper(rd_sn,xform,fullfile(outDir,[sc{ii} '_RD_sn.nii.gz']));
end
