function dataOut=plotMultipleParamVsDistance(view,roiList,plotParam,scanNum,binSize,plotFlag)
% dataOut=plotMultipleParamVsDistance(view,[plotParam],[scanNum],[ROIData],[binSize],[plotFlag])
% Wrapper for plotMultipleParamVsDistance: 
% 
% arw : 071005: Wrote it.
% 

% Do the usual checks
if (ieNotDefined('view'))
    error('You must supply a view');
end

if (ieNotDefined('roiList')) 
    
    nROIs=size(view.ROIs,2);
    roiList=cell(1,nROIs);
    
    for r=1:nROIs
        roiList{r}=view.ROIs(r).name;
    end
    
    selectedROIs = find(buttondlg('ROIs to Plot',roiList));
    nROIs=length(selectedROIs);
    
    if (nROIs==0)
        error('No ROIs selected');
    end
    
    roiList=selectedROIs;
end % End check on roiList

if (ieNotDefined('plotParam'))
    disp('Setting plotParam to ph by default');
    plotParam='ph';
end

if (ieNotDefined('scanNum'))
    disp('Setting scan num to current scan');
    scanNum=view.curScan;
end

if (ieNotDefined('binSize'))
    disp('Setting bin size to 4mm');
    binSize=4;
end

if (ieNotDefined('plotFlag'))
disp('Not plotting the data');
    plotFlag=0;
end

% Loop over all the ROIs in roiList : Exctract the ROI data and send it in to plotParamVsDistance

nROIs=length(roiList);

for thisROI=1:nROIs
    ROIdata=view.ROIs(roiList(thisROI));
    disp(ROIdata)
    
    retData = plotParamVsDistance(view, plotParam, scanNum, ROIdata, binSize, plotFlag);
    % The data we want are actually in dataOut.bins   
    % We do some extra work here to present them in an intuitive manner.
    nBins=length(retData.bins);
    meanPh=zeros(nBins,1);
    cumDist=zeros(nBins,1);
    for thisBin=1:nBins
       disp( retData.bins(thisBin).allPh)
       meanPh(thisBin)=mean(retData.bins(thisBin).allPh);
       distList(thisBin)=retData.bins(thisBin).distToPrev;    
    end
    cumDist=cumsum(distList);
    dataOut{thisROI}.cumDist=cumDist;
    dataOut{thisROI}.meanPh=meanPh;
    dataOut{thisROI}.distList=distList;
    
end


% That's it.
