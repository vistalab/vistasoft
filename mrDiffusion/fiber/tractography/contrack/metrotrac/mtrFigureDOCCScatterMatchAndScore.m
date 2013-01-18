function mtrFigureDOCCScatterMatchAndScore(machineDir, type)

%subjVec = {'ss040804','mho040625','bg040719','md040714'};
subjVec = {'bg040719'};
distMatricesFile = 'distMatricesDOCC.mat';
params = [-2 18 0.175];
ctFile = ['paths_100k_5k_kSmooth_' num2str(params(2)) '_kLength_' num2str(params(1)) '_kMidSD_' num2str(params(3)) '.dat']; 
bSaveImages = 0;
bDoMax = 0;

for ss = 1:length(subjVec)
    subjDir = fullfile(machineDir,subjVec{ss});
    dt6 = load(fullfile(subjDir,'dt6.mat'),'xformToAcPc');
        
    fgDir = fullfile(subjDir, 'conTrack/resamp_LDOCC');
    disp(['cd ' fgDir]);
    cd(fgDir);
    
    % Load distances from STT paths to conTrack paths        
    D = load(distMatricesFile); 
    
    % Load STT paths to get scores
    fg = dtiNewFiberGroup;
    if strcmp(type,'STT')
        fg = mtrImportFibers(fullfile(subjDir,'fibers/paths_STT_LDOCC.dat'),dt6.xformToAcPc);
        if bDoMax
            distVec = min(D.maxD,[],2);
        else
            distVec = min(D.meanD,[],2);
        end
    else
        fg = mtrImportFibers(ctFile,dt6.xformToAcPc);
        if bDoMax
            distVec = min(D.maxD,[],1);
        else
            distVec = min(D.meanD,[],1);
        end
    end
    scoreVec = mtrGetFGScoreVec(fg);      
    
    figure;  
    % Scatter plot
    subplot(1,2,1); scatter(scoreVec(~isinf(scoreVec)),distVec(~isinf(scoreVec)));
    axis([-50 150 0 22]);
    xlabel('ln(score)');
    ylabel('Distance to nearest path (mm)');
    % Save out the figures to the image dir
    
    fgDir = fullfile(subjDir, 'conTrack/resamp_RDOCC');
    disp(['cd ' fgDir]);
    cd(fgDir);
    
    % Load distances from STT paths to conTrack paths        
    D = load(distMatricesFile); 
    
    % Load STT paths to get scores
    fg = dtiNewFiberGroup;
    if strcmp(type,'STT')
        fg = mtrImportFibers(fullfile(subjDir,'fibers/paths_STT_RDOCC.dat'),dt6.xformToAcPc);
        if bDoMax
            distVec = min(D.maxD,[],2);
        else
            distVec = min(D.meanD,[],2);
        end
    else
        fg = mtrImportFibers(ctFile,dt6.xformToAcPc);
        if bDoMax
            distVec = min(D.maxD,[],1);
        else
            distVec = min(D.meanD,[],1);
        end
    end
    scoreVec = mtrGetFGScoreVec(fg);
   
    % Scatter plot
    subplot(1,2,2); scatter(scoreVec(~isinf(scoreVec)),distVec(~isinf(scoreVec)));
    axis([-50 150 0 22]);
    xlabel('ln(score)');
    ylabel('Distance to nearest path (mm)');
    % Save out the figures to the image dir
    
    set(gcf,'Position',[410   597   672   270]);
    if bSaveImages
        if strcmp(type,'STT')
            figFilename = fullfile(subjDir,'images',['scatterScoreDistSTT.png'])
        else
            figFilename = fullfile(subjDir,'images',['scatterScoreDistCT.png'])
        end
        set(gcf,'PaperPositionMode','auto');
        print('-dpng', figFilename);
    end
end