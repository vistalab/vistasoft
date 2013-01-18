function mtrFigureDOCCMatchedPathDist(machineDir, imageDir)

subjVec = {'ss040804','mho040625','bg040719','md040714'};
threshVec = [1000];
paramNames = {'kLength','kSmooth','kMidSD'};
params = [-2 18 0.175];
ctFile = ['paths_100k_5k_kSmooth_' num2str(params(2)) '_kLength_' num2str(params(1)) '_kMidSD_' num2str(params(3)) '.dat'];
distMatricesFile = 'distMatricesDOCC.mat';

for ss = 1:length(subjVec)
    subjDir = fullfile(machineDir,subjVec{ss}); 
    figure;
    
    fgDir = fullfile(subjDir, 'conTrack/resamp_LDOCC');
    disp(['cd ' fgDir]);
    cd(fgDir);    
    [meanLD, maxLD] = mtrMatchPathways(fullfile(subjDir,'dt6.mat'), fullfile(subjDir,'fibers/paths_STT_LDOCC.dat'), ctFile);

    % Save out the figures to the image dir
    subplot(2,1,1); hist((min(meanLD,[],2)));
    xlabel('LDOCC: Mean distance to closest conTrack path (mm)');
    save(distMatricesFile,'meanLD','maxLD');
    
    fgDir = fullfile(subjDir,'conTrack/resamp_RDOCC');
    disp(['cd ' fgDir]);
    cd(fgDir);    
    [meanRD, maxRD] = mtrMatchPathways(fullfile(subjDir,'dt6.mat'), fullfile(subjDir,'fibers/paths_STT_RDOCC.dat'), ctFile);
   
    % Save out the figures to the image dir
    subplot(2,1,2); hist((min(meanD,[],2)));
    xlabel('RDOCC: Mean distance to closest conTrack path (mm)');
    save(distMatricesFile,'meanRD','maxRD');
    
    set(gcf,'Position',[504 687 436 259]);
    figFilename = fullfile(subjDir,imageDir,['distHist_kLength_' num2str(params(1)) '.png'])
    set(gcf,'PaperPositionMode','auto');
    print('-dpng', figFilename);
end