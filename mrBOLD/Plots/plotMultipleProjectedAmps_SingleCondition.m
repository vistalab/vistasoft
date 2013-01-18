function dataOut=plotMultipleProjectedAmps_SingleCondition(view,scanToPlot,projectionPhase)
%
% plotMultipleProjectedAmps_SingleCondition(view,projectionPhase)
% 
% Bar plot of the amplitudes for each scan, averaging across
% all pixels (in all slices) in a selection of ROIs. All y-axes are made the same. The bar heights
% and a coarse SEM can be obtained from get(gca,'UserData').
% Amplitudes are projected against a single phase (supplied). 

% gmb  5/25/98
% bw   2/19/99  Added seY field to the UserData field.
%	    seY is an estimate of the variability in the
%      amplitudes.  It is the SEM of the in the complex 
%      (amp*exp(-i*ph)) representation.  The values are
%      computed in vectorMean.m
% fwc   11/07/02 plots data relative to current view
%       added plotting of multiple ROIs
%       ROI selection copied from plotMultipleTSeries.m
% arw   042505 Correctly extracts projections phase from current scan if
%   none is sprcified.
%   Projection phase is in radians.
%   

mrGlobals;

refScan = getCurScan(view);
if (~exist('projectionPhase','var'))
    computeProjPhase=1;
else
    if (isnan(projectionPhase))
        % User input requested
        projectionPhase=input('Enter projection phase in radians:');
    end
    
    computeProjPhase=0;
end


% Select ROIs
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

% Plot it
selectGraphWin
clf
fontSize = 8;
headerStr = ['Mean Amplitudes'];
set(gcf,'Name',headerStr);

minylim=0;
maxylim=0;
nrows=0;
ncols=0;

nscans = numScans(view);
ROIamps=zeros(nROIs,1);
ROIseZ=zeros(nROIs,1);
ROImeanPhs=zeros(nROIs,1);

for r=1:nROIs
    
    n=selectedROIs(r);
    view = selectROI(view,n); % is there another way? Well yes - we could be opening up a hidden window and doing all this invisibly.
    
    [meanAmps,meanPhs,seZ] = vectorMeans(view);
    meanAmps=meanAmps(scanToPlot);
    meanPhs=meanPhs(scanToPlot);
    seZ=seZ(scanToPlot);
    
    if (computeProjPhase)
        projectionPhase=meanPhs(refScan);
    end
    
    % Compute the amplitude projected onto the reference phase
    meanAmps = meanAmps.*cos(meanPhs-projectionPhase);
    
    ROIamps(r)=meanAmps;
    ROIseZ(r)=seZ;
    
    ROImeanPhs(r)=meanPhs;
    %xstr{r}=[view.ROIs(selectedROIs(r)).name];
    xstr{r}=int2str(r);
    roiName{r}=view.ROIs(selectedROIs(r)).name;
    fprintf(['\n#%d :',roiName{r}],r);  
end

dataOut.ROIamps=ROIamps;
dataOut.ROIseZ=ROIseZ;
dataOut.ROIname=roiName;

% Now do the plotting

    nrows=1;
    ncols=1;
   
 
    
    subplot(nrows,ncols,1);
    
    %plot the bar graph
    size(ROIamps)
    size(ROIseZ)
    size(xstr)
    
    
    h=mybar(ROIamps,ROIseZ,xstr,'');   
    
    xlabel('ROI','FontSize',fontSize);
    ylabel('Mean Amplitude','FontSize',fontSize);
    set(gca,'FontSize',ceil(fontSize*1.2));
    conditionName=dataTYPES(view.curDataType).scanParams(scanToPlot).annotation;
    fprintf('\nCondition #%d :',scanToPlot);

    
    title(['Condition #: ' int2str(scanToPlot)]);
 
end

%Save the data in gca('UserData')
data.y =ROIamps(:);
data.refScan = refScan;
data.seY = ROIseZ(:); % this should probably be adapted

set(gca,'UserData',data);



% give all plots same y-axis


return;
