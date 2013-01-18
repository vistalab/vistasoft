if(ispc)
    tdir = '\\white.stanford.edu\biac2-wandell2\data\reading_longitude\templates\adult\';
    baseDir = '\\white.stanford.edu\biac2-wandell2\data\reading_longitude\dti_adults\*0*';
else
    tdir = '/biac2/wandell2/data/templates/adult/';
    baseDir = '/biac2/wandell2/data/reading_longitude/dti_adults/*0*';
end
normDir = fullfile(tdir, ['SIRL20_adultwarp2']);
sumStatsFile = fullfile(normDir,'summaryStats.mat');
if(exist(sumStatsFile,'file'))
    disp(['Loading control stats from ' sumStatsFile '...']);
    load(sumStatsFile);
else
    files = findSubjects(normDir, '*_sn*',{});
    N = length(files);
    disp(['Loading ' files{1} '...']);
    dt = load(files{1});
    xformDt6ToAcPc = dt.xformToAcPc;
    mmPerVoxDt6 = dt.mmPerVox;
    fa = zeros([size(dt.b0) N]);
    md = zeros([size(dt.b0) N]);
    b0Avg = zeros(size(dt.b0));
    t1Avg = zeros(size(dt.anat.img));
    bmAvg = zeros(size(dt.anat.img));

    for(ii=1:N)
        disp(['Loading ' files{ii} '...']);
        dt = load(files{ii});
        dt.dt6(isnan(dt.dt6)) = 0;
        b0Avg = b0Avg+mrAnatHistogramClip(double(dt.b0),0.5,0.99);
        t1Avg = t1Avg+mrAnatHistogramClip(double(dt.anat.img),0.5,0.99);
        bmAvg = bmAvg+double(dt.anat.brainMask);
        [eigVec, eigVal] = dtiSplitTensor(dt.dt6);
        fa(:,:,:,ii) = dtiComputeFA(eigVal);
        md(:,:,:,ii) = sum(dt.dt6(:,:,:,1:3), 4)./3;
        % Could also do sum(eigVal,4)./3;
    end

    b0Avg = b0Avg./N;
    t1Avg = t1Avg./N;
    bmAvg = bmAvg./N;

    %figure;imagesc(makeMontage(b0Avg));axis image;colormap gray;
    fa(isnan(fa)) = 0;
    faAvg = mean(fa,4);
    faStd = std(fa,1,4);
    %figure;imagesc(makeMontage(faAvg));axis image;colormap gray; colorbar;
    %figure;imagesc(makeMontage(faStd));axis image;colormap hot; colorbar;

    mdAvg = mean(md,4);
    mdStd = std(md,1,4);
    %figure;imagesc(makeMontage(mdAvg));axis image;colormap gray; colorbar;
    %figure;imagesc(makeMontage(mdStd));axis image;colormap hot; colorbar;
    save(sumStatsFile, 't1Avg', 'b0Avg', 'bmAvg', 'faAvg', 'faStd', 'mdAvg', 'mdStd', 'files');
end

handles = guidata(gcf);

%subMd = handles.bg(5).img.*handles.bg(5).maxVal;
subMd = sum(handles.dt6(:,:,:,1:3), 4)./3;
subMd(subMd<0) = 0;

if(~isfield(handles.t1NormParams,'deformX') | isempty(handles.t1NormParams.deformX))
   disp('Computing inverse deformation...');
   [handles.t1NormParams.deformX, handles.t1NormParams.deformY, handles.t1NormParams.deformZ] = mrAnatInvertSn(sn);
end

bb = dtiGet(handles, 't1BoundingBox');
dt6Xform = dtiGet(handles,'dt6Xform');
dt6Xform(1:3,4) = dt6Xform(1:3,4)-1;
mmPerVoxDt6 = handles.vec.mmPerVoxel;
handles.t1NormParams.inMat = inv(handles.t1NormParams.sn.VF.mat);
handles.t1NormParams.outMat = inv(dt6Xform);
[wMdAvg,xform] = mrAnatResliceSpm(mdAvg, handles.t1NormParams, bb, mmPerVoxDt6, [1 1 1 0 0 0]);
[wMdStd,xform] = mrAnatResliceSpm(mdStd, handles.t1NormParams, bb, mmPerVoxDt6, [1 1 1 0 0 0]);
nz = wMdStd>0;
wMdSS = zeros(size(wMdAvg));
wMdSS(nz) = (subMd(nz)-wMdAvg(nz))./wMdStd(nz);
wMdSS(wMdSS>10) = 10; wMdSS(wMdSS<-10) = -10;

handles = dtiAddBackgroundImage(handles, wMdAvg, 'avg MD', mmPerVoxDt6, diag([mmPerVoxDt6 1]));
handles = dtiAddBackgroundImage(handles, wMdSS, 'MD SS', mmPerVoxDt6, diag([mmPerVoxDt6 1]));
handles = dtiRefreshFigure(handles);
guidata(gcf, handles)

