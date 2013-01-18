function fiberindices = dtiFindFGOI(referenceFgE, targetFgE, numNvecs2match)

%Find fibers in an ROI (defined as FG ROI)
%Given two sets of embedding vectors, this function finds a subset of the subset-2
%that best matches the subset-1. 

%Arguments: 
%1. Embedded vectors for Reference FGOI group
%2. Embedded vectors for the targe space of fibers from where
%FGOI-corresponding set of fibers will be extracted. 
%3. numNvecs2match: how many top vectors shoudl be used

%Returns fiberindices corresponding to the fibers from E (subset-2)

%match criteria: 
%When a new fiber's first 5 nvecs fall within the range of 5 first nvecs of
%referenceFgE

%ER 04/13/2008

lowerbound=min(referenceFgE(:, 1:numNvecs2match));
upperbound=max(referenceFgE(:, 1:numNvecs2match));

fiberindices=[];

for i=1:size(targetFgE, 1)
    
if (sum(targetFgE(i, 1:numNvecs2match)>lowerbound)==numNvecs2match) &&(sum(targetFgE(i, 1:numNvecs2match)<upperbound)==numNvecs2match)
%TODO: not box but a convex hull to match fiber group representations in
%the embedded space

fiberindices=[fiberindices;i];
end
end




