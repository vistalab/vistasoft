function dtiOTSDataPrep 

% function dtiOTSDataPrep 
%
% Script to prepare Davie's OTS data for analysis...
%
% Author: DA 

baseDir = '//biac2/wandell2/data/reading_longitude/dti'; %on Teal
d = dir([baseDir filesep '*0*']); % lists all directories 
subjectNames = {d.name};

%subjectNames = {'ab050307','as050307','aw040809','bw040806','da050311','gm050308',...
%        'jl040902','ka040923','mbs040503', 'me050126', 'mz040828',...
%        'pp050208', 'rd040630','sn040831','sp050303'};

fiberDir = '/fibers/OTSproject'
fgNames = {'LOTS_tal_sph8_FG.mat', 'ROTS_tal_sph8_FG.mat'};

for(subjectIndex=1:length(subjectNames))
    subjectDir = [baseDir filesep subjectNames{subjectIndex}];
    subjectName = subjectNames{subjectIndex}
    dt6Name = sprintf ('%s_dt6.mat', subjectName);
    dt6Path = [subjectDir filesep dt6Name];
    
    fprintf ('Converting DT6 %s to binary format...\n', dt6Name);
    dtiConvertDT6ToBinaries (dt6Path);
    
    for (fGroupIndex=1:length(fgNames))
        fgName = fgNames{fGroupIndex};
        fgPath = [subjectDir filesep fiberDir filesep fgName];
        distanceName = [subjectDir filesep 'bin' filesep 'selections' filesep fgName '.dis'];
        
        fprintf ('Loading fiber group %s\n', fgPath);
        fg = open (fgPath);
        fprintf ('Computing distance matrix...\n');
        dtiComputePathwayDistanceMatrixFromFG (fg.fg, distanceName);
    end;

end;

fprintf ('Done!\n');
