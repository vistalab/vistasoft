function mtrFigureDOCCConvergence(machineDir, saveDir)

subjVec = {'ss040804','mho040625','bg040719','md040714'};
threshVec = [1000];
paramNames = {'kLength','kSmooth','kMidSD'};
midP = [-2 18 0.175];
bSaveImages = 1;
maxSampleSize = 100000;
minSampleSize = 10000;
deltaSampleSize = 10000;

sampleSizeVec = [maxSampleSize:-deltaSampleSize:minSampleSize 5000 2000 1000];
fgFilename = ['paths_100k_kSmooth_' num2str(midP(2)) '_kLength_' num2str(midP(1)) '_kMidSD_' num2str(midP(3)) '.dat'];

figure; hold on;
axis([min(sampleSizeVec) max(sampleSizeVec) 0 1]);
ylabel('Corr. Coef.');
xlabel('Samples');
box on
for ss = 1:length(subjVec)
    subjDir = [machineDir subjVec{ss}];

    fgDir = fullfile(subjDir, '/conTrack/resamp_LDOCC');
    disp(['cd ' fgDir]);
    cd(fgDir);
    % Get entire pathway database of all sampled paths
    ccVec = computeConvergenceMatrix(sampleSizeVec,fgFilename,subjDir,threshVec);
    plot(sampleSizeVec,ccVec);

    fgDir = fullfile(subjDir, '/conTrack/resamp_RDOCC');
    disp(['cd ' fgDir]);
    cd(fgDir);
    % Get entire pathway database of all sampled paths
    ccVec = computeConvergenceMatrix(sampleSizeVec,fgFilename,subjDir,threshVec);
    plot(sampleSizeVec,ccVec);
end

% Save out the figure to the image dir
set(gcf,'Position',[395   447   289   240]);
if bSaveImages
    figFilename = fullfile(saveDir,['convergenceDOCC.png']);
    set(gcf,'PaperPositionMode','auto');
    print('-dpng', figFilename);
end

function ccVec = computeConvergenceMatrix(sampleSizeVec,fgFilename,subjDir,threshVec)

% Load necessary info
dt6 = load(fullfile(subjDir,'dt6.mat'),'xformToAcPc');
ni = niftiRead(fullfile(subjDir,'bin','t1.nii.gz'));
img_t1 = ni.data;
imSize = size(img_t1);
mmPerVoxel = [1 1 1];
xformT1ImgToAcPc = ni.qto_xyz;
clear ni;

ni = niftiRead(fullfile(subjDir,'bin','wmMask.nii.gz'));
img_wm = interp3(ni.data,'nearest');
clear ni;

fdPrevImg = [];
ccVec = 1;
fg = [];


% For different starting group sizes
for gg = sampleSizeVec
    [fgDir, filename, junk2, junk3] = fileparts(fgFilename);
    densityFilename = sprintf('%s_fp_%gk_fd_image.nii.gz',filename,round(gg/1000));
    densityFilename = fullfile(fgDir,densityFilename);
    f = dir(densityFilename);
    % See if we need to create the fiber density image
    if isempty(f)
        if isempty(fg)
            % Load fiber group for first pass
            msg = sprintf('Importing fiber group from %s ...',fgFilename);
            disp(msg);
            % Import fibers
            fg = mtrImportFibers(fgFilename, dt6.xformToAcPc);
            idRandom = randperm(length(fg.fibers));
        end
        
        % Get a portion of the starting group
        fpIndex = round(gg / max(sampleSizeVec) * length(fg.fibers));
        fpSubFg = dtiNewFiberGroup;
        fpSubFg.fibers = fg.fibers(idRandom(1:fpIndex));
        fpSubFg.params = fg.params;
        fpSubFg.params{1}.stat = fg.params{1}.stat(idRandom(1:fpIndex));

        % Take top scoring paths from this group portion
        weight = [];
        tempThreshVec = [];
        if ~isempty(threshVec)
            % Get weight so that we can sort
            weight = fpSubFg.params{1}.stat;
            [foo, iSort] = sort(weight,'descend');
            % Make sure we don't try to sample more than the current database
            tempThreshVec = threshVec(threshVec<length(fpSubFg.fibers));
        end
        % Doing it this way to handle case where max is too big for any fibers
        % ot be selected
        if isempty(tempThreshVec)
            iSort = [1:length(fpSubFg.fibers)];
            tempThreshVec = length(fpSubFg.fibers);
        end
        for tt = tempThreshVec;
            % Calculate fiber density for these fiber paths
            disp(['Calculating fiber density map at thresh = ' num2str(tt) ' ...']);
            fpSubFgThresh = dtiNewFiberGroup;
            fpSubFgThresh.fibers = fpSubFg.fibers(iSort(1:tt));
            fdImg = dtiComputeFiberDensityNoGUI(fpSubFgThresh, xformT1ImgToAcPc, imSize, 1, 0, 0);
            % Save out image
            msg = sprintf('Saving density image to %s ...',densityFilename);
            disp(msg);
            dtiWriteNiftiWrapper(fdImg, xformT1ImgToAcPc, densityFilename);
        end
        clear('fpSubFgThresh','fpSubFg');
    else
        % Load the density image
        disp(['Loading density image ' densityFilename ' ...']);
        ni = niftiRead(densityFilename);
        fdImg = ni.data;
    end
    % Limit to white matter and binarize
    fdImg = double(fdImg(img_wm>0)>0);
    
    % Compare the density images
    if ~isempty(fdPrevImg)
        cc = corrcoef(fdPrevImg(:),fdImg(:));
        ccVec(end+1) = cc(1,2);
        disp(['CC: ' num2str(cc(1,2))]);
    else
        fdPrevImg = fdImg;
    end
    % Now shift the register of images
    %fdPrevImg = fdImg;
end
