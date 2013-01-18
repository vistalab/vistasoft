function HierarchicalClustering(FiberGroupFile, numNodesToResample, NumFibersPerPartition, maxDistanceOfInterest, NClusters)

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
%fibersReorderedByDistance=driReorderFibersByDistance(fg)
fg=dtiReorderFibersByDistance(fg);
ReorderedFiberGroupFileName=[FiberGroupFileName 'ReorderedByDistance'];
save(ReorderedFiberGroupFileName, 'fg', 'versionNum', 'coordinateSpace');
 display('Reordered by Distance');
 
%1. Resample originalFibersFile ->ResampledFibers

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



%3. Go through FIBER partitions and cluster them, creating master clusterLabels

clusterlabelsAll=[];
totalclusterssofar=0;

['Partitions_of_' ReorderedFiberGroupFileName 'Resampled.txt']
allPartitions= readFileList(['Partitions_of_' ReorderedFiberGroupFileName 'Resampled.txt']);
cd('fgFile_Parts');

for PartitionId=1:size(allPartitions, 1)

   if size(dir(['clusterlabels' filesep char(allPartitions(PartitionId))]))>0
    load(['clusterlabels' filesep char(allPartitions(PartitionId))])
    display(['Loaded previously clustered fibers for partition ' char(allPartitions(PartitionId))]);

   else

       %[clusterlabels]=ClusterFibers(char(allPartitions(PartitionId)), maxDistanceOfInterest, NClusters);
       %^^THIS PART IS REPLACED BY CLUSTER-SPECIFIC PART BELOW
        unix(['/home/elenary/project_scripts/full_brain_clustering/cluster_fibers.batch.job ' char(allPartitions(PartitionId)) ' ' num2str(maxDistanceOfInterest) ' ' num2str(NClusters)]);
       display(['Fibers clustered for partition ' char(allPartitions(PartitionId))]);
   end

end

%Check if the jobs are completed, then load computed cluster labels
a=[];
while size(a, 1)<size(allPartitions, 1)
    a=dir('*clusterlabels.mat');
    pause(2);
end
        unix(['ls *clusterlabels.mat > ' ReorderedFiberGroupFileName 'Resampled.txt']);

        
for PartitionId=1:size(allPartitions, 1)

[pathstrCL, NameCL, extCL, versnCL] = fileparts(char(allPartitions(PartitionId))); 
load([NameCL 'clusterlabels']);
clusterlabelsAll=[clusterlabelsAll; clusterlabels+totalclusterssofar];
totalclusterssofar=totalclusterssofar+max(clusterlabels);

end


%RECURSIVE PART START
%3. Create COMPUTE SUPERFIBERREPRESENTATION for the full original FiberSet
%DECIDE ON: levels; NumSuperFibersPerPartition, NClusters on every level
level=0;
    NumSuperFibersPerPartition=NumFibersPerPartition;  NSFClusters=NClusters; %maxDistanceOfInterest=40; %4cm 

while size(allPartitions, 1)>1
    level=level+1;



    cd('../..'); %To go back up from fgFile_Parts->up, ResampledFolder -->up
    load(ResampledFiberGroupFile);
    display('Computing Superfiber Means');
    SuperFibersGroup = dtiComputeSuperFiberMeans(fg, clusterlabelsAll);
    display('Superfibers Created');

    fg=SuperFibersGroup;
    ParentFiberGroupFile=[ResampledFiberGroupFile '.mat'];
    SuperFiberGroupFileName=['SuperFibersOf_' ReorderedFiberGroupFileName 'Resampled_Level' num2str(level)];
    SuperFiberGroup=fullfile(pathstr, ResampledFolder, SuperFiberGroupFileName);
    save(SuperFiberGroup, 'ParentFiberGroupFile', 'clusterlabelsAll', 'maxDistanceOfInterest', 'fg', 'coordinateSpace', 'versionNum');

    display(max(clusterlabelsAll))

    %Cluster the SuperFibers and update master clusterlabelsAll
    cd(ResampledFolder)
    FractionizeFiberDataSet(SuperFiberGroupFileName, NumSuperFibersPerPartition); %Partitions will be saved un fgFile_Parts dir
    %Go through FIBER partitions and cluster them, creating master clusterLabels
    %We have here clusterlabelsALL
    
    allPartitions= readFileList(['Partitions_of_' SuperFiberGroupFileName '.txt']);
    cd('fgFile_Parts');
    
    clusterlabelsCurrAll=clusterlabelsAll; %Labels from the current level
    thisleveltotalclusterssofar=0;
    
    for SFPartitionId=1:size(allPartitions, 1)


if size(dir(['clusterlabels' filesep char(allPartitions(SFPartitionId))]))>0
    load(['clusterlabels' filesep char(allPartitions(SFPartitionId))])
    display(['Loaded previously clustered fibers for partition ' char(allPartitions(SFPartitionId))]);
else
        [clusterlabels]=ClusterFibers(char(allPartitions(SFPartitionId)), maxDistanceOfInterest, NSFClusters);

        display(['SuperFibers clustered for partition ' char(allPartitions(SFPartitionId))]);
        %Udate the portion of clusterlabelsAll pertaining to current partition
        %of superfiberset only
end
        for SuperFiberId=1:min(NumSuperFibersPerPartition, size(clusterlabels, 1))
            clusterlabelsAll(find(clusterlabelsCurrAll==SuperFiberId+(SFPartitionId-1)*NumSuperFibersPerPartition), 1)=clusterlabels(SuperFiberId)+thisleveltotalclusterssofar;
        end
        thisleveltotalclusterssofar=thisleveltotalclusterssofar+max(clusterlabels);


    end
    
end %while size(allPartitions, 1)>1


%So we have a single partition of SuperFibers for which clustering has just
%been performed. Save the results. 

    level=level+1;

    cd('../../'); %To go back up from fg_FileParts -up, ResampledFolder -->up
    load(ResampledFiberGroupFile);
    SuperFibersGroup = dtiComputeSuperFiberMeans(fg, clusterlabelsAll);
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
