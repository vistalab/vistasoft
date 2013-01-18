function ResampledFiberGroup=dtiResampleFiberGroup(fg, value, flag)
%ResampledFiberGroup=resampleFibers(fiberGroup, numNodes, 'N')
%ResampledFiberGroup=resampleFibers(fiberGroup, stepSize, 'L')
%Resamples the fibers so that each has number of nodes = value (if flag=='N')
%or to fibers of step size = value (flag=='L')

%ER 02/2008 SCSNL
warning off;

if ~exist('flag', 'var') || isempty(flag)
flag='N'; 
end

ResampledFiberGroup=fg; 

numFibers=size(fg.fibers,1); 

for fiberIndex=1:numFibers
ResampledFiberGroup.fibers{fiberIndex}=dtiFiberResample(fg.fibers{fiberIndex}, value, flag);
end
 warning on; 