function EvaluationMetric = kmeansScreePlot(E, maxNclusters)
%Build a scree plot for k-means clustering of fibers applied to their embedded
%space representation

%Input: E(Nxnvecs) (loadings of N fibers in the embedded space of nvecs dimensions)
%maxNclusters (optional) is the largest number of clusters you want to allow
%if not provided, will be set to N
%Will perform  clustering maxNclusters times and will produce a scree plot  (evaluation graph)
%Returns a vector of EvaluationMetric s for 1-N clusters

%ER 09/2008 SCSNL wrote it

N=size(E, 1); 

if (nargin<2)
    maxNclusters=N; 
end

for dim=2:maxNclusters
display(['Performing clustering for N=' num2str(dim)]);
[IDX, C]=kmeans(E, dim, 'emptyaction', 'singleton');
EvaluationMetric(dim)=min(pdist(C).^2);
end

figure; plot(EvaluationMetric); 
%Metric used in evaluation graph should be the same as the metric used in
%the clustering algorithm
%Kmeans default: Squared Euclidean distance 
%pdist(C)^2; --pdist uses Euclidean as a default  