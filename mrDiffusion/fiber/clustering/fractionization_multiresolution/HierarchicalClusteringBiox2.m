function HierarchicalClusteringBiox2(FiberGroupFile, numNodesToResample, NumFibersPerPartition, maxDistanceOfInterest, NClusters)

%Make all parameters numerical;
if ischar(numNodesToResample) 
    numNodesToResample=str2num(numNodesToResample);
end

%Make all parameters numerical;
if ischar(NumFibersPerPartition) 
    NumFibersPerPartition=str2num(NumFibersPerPartition);
end


%Make all parameters numerical;
if ischar(maxDistanceOfInterest) 
    maxDistanceOfInterest=str2num(maxDistanceOfInterest);
end


%Make all parameters numerical;
if ischar(NClusters) 
    NClusters=str2num(NClusters);
end

warning off; 

[pathstr, FiberGroupFileName, ext, versn] = fileparts(FiberGroupFile); 
if isempty(pathstr)
    pathstr=['.' filesep ];
end

%0 Reorder fibers by distance among seeds
load(FiberGroupFile); 
%fibersReorderedByDistance=dtiReorderFibersByDistance(fg)
fg=dtiReorderFibersByDistance(fg);
ReorderedFiberGroupFileName=[FiberGroupFileName 'ReorderedByDistance'];
save(ReorderedFiberGroupFileName, 'fg', 'versionNum', 'coordinateSpace');
 display('Reordered by Distance');
 
%1. Resample originalFibersFile ->ResampledFibers
%Make all parameters numerical;
if ischar(numNodesToResample) 
    numNodesToResample=str2num(numNodesToResample);
end

fg=resampleFiberGroup(fg, numNodesToResample);

ResampledFolder=['FibersResampledTo' num2str(numNodesToResample)];
mkdir(pathstr, ResampledFolder);
ResampledFiberGroupFile=fullfile(pathstr, ResampledFolder, [ReorderedFiberGroupFileName 'Resampled']);
save(ResampledFiberGroupFile, 'fg', 'coordinateSpace', 'versionNum'); 
clear fg coordinateSpace versionNum; %Saving memoryl
display('Resampled');

%2. Partition ResampledFiberGroupFile by chunks of
%size=NumFibersPerPartition
cd(ResampledFolder)
dtiFractionizeFiberDataSet([ReorderedFiberGroupFileName 'Resampled'], NumFibersPerPartition);

cd('fgFile_Parts')

