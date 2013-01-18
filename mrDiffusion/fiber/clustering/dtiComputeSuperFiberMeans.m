function SuperFibersGroup = dtiComputeSuperFiberMeans(fg, clusterlabels)
%Find the mean position of the super fiber in a group.
%
%   SuperFibersGroup=computeSuperFiberRepresentation(FiberGroup, clusterlabels)
%
% *** WARNING:  These comments might be wrong.  Elena should patch them up.
% *** BW
%
% The fiber group (fg) sent in has a cell array of fibers attached
% (fg.fibers{}).  
% Not sure what clusterlabels is.
%
% The SuperFiber is the single most-representative fiber in a cluster
% (label). It is assumed that they all the fibers with a common label are
% resampled to same length.  
%
% The returned group representations specificy the position of each node in
% the super fiber group.
%
% fg:  Fiber groups
% clusterlabels:  Integers defining different clusters.  The assignment
% between integers and cluster labels (real names) should be explicit
% somewhere (I think). BW
%
% Returned structure:
%
%  SuperFibersGroup.fibermeans: means (for every coordinate, every node)
%  SuperFibersGroup.n is number of fibers included in this cluster. 
%
% Example:
%
%
% Elena
%
SuperFibersGroup.name=[fg.name '_SuperFibers'];

%Fibergroup fg.fibers
%read into an array: 
nfibers  = size(fg.fibers, 1); % Number of fibers in this group

% We assume all fibers have the same number of nodes
numNodes = size(fg.fibers{1}, 2);   

% (x,y,z) position of the nodes for each nfiber value.
% I am not sure if nfibers is nclusters or nfibers within a cluster.
% I am also confused about the relationship between clusterlabels and the
% fiber groups and fibers.  Please explain.
curves   = zeros(3, numNodes, nfibers);

% Cumulate all of the fibers in this fiber group into a 3D matrix whose
% entries are (x,y,FiberNumber)
for ii = 1:nfibers
    curves(:, :, ii) = fg.fibers{ii};
end

%For every cluster, there should be a superfiber representation. Loop
%through the cluster labels
for clust=1:max(clusterlabels)
    
    % Count how many fibers have the current label
    SuperFibersGroup.n(clust, 1)=size(find(clusterlabels==clust), 1);
    
    % There may be none
    if SuperFibersGroup.n(clust, 1)==0
        % fprintf('No fibers for cluster %.0f\n',clust)
        display(['No fibers for cluster: ' num2str(clust)]);
    end

    %Calculate the mean position the super fiber at each node of the curves
    %in this cluster
    SuperFibersGroup.fibers{clust, 1}(:, :) = ...
        mean(curves(:, :, clusterlabels==clust), 3);

end %clust
