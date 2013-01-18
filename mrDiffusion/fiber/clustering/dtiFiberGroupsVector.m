function [fibergroupsvector3] = dtiFiberGroupsVector(IDX, minNumFibersInCluster)

%Given a vector IDX with clustering labels, form a vector of clusters that have
%at least minNumFibersInCluster elements

%Useful to use with dtiSaveFiberClusters  to save only clusters with
%greater number of fibers

%ER 04/2008

if(~exist('minNumFibersInCluster','var')||isempty(minNumFibersInCluster))
    minNumFibersInCluster = 1;
end


fibergroupsvector3=[];
for clust=1:max(IDX)
if size(find(IDX==clust), 1)>minNumFibersInCluster; 
fibergroupsvector3=[fibergroupsvector3 clust];
end
end