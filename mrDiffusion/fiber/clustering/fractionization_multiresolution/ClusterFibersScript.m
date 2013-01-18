function ClusterFibersScript(FiberGroupFile, maxDistanceOfInterest, NClusters, numNodesToResample, SuperFibersFolder)

%This is old version for clustering using Multiresolution Approach and
%Fractionizing dataset

%Given a file with fibers, cluster fibers, create superfiber
%representations and save them as a group of superfibers. 
%[clusterlabels]=ClusterFibers(FiberGroupFile, maxDistanceOfInterest, NClusters) ; %These parameters will be compiled together with...
%SuperFibersGroup = dtiComputeSuperFiberRepresentation(fg, clusterlabels);
%save SuperFibersGroup as just yet another fibergroup (plus clusterlabels and the reference to the original fibers of the original file -- like "parent" filename)
%(clustering parameters also saved in that file)
%ER 02/2008 SCSNL

warning off; 
%Make all parameters numerical;
if ischar(maxDistanceOfInterest) 
    maxDistanceOfInterest=str2num(maxDistanceOfInterest);
end

if ischar(NClusters) 
    NClusters=str2num(NClusters);
end

if ischar(numNodesToResample) 
    numNodesToResample=str2num(numNodesToResample);
end


load(FiberGroupFile); 


%RESAMPLE FIBERS
%ResampledFiberGroup=resampleFiberGroup(fg, numNodesToResample);
fg=resampleFiberGroup(fg, numNodesToResample);

[pathstr, FiberGroupFile, ext, versn] = fileparts(FiberGroupFile); 
if isempty(pathstr)
    pathstr=['.' filesep ];
end

    
ResampledFolder=['FibersResampledTo' num2str(numNodesToResample)];
mkdir(pathstr, ResampledFolder);
ResampledFiberGroupFile=fullfile(pathstr, ResampledFolder, [FiberGroupFile 'Resampled']);
save(ResampledFiberGroupFile, 'fg', 'coordinateSpace', 'versionNum'); 
clear fg coordinateSpace versionNum; %Saving memoryl

%CLUSTER FIBERS
[clusterlabels]=ClusterFibers(ResampledFiberGroupFile, maxDistanceOfInterest, NClusters);
display('Fibers clustered');

load(ResampledFiberGroupFile);

%COMPUTE SUPERFIBERREPRESENTATION
SuperFibersGroup = dtiComputeSuperFiberRepresentation(fg, clusterlabels);
display('Superfibers Created');

%CREATE A FOLDER FOR SUPERFIBERS
[s, mess, messid] = mkdir(fullfile(pathstr,ResampledFolder), SuperFibersFolder);


ParentFiberGroupFile=ResampledFiberGroupFile;
fg=SuperFibersGroup;

outputname=fullfile(pathstr, ResampledFolder, SuperFibersFolder,  ['SuperFibersOf_' FiberGroupFile 'Resampled']);
save(outputname, 'ParentFiberGroupFile', 'clusterlabels', 'maxDistanceOfInterest', 'fg', 'coordinateSpace', 'versionNum');

warning on; 