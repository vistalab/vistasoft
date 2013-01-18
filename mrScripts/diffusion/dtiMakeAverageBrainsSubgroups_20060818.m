%create average dti data for any subgroup of subjects, defined by age,
%gender, behavior etc.
%all the brains are already normalized and in one directory (inDir)
thisfilename = 'dtiMakeAverageBrainsSubgroups_20060818';
if ispc
    inDir = 'Y:\data\reading_longitude\templates\child_new\SIRL54warp3';%This is for Windows!!!   check this is updated
    outDir = 'Y:\data\reading_longitude\templates\child_new\subgroups_y1';
else
    inDir = '/biac2/wandell2/data/reading_longitude/templates/child_new/SIRL54warp3';%check this is updated
    outDir = '/biac2/wandell2/data/reading_longitude/templates/child_new/subgroups_y1';
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
    avg.b0 = mrAnatHistogramClip(double(avg.b0),0.5,0.99);
    avg.anat.img = mrAnatHistogramClip(double(avg.anat.img),0.5,0.99);
    if(isfield(avg.anat,'brainMask'))
        avg.anat.brainMask = double(avg.anat.brainMask);
    end
    if(isfield(avg,'dtBrainMask'))
        avg.dtBrainMask = double(avg.dtBrainMask);
    end
    Nb0 = double(avg.b0>0);
    Nt1 = double(avg.anat.img>0);

    for(jj=2:N)
        disp(['Loading ' files{averageThese(jj)} '...']);
        dt = load(files{averageThese(jj)});
        dt.dt6(isnan(dt.dt6)) = 0;
        b0 = mrAnatHistogramClip(double(dt.b0),0.5,0.99);
        b0(isnan(b0)) = 0;
        avg.b0 = avg.b0+b0;
        avg.dt6 = avg.dt6+dt.dt6;
        if(isfield(avg,'dtBrainMask')&& isfield(dt,'dtBrainMask'))
            avg.dtBrainMask = avg.dtBrainMask+dt.dtBrainMask;
        end
        t1 = mrAnatHistogramClip(double(dt.anat.img),0.5,0.99);
        t1(isnan(t1)) = 0;
        avg.anat.img = avg.anat.img+t1;
        if(isfield(avg.anat,'brainMask') && isfield(dt.anat,'brainMask'))
            avg.anat.brainMask = avg.anat.brainMask+double(dt.anat.brainMask);
        end
        Nb0 = Nb0+double(b0>0);
        Nt1 = Nt1+double(t1>0);
    end
    avg.b0(Nb0>0) = avg.b0(Nb0>0)./Nb0(Nb0>0);
    for(ii=1:6)
        tmp = avg.dt6(:,:,:,ii);
        tmp(Nb0>0) = tmp(Nb0>0)./Nb0(Nb0>0);
        avg.dt6(:,:,:,ii) = tmp;
    end
    avg.anat.img(Nt1>0) = avg.anat.img(Nt1>0)./Nt1(Nt1>0);
    if(isfield(avg.anat,'brainMask'))
        avg.anat.brainMask = avg.anat.brainMask./N;
    end
    if(isfield(avg,'dtBrainMask'))
        avg.dtBrainMask = avg.dtBrainMask./N;
    end
    % Apply a new dt mask based on the average B0
    mask = dtiCleanImageMask(avg.b0>0.3, 5);
    avg.dt6(repmat(~mask, [1,1,1,6])) = 0;
    rmfield(avg,'notes');
    avg.notes.dataFiles = {files{averageThese}};
    avg.notes.createdOn = datestr(now,31);
    avg.notes.subgroupName = curGroup;
    fid=fopen(which(thisfilename),'rt');thisScript=fread(fid);fclose(fid);
    avg.notes.buildScript = char(thisScript');
    newFileName = fullfile(outDir, curGroup,['average_y1_' curGroup '_N' num2str(N) '.mat']);
    disp(['Saving to ' newFileName '...']);
    dtiSaveStruct(avg, newFileName);
    clear avg
end

