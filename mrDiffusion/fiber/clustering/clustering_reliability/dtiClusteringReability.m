function frac=dtiClusteringReability(E, reps, nClusters)
%O'Donnell PhD Thesis (2006): measure clustering solution reliability
%We quantified this clustering variability by testing whether pairs
%of data points (paths from tractography) clustered always in the same cluster, never
%in the same cluster, or sometimes in the same and sometimes in different clusters.
%The fraction of pairs that sometimes were in the same cluster, and sometimes in
%different clusters, was measured for various numbers of clusters -- thus
%producing evaluation graph

%"In any case, the fraction of pairs that are inconsistent is less than 5 percent for any number of clusters greater
%than about 75."
nFibers=size(E, 1); 
nPairs=nFibers*(nFibers-1)/2;
reps=500; nClusters=23; 

for  rep=1:reps
rep
[IDX(:, rep), C(:, : , rep)]=kmeans(E, nClusters);
end
same=zeros(1, reps);
for fiber1=1:size(E, 1)
fiber1
for fiber2=fiber1+1:size(E, 1)
%For those that are sometimes in same, sometimes in differnt
%clusters == "clusters that were not always in the same or always in
%different clusters" . The lowest values show best performance

if sum(IDX(fiber1, :)==IDX(fiber2, :))>0 & sum(IDX(fiber1, :)==IDX(fiber2, :))<reps
same(sum(IDX(fiber1, :)==IDX(fiber2, :)))=            same(sum(IDX(fiber1, :)==IDX(fiber2, :)))+1;
end
end
end

%Fraction of pairs of fibers always in different or always (out of reps) in same
%clusters. "consistency" index.
frac=1-sum(same(:))/nPairs;

