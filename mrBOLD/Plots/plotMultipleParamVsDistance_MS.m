function [dataOut,ROIdistanceList]=getMultipleParamVsDistance_MS(flatView,grayView,roiList,plotParam,scanList,binSize)
% [dataOut,distanceList]=getMultipleParamVsDistance_MS(flatView,grayView,roiList,plotParam,scanList,binSize,plotFlag)
% Wrapper for plotParamVs3DDistance: 
% Returns an array that is nScans*nROIs*nDataPoints
% So it'll loop over all scans and all rois
% arw : 071005: Wrote it.
% 

% Do the usual checks
if (ieNotDefined('flatView'))
    error('You must supply a flat view');
end
if (ieNotDefined('grayView'))
    error('You must supply a gray (VOLUME) view');
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
    plotParam='Phase';
end

if (ieNotDefined('scanList'))
    disp('Setting scan num to current scan');
    scanNum=view.curScan;
end

if (ieNotDefined('binSize'))
    disp('Setting bin size to 2mm');
    binSize=2;
end

% Loop over all the ROIs in roiList : Exctract the ROI data and send it in to plotParamVsDistance

nROIs=length(roiList);

for thisROI=1:nROIs
    ROIdata=view.ROIs(roiList(thisROI));
    disp(ROIdata)
    
    [distanceList,parameterData] = getParamVsDistanceMultipleScanSingleROI(flatView, plotParam, scanList,grayView,ROIdata.coords, binsize)
    
    ROIdistanceList{thisROI}=distanceList;
    dataOut{thisROI}=parameterData;
    
end


% That's it.
