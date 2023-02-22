workDir = '/biac2/wandell/data/reading_longitudinal_study/To_correct/';

cd(workDir);
[fileNum dirName] = countDirs(pwd);

for count = 3:fileNum

    currentDir = dirName{count};
    
    cd(fullfile(workDir,currentDir));
    transformAll;
        
	close all
	clear all
	mrVista
	vw = getSelectedInplane;
	computeError

    % Redefining variables because they are cleared in transform
    workDir = '/biac2/wandell/data/reading_longitudinal_study/To_correct/';
    
    cd(workDir);
    [fileNum dirName] = countDirs(pwd);

end
    
    
    