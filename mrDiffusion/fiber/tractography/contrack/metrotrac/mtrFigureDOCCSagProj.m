function mtrFigureDOCCSagProj(machineDir, imageDir)

subjVec = {'ss040804','mho040625','bg040719','md040714'};
paramNames = {'kLength','kSmooth','kMidSD'};

threshVec = [1000 500];
params = [-2 18 0.175];
pathsRootFile = ['paths_100k_5k_kSmooth_' num2str(params(2)) '_kLength_' num2str(params(1)) '_kMidSD_' num2str(params(3))];
pathsFile = [pathsRootFile '.dat'];

for ss = 1:length(subjVec)
    subjDir = fullfile(machineDir,subjVec{ss});

    combSTTFile = 'sttDOCCComb.nii.gz';
    fgDir = fullfile(subjDir, 'fibers');
    disp(['cd ' fgDir]);
    cd(fgDir);
    f = dir('paths_STT_LDOCC*_fd_image.nii.gz');
    if isempty(f)
        disp('Density file does not exist, creating it ...');
        mtrComputeManyFiberDensities(subjDir,'paths_STT_LDOCC.dat',3000);
    end
    sttDensityImage = dir('paths_STT_LDOCC*_fd_image.nii.gz');
    niL = niftiRead(sttDensityImage(1).name);

    f = dir('paths_STT_RDOCC*_fd_image.nii.gz');
    if isempty(f)
        disp('Density file does not exist, creating it ...');
        mtrComputeManyFiberDensities(subjDir,'paths_STT_RDOCC.dat',3000);
    end
    sttDensityImage = dir('paths_STT_RDOCC*_fd_image.nii.gz');
    niR = niftiRead(sttDensityImage(1).name);
    
    imgComb = double(niL.data>0) + double(niR.data>0)*2;
    disp(['Writing ' fullfile(subjDir,imageDir,combSTTFile) ' ...']);
    dtiWriteNiftiWrapper(imgComb,niL.qto_xyz,fullfile(subjDir,imageDir,combSTTFile));
    
    for tt = threshVec
        densityFile = [pathsRootFile '_thresh_' num2str(tt) '_fd_image.nii.gz'];
        combFile = ['ctDOCCComb_kLength_' num2str(params(1)) '_thresh_' num2str(tt) '.nii.gz'];        
        
        fgDir = fullfile(subjDir, 'conTrack/resamp_LDOCC');
        disp(['cd ' fgDir]);
        cd(fgDir);
        % See if density file exists
        f = dir(densityFile);
        if isempty(f)
            disp('Density file does not exist, creating it ...');
            mtrComputeManyFiberDensities(subjDir,pathsFile,threshVec);
        end
        niL = niftiRead(densityFile);

        fgDir = fullfile(subjDir,'conTrack/resamp_RDOCC');
        disp(['cd ' fgDir]);
        cd(fgDir);
        % See if density file exists
        f = dir(densityFile);
        if isempty(f)
            mtrComputeManyFiberDensities(subjDir,pathsFile,threshVec);
        end
        niR = niftiRead(densityFile);

        imgComb = double(niL.data>0) + double(niR.data>0)*2;
        disp(['Writing ' fullfile(subjDir,imageDir,combFile) ' ...']);
        dtiWriteNiftiWrapper(imgComb,niL.qto_xyz,fullfile(subjDir,imageDir,combFile));
    end
end
