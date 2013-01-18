function distmsr=mean_covariance_distances(fibergroup)

%Compute pairwise distances between 9-feature mean and covariance vectors
%among fibers in a fibergroup

%ER SCSNL 2007
for i=1:size(fibergroup, 1)
   for j=i:size(fibergroup, 1)

[mu1, sigma1]=dtiFiberNormalMoments(fibergroup{i});
[mu2, sigma2]=dtiFiberNormalmoments(fibergroup{j});

distmsr(i, j)=sqrt(sum(([mu1 sigma1]-[mu2 sigma2]).^2));
%Skip on the sqrt when computing euclidian distance
   end
%display(['i=' num2str(i)]); 
end

