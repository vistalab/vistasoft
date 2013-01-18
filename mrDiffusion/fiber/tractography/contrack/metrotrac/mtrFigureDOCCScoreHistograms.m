function mtrFigureDOCCScoreHistograms(machineDir, imageDir)

subjVec = {'ss040804','mho040625','bg040719','md040714'};
threshVec = [2000 1000 500];


for ss = 1:length(subjVec)
    subjDir = [machineDir subjVec{ss}]; 
    
    fgDir = [subjDir '/conTrack/resamp_LDOCC'];
    disp(['cd ' fgDir]);
    cd(fgDir);    
    %mtrPDBScoreHist
    
    fgDir = [subjDir '/conTrack/resamp_LDOCC'];
    disp(['cd ' fgDir]);
    cd(fgDir);    
    %mtrPlotCorr(ccFilenameBase,threshVec,paramNames,midP);
end

