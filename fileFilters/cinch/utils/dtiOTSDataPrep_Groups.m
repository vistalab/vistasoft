function dtiOTSDataPrep 

% function dtiOTSDataPrep 
%
% Script to prepare Davie's OTS data for analysis... based off of Dave's
% dtiOTSDataPrep, but written to be run on a PC, not teal, and to analyze
% group average dt6s. 
%
% Author: DY
% Date: 08/20/2006

baseDir = 'Y:\data\reading_longitude\templates\child_new\subgroups_y1'; %path to subjects' dti data on harddrive
cd(baseDir);
d = dir; % lists all directories 
f = {d.name};
f = f(3:length(f));

dtname = {'average_y1_PAhigh_N17.mat','average_y1_PAlow_N25.mat','average_y1_female_N30.mat',...
    'average_y1_male_N24.mat','average_y1_olderGR_N15.mat','average_y1_youngerGR_N11.mat'};

fiberDir = '\fibers\OTSproject';
fgNames = {'LOTS_tal_sph8_FG.mat', 'ROTS_tal_sph8_FG.mat'};

for(ii=1:length(f))
    groupDir = fullfile(baseDir, f{ii});
    dt6Name = dtname{ii}
    dt6Path = fullfile(groupDir, dtname{ii});
    
    fprintf ('Converting DT6 %s to binary format...\n', dt6Name);
    dtiConvertDT6ToBinaries (dt6Path);
    
    for (fGroupIndex=1:length(fgNames))
        fgName = fgNames{fGroupIndex};
        fgPath = fullfile(groupDir, fiberDir, fgName);
        distanceName = fullfile(groupDir,'bin','selections',fgName);
        distanceName = [distanceName '.dis'];
        
        fprintf ('Loading fiber group %s\n', fgPath);
        fg = open (fgPath);
        fprintf ('Computing distance matrix...\n');
        dtiComputePathwayDistanceMatrixFromFG (fg.fg, distanceName);
    end;

end;

fprintf ('Done!\n');
