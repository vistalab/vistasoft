% go to every subject in the BA44-45 list
% load each fiber group in the BA44-45\dissections dir
% transpose  fg.fibers
% save as .._fixed.mat

baseDir = 'U:\data\reading_longitude\dti_adults\';
subDirs = {'ab050307','as050307','aw040809','bw040806','da050311','gm050308',...
        'jl040902','ka040923','mbs040503', 'me050126', 'mz040828',...
        'pp050208', 'rd040630','sn040831','sp050303'};
fiberDir = 'fibers\BA44-45\dissections\';
    
        
for ii = 1:length(subDirs)
    workDir = fullfile(baseDir,subDirs{ii},fiberDir);
    cd(workDir);
    d = dir('?BA*.mat');
    fileNames = {d.name};
    for jj = 1:length(fileNames)
        curFileName = fileNames{jj};
        load(curFileName);
        fg.fibers = fg.fibers';
        newFileName = [curFileName(1:end-4) '_fixed.mat'];
        save(newFileName,'fg','versionNum','coordinateSpace');
        clear fg versionNum coordinateSpace
    end
end
