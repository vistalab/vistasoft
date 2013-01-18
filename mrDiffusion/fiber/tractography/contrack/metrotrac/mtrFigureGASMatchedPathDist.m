function mtrFigureGASMatchedPathDist(machineDir, imageDir)

subjVec = {'tony_nov05','thor_nov05','sil_nov05'};
%subjVec = {'thor_nov05'};
threshVec = [1000];
ctFile = 'paths500k_5k.dat';
sttFile = 'stt_clip.dat';
distMatricesFile = 'distMatricesGAS.mat';
bSavePlot = 0;

for ss = 1:length(subjVec)
    subjDir = fullfile(machineDir,subjVec{ss}); 
    figure;
    
    fgDir = fullfile(subjDir, 'conTrack');
    disp(['cd ' fgDir]);
    cd(fgDir);    
    [meanD, maxD] = mtrMatchPathways(fullfile(subjDir,'dt6.mat'), fullfile(subjDir,'fibers',sttFile), ctFile);

    % Save out the figures to the image dir
    subplot(2,1,1); hist((min(meanD,[],2)));
    xlabel('Mean distance to closest conTrack path (mm)');
    subplot(2,1,2); hist((min(maxD,[],2)));
    xlabel('Max distance to closest conTrack path (mm)');
    save(distMatricesFile,'meanD','maxD');
    
    if(bSavePlot)
        set(gcf,'Position',[504 687 436 259]);
        figFilename = fullfile(subjDir,imageDir,['distHist.png'])
        set(gcf,'PaperPositionMode','auto');
        print('-dpng', figFilename);
    end
end
