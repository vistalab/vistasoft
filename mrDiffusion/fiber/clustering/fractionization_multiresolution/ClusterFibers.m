function [clusterlabels]=ClusterFibers(FiberGroupFile, maxDistanceOfInterest, NClusters) 

%Perform clustering on the fibersubset: 

%b) compute interfiber distances using a multiresolution method or another method or whatnot
%c) Link and cluster the fibers using the distance matrix. 
%d) make NClusters clusters. Note that we will need to test if this parameter influences the results much. I imagine to start with Nclusters=100 (for a typical partition of 500 fibers). 
%When Nclusters is large, clusters naturally will include less fibers. 
%clusterlabels is a vector whose length is equal to the number of fibers in
%the FiberGroupFile, and that contains numbers 1:NCluster labeling each
%fiber as a member of one of the clusters. 

%Your fibers should be resampled to equal number of nodes each, otherwise
%the function will not work. Use ResampledFiberGroup=resampleFiberGroup(fg,
%numNodes) and save the resulting fiberGroup in an appropriate file. 

%ER 02/2008 SCSNL
epsilon=.000000001; 

%Make all parameters numerical;
if ischar(maxDistanceOfInterest) 
    maxDistanceOfInterest=str2num(maxDistanceOfInterest);
end


%Make all parameters numerical;
if ischar(NClusters) 
    NClusters=str2num(NClusters);
end

mkdir('clusterlabels');

%1. compute interfiber distances using a multiresolution method 
distance=compute_interfiber_distances_multires(FiberGroupFile, maxDistanceOfInterest);
%%Multiresolution approach: first approximation with mass_center distances,
%for the closest fibers pointwise average distance is computed for closest fibers.
%Will output a matrix that looks smth like %[FiberGroupFile 'distances_multires' num2str(range1start) 'to' num2str(range1end) 'vs' num2str(range2start) 'to' num2str(range2end) '.mat'];
%This matrix is sparse and haz zeros where the distances are too large to
%be of interest. 
%Note that here we naturally have a symmetric distanceSquared matrix. 

%2. Transform this symmetric distance matrix to vector format

%distance=full(distance);
distance(distance==0)=Inf; 
distance(distance==epsilon)=0; 
distance=squareform(full(distance), 'tovector'); 

%3 Cluster observation using a hierarchical clustering procedure; 

distanceLinked=linkage(distance);
clusterlabels=cluster(distanceLinked, 'maxclust', NClusters);


%%%%%%%%%%%OPTIONAL: VIZUALIZE%%%%%%%%%%%%%%%%%%%%%%%
%%This snippet of code is to check out how many of these clusters have more
%than 10 fibers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%TODO: PLOT THE FIBERS IN ACTUAL BRAIN COORDINATE SPACE

% 
% for clstr=1:max(clusterlabels)
% if size(find(clusterlabels==clstr),1) > 5
% [clstr size(find(clusterlabels==clstr), 1)]
% vis_fib_cluster(clstr, clusterlabels,  fibergroup1); title(['Cluster' num2str(clstr) ' nfibers ' num2str(size(find(clusterlabels==clstr), 1))]); 
% end
% end

[pathstr, FiberGroupFileName, ext, versn] = fileparts(FiberGroupFile); 
if isempty(pathstr)
    pathstr=['.' filesep ];
end

save(['clusterlabels' filesep FiberGroupFileName], 'clusterlabels');