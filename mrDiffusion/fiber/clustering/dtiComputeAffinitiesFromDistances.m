function affinities=dtiComputeAffinitiesFromDistances(distmsr, kernelsigma)

%This function tranforms euclidian distance - like measures into affinity
%using a gaussian kernel

sigmasq=kernelsigma^2; 
affinities=exp(-((distmsr.^2)./sigmasq));

