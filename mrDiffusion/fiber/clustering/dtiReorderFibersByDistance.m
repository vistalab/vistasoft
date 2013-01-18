function fibersReorderedByDistance=dtiReorderFibersByDistance(fg)
%fibersReorderedByDistance=dtiReorderFibersByDistance(FiberGroup)
%computes matrix of distances for seeds and finds the reordering (use symrcm) of proximity matrix such that the distance between the neighbouring seeds is minimized. 
%This reordering is applyed to fibers and a new dataset is produced.
%ER 02/2008 SCSNL

%Note that matlab memory would be most comfortable working with fiber seed
%groups of 1,000

stepS=1000; 

fibersReorderedByDistance=fg;  %Create a copy

numFibers=size(fg.seeds,1); 

for chunkofSeeds=1:stepS:numFibers; 
    min(chunkofSeeds+(stepS-1), numFibers);
display([ num2str(chunkofSeeds) ' of ' num2str(numFibers)])    
InterSeedDistances=pdist(fg.seeds(chunkofSeeds:min(chunkofSeeds+(stepS-1), numFibers), :), 'euclidean');
InterSeedDistancesSquareForm=squareform(InterSeedDistances);
InterSeedProximitiesSquareForm=1-InterSeedDistancesSquareForm;
InterSeedProximitiesSquareForm(find(InterSeedProximitiesSquareForm<.95))=0;




newOrder=symrcm(sparse(InterSeedProximitiesSquareForm));
fibersReorderedByDistance.seeds(chunkofSeeds:min(chunkofSeeds+(stepS-1), numFibers), :)=fg.seeds(chunkofSeeds-1+newOrder, :); 
fibersReorderedByDistance.fibers(chunkofSeeds:min(chunkofSeeds+(stepS-1), numFibers), :)=fg.fibers(chunkofSeeds-1+newOrder);
end


