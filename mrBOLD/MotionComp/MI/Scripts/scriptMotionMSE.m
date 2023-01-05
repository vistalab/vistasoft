close all
clear all
rootDir = '\\Snarp\u1\data\reading_longitude\fmri';

cd(rootDir);
[fileNum dirName] = countDirs(pwd);

for count = 3:fileNum
    try
        currentDir = dirName{count};
    
        cd(fullfile(rootDir,currentDir));
        mrVista;
        vw = getSelectedInplane;
        motionCompPlotMSE(vw);

    end
    
    close all;
    clear all;
    
    rootDir = '\\Snarp\u1\data\reading_longitude\fmri';

	cd(rootDir);
	[fileNum dirName] = countDirs(pwd);

    pause(0.001);
end
    
    
    