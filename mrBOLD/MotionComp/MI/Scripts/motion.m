rootDir = '\\White\biac2-wandell\data\reading_longitudinal_study\To do';

cd(rootDir);
[fileNum dirName] = countDirs(pwd);

for count = 3:length(dirName)
    currentDir = dirName{count};
    
    cd(fullfile(rootDir,currentDir));
    mrVista;
    vw = getSelectedInplane;
    MSE = motionCompDetectMotionMSE(vw,'',1:6,0);
    
    save(['MSE_' currentDir],'MSE');
end
    
    
    