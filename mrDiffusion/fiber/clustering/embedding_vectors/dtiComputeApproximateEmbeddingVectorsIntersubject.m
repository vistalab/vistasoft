function [E]=dtiComputeApproximateEmbeddingVectorsIntersubject(fgfile, NfibersInA, npoints, kernelsigma, nvec) 

%Computes embedded coordinates on a large fiberset
%Parameters: full fiber set (fgfile)
% NSamples: how many fibers form the "A" marix (full affinity matrix).
% Recommended: 15%
%npoints (nodes in a resampled fiber)
%Note that your sample for A matrix will be picked from the first
%NfibersInA fibers. I is therefore crucial that the original fiberset is
%reshuffled using  fg = ShuffleFibers(fg) before it is passed into this
%function. 

%This function is different from dtiComputeApproximateEmbeddingVectors
%because the infinities computed are weighted by curvature correlations. 

%Kernel is a parameter used for gaussian transformation from distances to
%affinities  (sigma of affinity=-distance^2/sigmasquare)

%ER 03/2008

load(fgfile); 
NoFibersTotal=size(fg.fibers, 1); 

%Compute distances for A. Compute distances for B. 
range1start=1; range2start=1; range1end=NfibersInA; range2end=NoFibersTotal;
method='pairwise_dist';

compute_interfiber_distances(fgfile, npoints, method, range1start, range1end, range2start,  range2end);
%This will save some intermediate results on disk. 

outfile=[fgfile 'dist' num2str(range1start) 'to' num2str(range1end) 'vs' num2str(range2start) 'to' num2str(range2end)];

%Transform distances into proximities. Use kernel sigma=30; That makes sigmasquare=900.
load(outfile); 
distmsr(1:NfibersInA, 1:NfibersInA)=(distmsr(1:NfibersInA, 1:NfibersInA)'+distmsr(1:NfibersInA, 1:NfibersInA))./2;
%just to fix assymmetry which shldnt be there  btw. 


affinities=dtiComputeAffinitiesFromDistances(distmsr, kernelsigma);	clear distmsr; 
clear fibergroup1 fibergroup2

%%%%%Compute curvatures -- VERY STRAIGHFORWARD APPROACH CURRENTLY NOT SCALED TO
%THE SIZE OF THE ORIGINAL FIBERSET
load(fgfile);
[fibercurvatures]=dtiComputeFiberGroupCurvatures(dtiResampleFiberGroup(fg, 15));
fibercurvatures(fibercurvatures>std(fibercurvatures(:))*3)= std(fibercurvatures(:))*3;
curvacorrs=corrcoef(fibercurvatures'); 

figure; subplot(3, 1, 1); imagesc(affinities); subplot(3, 1, 2); imagesc(abs(curvacorrs(range1start:range1end, range2start:range2end)));
affinities=affinities.*(curvacorrs(range1start:range1end, range2start:range2end));
subplot(3, 1, 3); imagesc(affinities);
%%%%%%END COMPUTE CURVATURES

%Perform estimation such that the size of B matrix is 5xSizeOfA which makes
%A about 20%
NSamples=min(NoFibersTotal, NfibersInA*5);

A=affinities(1:NfibersInA, 1:NfibersInA);
B=affinities(1:NfibersInA, NfibersInA+1:NSamples);
clear affinities;

%Compute embedding vectors; 
[E, embbasis]=dtiApproximateEmbeddingVectors(A, B, nvec);
display('Embedded space basis computed'); 

clear B;


maxcurr=NSamples; 

while maxcurr<NoFibersTotal

display(['Embedding fibers ' num2str(maxcurr+1) ' to' num2str(min(maxcurr+NSamples, NoFibersTotal))]);  
load(outfile); 
distmsr(1:NfibersInA, 1:NfibersInA)=(distmsr(1:NfibersInA, 1:NfibersInA)'+distmsr(1:NfibersInA, 1:NfibersInA))./2;
%just to fix assymmetry which shldnt be there  btw. 
affinities=dtiComputeAffinitiesFromDistances(distmsr, kernelsigma);	clear distmsr; 

clear fibergroup1 fibergroup2
S=affinities(1:NfibersInA, (maxcurr+1):min(maxcurr+NSamples, NoFibersTotal));
%%%%% TO ACCOUNT FOR CURVATURES
S=S.*curvacorrs(1:NfibersInA, (maxcurr+1):min(maxcurr+NSamples, NoFibersTotal)); %THIS WEIGHTING BY CURVATURE CORRELATIONS
%%%END ACCOUNTING FOR CURVATURES

clear affinities;

E=[E; NewDataOntoEmbeddingVectors(A, S, embbasis, nvec)];
maxcurr=maxcurr+NSamples;
end



%The next step will be computing actual clustering which we will put into a
%different function in case we wanted to stop here and use current embedded
%vectors for atlas creation purposes. 


save([fgfile 'EV'], 'E', 'embbasis', 'NfibersInA', 'npoints', 'kernelsigma', 'nvec');