%3. Go through FIBER partitions and cluster them, creating master clusterLabels
clusterlabelsAll=[];
allPartitions=dir([ReorderedFiberGroupFileName 'Resampled' '*.mat']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%THIS PART IS SPECIFIC TO BIOX2CLUSTER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for PartitionId=1:size(allPartitions, 1)

%[clusterlabels]=ClusterFibers(allPartitions(PartitionId).name, maxDistanceOfInterest, NClusters);
%the two lines below perform clustering by submitting a job ^^
unix(['/home/elenary/project_scripts/full_brain_clustering/cluster_fibers.batch.job ' allPartitions(PartitionId).name ' ' num2str(maxDistanceOfInterest) ' ' num2str(NClusters)]);
display(['Fibers clustered for partition ' allPartitions(PartitionId).name]);
end

%Check if the jobs are completed, then load computed cluster labels
a=[];
while size(a, 1)<size(allPartitions, 1)
    a=dir('*clusterlabels.mat');
    pause(2);
end
        unix(['ls *clusterlabels.mat > ' ReorderedFiberGroupFileName 'Resampled.txt']);

for PartitionId=1:size(allPartitions, 1)

[pathstrCL, NameCL, extCL, versnCL] = fileparts(allPartitions(PartitionId).name); 
load([NameCL 'clusterlabels']);
clusterlabelsAll=[clusterlabelsAll; clusterlabels+NClusters*(PartitionId-1)];
end

%cleanup temp files
unix(['rm *clusterlabels*']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%END OF CLUSTER SPECIFIC PART%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%RECURSIVE PART START
%3. Create COMPUTE SUPERFIBERREPRESENTATION for the full original FiberSet
%DECIDE ON: levels; NumSuperFibersPerPartition, NClusters on every level
level=0;
    NumSuperFibersPerPartition=NumFibersPerPartition;  NSFClusters=NClusters; %maxDistanceOfInterest=50; %5cm
display('Start recursion');

while size(allPartitions, 1)>1
    level=level+1;



    cd('../../'); %To go back up from fg_FileParts -up, ResampledFolder -->up
    load(ResampledFiberGroupFile);
    display(['Computing superfiber representations at level ' num2str(level)]);
    tic; SuperFibersGroup = dtiComputeSuperFiberRepresentation(fg, clusterlabelsAll); toc;
    display('Superfibers Created');

    fg=SuperFibersGroup;
    ParentFiberGroupFile=[ResampledFiberGroupFile '.mat'];
    SuperFiberGroupFileName=['SuperFibersOf_' ReorderedFiberGroupFileName 'Resampled_Level' num2str(level)];
    SuperFiberGroup=fullfile(pathstr, ResampledFolder, SuperFiberGroupFileName);
    save(SuperFiberGroup, 'ParentFiberGroupFile', 'clusterlabelsAll', 'maxDistanceOfInterest', 'fg', 'coordinateSpace', 'versionNum');

    %Cluster the SuperFibers and update master clusterlabelsAll
    cd(ResampledFolder)
    FractionizeFiberDataSet(SuperFiberGroupFileName, NumSuperFibersPerPartition); %Partitions will be saved un fgFile_Parts dir
    cd('fgFile_Parts')
    %Go through FIBER partitions and cluster them, creating master clusterLabels
    %We have here clusterlabelsALL
    allPartitions=dir([SuperFiberGroupFileName '*mat']);
    clusterlabelsCurrAll=clusterlabelsAll; %Labels from the current level
        
    %%%%%%%%%%%THIS PART IS SPECIFIC TO BIOX2 CLUSTER
    %%%HERE WE ARE SUBMITTING BJOBS
    
    for SFPartitionId=1:size(allPartitions, 1)

       % [clusterlabels]=ClusterFibers(allPartitions(SFPartitionId).name, maxDistanceOfInterest, NSFClusters);
       unix(['/home/elenary/project_scripts/full_brain_clustering/cluster_fibers.batch.job ' allPartitions(SFPartitionId).name ' ' num2str(maxDistanceOfInterest) ' ' num2str(NSFClusters)]);
       display(['SuperFibers clustered for partition ' allPartitions(SFPartitionId).name]);
        %Udate the portion of clusterlabelsAll pertaining to current partition
        %of superfiberset only

        
    end

    %%%%%%%%%%%THIS PART IS SPECIFIC TO BIOX2 CLUSTER
    %%%HERE WE ARE READING RESULS OF SUBMITTED JOBS

        %Check if the jobs are completed, then load computed cluster labels
        a=[];
        while size(a, 1)<size(allPartitions, 1)
            a=dir('*clusterlabels.mat');
            pause(2);
        end
        unix(['ls *clusterlabels.mat > SuperFibersOf_' ReorderedFiberGroupFileName 'Resampled_Level' num2str(level) '.txt']);

    
    for SFPartitionId=1:size(allPartitions, 1)
    
        
        %Udate the portion of clusterlabelsAll pertaining to current partition
        %of superfiberset only
        [pathstrCLSF, NameCLSF, extCLSF, versnCLSF] = fileparts(allPartitions(SFPartitionId).name); 
        load([NameCLSF 'clusterlabels']);

        for SuperFiberId=1:min(NumSuperFibersPerPartition, size(clusterlabels, 1))
            clusterlabelsAll(find(clusterlabelsCurrAll==SuperFiberId+(SFPartitionId-1)*NumSuperFibersPerPartition), 1)=clusterlabels(SuperFiberId)+NSFClusters*(SFPartitionId-1);
        end

    end

        %cleanup temp files
        unix(['rm *clusterlabels*']);
    
    
end %while size(allPartitions, 1)>1


%So we have a single partition of SuperFibers for which clustering has just
%been performed. Save the results. 

    level=level+1;

    cd('../../'); %To go back up from fg_FileParts -up, ResampledFolder -->up
    load(ResampledFiberGroupFile);
    SuperFibersGroup = dtiComputeSuperFiberRepresentation(fg, clusterlabelsAll);
    display('Superfibers Created');

    fg=SuperFibersGroup;
    ParentFiberGroupFile=[ResampledFiberGroupFile '.mat'];
    SuperFiberGroupFileName=['SuperFibersOf_' ReorderedFiberGroupFileName 'Resampled_Level' num2str(level)];
    SuperFiberGroup=fullfile(pathstr, ResampledFolder, SuperFiberGroupFileName);
    save(SuperFiberGroup, 'ParentFiberGroupFile', 'clusterlabelsAll', 'maxDistanceOfInterest', 'fg', 'coordinateSpace', 'versionNum');
%Note: we are creating superfiber representation for
%ResampledFiberGroupFileName, not ReorderedFiberGroupFileName, because for
%computing SF representation the fibers need to be equisampled. 

%However, to create a good visualization of clustering results, we are
%encouraged to use 
%fg from ReorderedFiberGroupFileName
%and clusterlabelsAll from     SuperFiberGroupFileName

%fibergroupsvector=1:50;
%load(ReorderedFiberGroupFileName);
%dtiSaveFiberClusters(clusterlabelsAll, fibergroupsvector, fg, versionNum, coordinateSpace)
