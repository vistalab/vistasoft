%create average dti data for any subgroup of subjects, defined by age,
%gender, behavior etc.
%all the brains are already normalized and in one directory (inDir)

if ispc
    inDir = 'U:\data\reading_longitude\templates\child_new\SIRL54warp3';%This is for Windows!!!   check this is updated
    outDir = 'U:\data\reading_longitude\templates\child_new\SIRL54warp3\subgroups_y1';
else
    inDir = '/biac2/wandell2/data/reading_longitude/templates/child_new/SIRL54warp3';%check this is updated
    outDir = '/biac2/wandell2/data/reading_longitude/templates/child_new/SIRL54warp3/subgroups_y1';
end

cd(inDir);
d = dir(fullfile(inDir, ['*_sn*' '.mat']));
files = {d.name};

nSubs = length(files);
index = [1:nSubs]';
%get sub initials from filenames
for(ii=1:nSubs)
    s = files{ii};
    if(~isempty([strfind(s,filesep) strfind(s,'\') strfind(s,'/') strfind(s,'0')]))
        [p,s,e] = fileparts(s);
        us = findstr('0',s);
    else
        us = findstr('_',s);
    end
    subCodeList{ii} = s(1:us(1)-1);
end
%get behavioral data
[behaveData, colNames] = dtiGetBehavioralData(subCodeList);

% the following groups are defined for all 54 subjects (excluding tk), by
% alphabetical order of initials.
age7to9 = index(behaveData(:,2)<=9);
age10to12 = index(behaveData(:,2)>=10);
% age7 = index(behaveData(:,2)<8);
% age8 = index(behaveData(:,2)>=8 & behaveData(:,2)<9);
% age9 = index(behaveData(:,2)>=9 & behaveData(:,2)<10);
% age10 = index(behaveData(:,2)>=10 & behaveData(:,2)<11);
% age11 = index(behaveData(:,2)>=11);
female = index(behaveData(:,1)==0);
male = index(behaveData(:,1)==1);
PAlow = index(behaveData(:,8)<95);
PAhigh = index(behaveData(:,8)>105);
PAnotPoor = index(behaveData(:,8)>95);
% WIDlow = index(behaveData(:,5)<=95);
% WIDhigh = index(behaveData(:,5)>95);

youngerGR = intersect(age7to9,PAnotPoor);
olderGR = intersect(age10to12,PAnotPoor);

% age7WIDhigh = intersect(age7,WIDhigh);
% age8WIDhigh = intersect(age8,WIDhigh);
% age9WIDhigh = intersect(age9,WIDhigh);
% age10WIDhigh = intersect(age10,WIDhigh);
% age11WIDhigh = intersect(age11,WIDhigh);
groupsToAverage = {'youngerGR','olderGR','female','male','PAlow','PAhigh'};
nAverages = length(groupsToAverage);
for ii = 1:nAverages
    curGroup = groupsToAverage{ii};
    averageThese = eval(curGroup);
    N = length(averageThese);
    disp(['Loading ' files{averageThese(1)} '...']);
    dt = load(files{averageThese(1)});
    avg = dt;
    for(jj=2:N)
        disp(['Loading ' files{averageThese(jj)} '...']);
        dt = load(files{averageThese(jj)});
        avg.b0 = avg.b0+dt.b0;
        avg.dt6 = avg.dt6+dt.dt6;
        avg.anat.img = avg.anat.img+dt.anat.img;
    end
    avg.b0(isnan(avg.b0)) = 0;
    avg.dt6(isnan(avg.dt6)) = 0;
    avg.b0 = avg.b0./N;
    avg.dt6 = avg.dt6./N;
    avg.anat.img = avg.anat.img./N;
    % Apply a new brain mask based on the average B0
    avg.b0 = double(avg.b0);
    avg.b0 = mrAnatHistogramClip(avg.b0,.4,.99); %this fails if avg.b0 is an int16. we cast it as double therefore
    mask = dtiCleanImageMask(avg.b0>0.2, 5);
    avg.dt6(repmat(~mask, [1,1,1,6])) = 0;
    newFileName = fullfile(outDir, curGroup,['average_y1_' curGroup '_' num2str(N) '.mat']);
    disp(['Saving to ' newFileName '...']);
    dtiSaveStruct(avg, newFileName);
    clear avg
end

