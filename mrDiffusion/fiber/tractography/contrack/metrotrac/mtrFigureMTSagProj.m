function mtrFigureMTSagProj(machineDir, imageDir)

subjVec = {'ss040804','mho040625','bg040719','md040714'};
paramNames = {'kLength','kSmooth','kMidSD'};

threshVec = [1000 500];
params = [-3 18 0.175];
pathsRootFile = ['paths_100k_5k_kSmooth_' num2str(params(2)) '_kLength_' num2str(params(1)) '_kMidSD_' num2str(params(3))];
pathsFile = [pathsRootFile '.dat'];

for ss = 1:length(subjVec)
    subjDir = fullfile(machineDir,subjVec{ss});     
    
    for tt = threshVec
        densityFile = [pathsRootFile '_thresh_' num2str(tt) '_fd_image.nii.gz'];
        combFile = ['ctMTComb_kLength_' num2str(params(1)) '_thresh_' num2str(tt) '.nii.gz'];
        
        fgDir = fullfile(subjDir, 'conTrack/resamp_LMT');
        disp(['cd ' fgDir]);
        cd(fgDir);
        % See if density file exists
        f = dir(densityFile);
        if isempty(f)
            disp('Density file does not exist, creating it ...');
            mtrComputeManyFiberDensities(subjDir,pathsFile,threshVec);
        end
        niL = niftiRead(densityFile);

        fgDir = fullfile(subjDir,'conTrack/resamp_RMT');
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
