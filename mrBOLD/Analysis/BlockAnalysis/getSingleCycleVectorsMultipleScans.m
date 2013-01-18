function multipleCycleVectors=getSingleCycleVectorsMultipleScans(view,scanList,coords)
% multipleCycleVectors=getSingleCycleVectorsultipleScans(view,scanList,coords)
% PURPOSE: Concatenates the output for 'getSingleCycleVectors' over a set of scans.
% Ultimately, will allow you to compute TCirc statistic using many scans
% AUTHOR: ARW wade@ski.org 020705
% $date$
% Note: Does not accept the 'coords' param at the moment. 


mrGlobals

if (~exist('scanList','var') | isempty(scanList)), scanList = selectScans(view); end

% Pre-allocate the huge array that will hold the vectors
% (x*y)*nSlices*nCycles*nScans

% We are going to concatenate so all the dimensions for the different scans
% must match
checkScans(view,scanList);

nScans=length(scanList);


nCycles = numCycles(view,scanList(1));
currentDataType=view.curDataType;
dt=dataTYPES(currentDataType);
blockSize=dt.scanParams(scanList(1)).cropSize;
nSlices=length(dt.scanParams(scanList(1)).slices);
singleCycleVectors=zeros(blockSize(1)*blockSize(2),nSlices,nCycles);
multipleCycleVectors=zeros(blockSize(1)*blockSize(2),nSlices,nCycles,nScans);

for thisScan=1:nScans
    disp(thisScan);
    
    singleCycleVectors=getSingleCycleVectors(view,scanList(thisScan));
    multipleCycleVectors(:,:,:,thisScan)=singleCycleVectors;
end

    
return;
