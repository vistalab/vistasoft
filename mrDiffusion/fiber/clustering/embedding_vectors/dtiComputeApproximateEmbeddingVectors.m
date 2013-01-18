function [E]=dtiComputeApproximateEmbeddingVectors(fgfile, NfibersInA, method, npoints, kernelsigma, nvec) 

%[E]=dtiComputeApproximateEmbeddingVectors(fgfile, [NfibersInA=1500', [method='pairwise_dist'], [npoints=15], [kernelsigma=30   ], [nvec=15])

%Computes embedded coordinates on a large fiberset
%Parameters: full fiber set (fgfile)
% NfibersInA: how many fibers form the "A" marix (full affinity matrix).
% Recommended/max my laptom with 2GB RAM can handle is 1500
%npoints (nodes in a resampled fiber)
%Note that your sample for A matrix will be picked from the first
%NfibersInA fibers. I is therefore crucial that the original fiberset is
%reshuffled using  fg = dtiShuffleFibers(fg) before it is passed into this
%function. 

%Kernel is a parameter used for gaussian transformation from distances to
%affinities  (sigma of affinity=-distance^2/sigmasquare)

%ER 03/2008
%ER 11/2008 added default parameters

%TODO: = Specify recommended params
%= Add reshuffling by default
%= Add an option of using NfibersInA=size(fg.fibers, 2)

%%%%%%%%%%%%%%%%%%%%%%%%%
if(~exist('npoints','var')||isempty(npoints))
    npoints = 15;
end

if(~exist('kernelsigma','var')||isempty(kernelsigma))
    kernelsigma = 30; %30 for short distances, like clustering 1/2 brain; 60 for full brain distances
end

if(~exist('nvec','var')||isempty(nvec))
    nvec = 15;
end

if(~exist('method','var')||isempty(method))
    method = 'pairwise_dist';
end

if(~exist('NfibersInA','var')||isempty(NfibersInA))
    NfibersInA = 1500;
end


load(fgfile); 
NumFibersTotal=size(fg.fibers, 1); 
clear fg; 
if (NumFibersTotal<NfibersInA)
NfibersInA=NumFibersTotal;
end

%Compute distances for A. Compute distances for B. 
range1start=1; range2start=1; range1end=NfibersInA; range2end=NumFibersTotal;

compute_interfiber_distances(fgfile, npoints, method, range1start, range1end, range2start,  range2end, 1);
%If you want, use compute_interfiber_distances(fgfile, npoints, method, range1start, range1end, range2start,  range2end, 1);
%This will save some intermediate results on disk. 

outfile=[prefix(fgfile) 'dist' num2str(range1start) 'to' num2str(range1end) 'vs' num2str(range2start) 'to' num2str(range2end) method '.mat'];

%Transform distances into proximities. Use kernel sigma=30; That makes sigmasquare=900.
load(outfile); 

if (strcmp(method,'frenet'))

    
    for i=1:size(distmsr(:));
    distmsr(i)=log(distmsr(i));
    end

    distmsr(distmsr<-3)=-3; %rescale so that zero is the smalles distance
    distmsr= distmsr+3;
    distmsr(isinf(distmsr))=0;
end

%figure; hist(distmsr(:));
%kernelsigma=mean(distmsr(:))    ;

distmsr(1:NfibersInA, 1:NfibersInA)=(distmsr(1:NfibersInA, 1:NfibersInA)'+distmsr(1:NfibersInA, 1:NfibersInA))./2;
%just to fix assymmetry which shldnt be there  btw. 

affinities=dtiComputeAffinitiesFromDistances(distmsr, kernelsigma);	clear distmsr; 
clear fibergroup1 fibergroup2

%figure; hist(affinities(:));

%Perform estimation such that the size of B matrix is 5xSizeOfA which makes
%A about 20%

NSamples=min((NumFibersTotal-NfibersInA), NfibersInA*5);
%display(['Nsamples ' num2str(NSamples) ' NumFibersTotal ' num2str(NumFibersTotal) ' NFibersInA ' num2str(NfibersInA)]);
A=affinities(1:NfibersInA, 1:NfibersInA);
B=affinities(1:NfibersInA, NfibersInA+(1:NSamples));
clear affinities;

%Compute embedding vectors; 
[E, embbasis]=dtiApproximateEmbeddingVectors(A, B, nvec);
display('Embedded space basis computed'); 

clear B;


maxlast=NfibersInA+NSamples; 

while maxlast<NumFibersTotal

display(['Embedding fibers ' num2str(maxlast+1) ' to' num2str(min(maxlast+NSamples, NumFibersTotal))]);  

load(outfile); 
affinities=dtiComputeAffinitiesFromDistances(distmsr, kernelsigma);	clear distmsr; 
clear fibergroup1 fibergroup2
S=affinities(1:NfibersInA, (maxlast+1):min(maxlast+NSamples, NumFibersTotal));
clear affinities;

E=[E; dtiNewDataOntoEmbeddingVectors(A, S, embbasis, nvec)];
maxlast=maxlast+NSamples;
end



%The next step will be computing actual clustering which we will put into a
%different function in case we wanted to stop here and use current embedded
%vectors for atlas creation purposes. 


save([prefix(fgfile) 'EV' method], 'A', 'E', 'embbasis', 'npoints', 'kernelsigma', 'method');
