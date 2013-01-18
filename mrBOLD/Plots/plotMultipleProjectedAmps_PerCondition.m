function dataOut=plotMultipleProjectedAmps_PerCondition(view,projectionPhase)
%
% plotMultipleProjectedAmps_PerCondition(view,projectionPhase)
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
% arw   071204 Correctly extracts projections phase from current scan
% Compute means across scans, for all pixels in the
% currently selected ROI.  The seZ value is the mean
% distance from the mean.
% projectionPhase (if supplied) is in radians.

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
ROIamps=zeros(nscans,nROIs);
ROIseZ=zeros(nscans,nROIs);
ROImeanPhs=zeros(nscans,nROIs);

for r=1:nROIs
    
    n=selectedROIs(r);
    view = selectROI(view,n); % is there another way?
    [meanAmps,meanPhs,seZ] = vectorMeans(view);
    
    if (computeProjPhase)
        projectionPhase=meanPhs(refScan);
    end
    
    % Compute the amplitude projected onto the reference phase
    meanAmps = meanAmps.*cos(meanPhs-projectionPhase);
    
    ROIamps(:,r)=meanAmps(:);
    ROIseZ(:,r)=seZ(:);
    
    ROImeanPhs(:,r)=meanPhs(:);
    %xstr{r}=[view.ROIs(selectedROIs(r)).name];
    xstr{r}=int2str(r);
    roiName{r}=view.ROIs(selectedROIs(r)).name;
    fprintf(['\n#%d :',roiName{r}],r);  
end

dataOut.ROIamps=ROIamps;
dataOut.ROIseZ=ROIseZ;
dataOut.ROIname=roiName;

% Now do the plotting

if nscans<=3
    nrows=1;
    ncols=nscans;
    fontSize = 9;
elseif nscans<=8
    nrows=2;
    ncols=ceil(nscans/nrows);
    fontSize = 8;
else
    nrows=ceil(sqrt(nscans));
    ncols=ceil(nscans/nrows);
    fontSize = 6;
end

    scanList = [1:numScans(view)];

for r=1:nscans
    
    
    subplot(nrows,ncols,r);
    
    %plot the bar graph
    if(r==refScan)
        h=mybar(ROIamps(r,:)',ROIseZ(r,:)',xstr,[],[1 0 0]);   
    else
        h=mybar(ROIamps(r,:)',ROIseZ(r,:)',xstr,[],[0 0 1]);
    end
 
    xlabel('ROI','FontSize',fontSize);
    ylabel('Mean Amplitude','FontSize',fontSize);
    set(gca,'FontSize',ceil(fontSize*1.2));
    conditionName{r}=dataTYPES(view.curDataType).scanParams(r).annotation;
    fprintf(['\nCondition #%d :',conditionName{r}],r);

    
    title(['Condition #: ' int2str(r)]);
    yl=ylim;
 
    if yl(1)< minylim
        minylim=yl(1);
    end
    if yl(2)> maxylim
        maxylim=yl(2);
    end
end

% 	xlabel('Scan','FontSize',fontSize);
% 	ylabel('Mean Amplitude','FontSize',fontSize);
% 	ylim =get(gca,'YLim');
% 	set(gca,'YLim',ylim*1.1);
%     % slightly bigger title
% 	set(gca,'FontSize',ceil(fontSize*1.2));
% 	title(['ROI: ' view.ROIs(selectedROIs(r)).name]);

%  foo=cell2struct(h,'bar');
% 	hbar=foo.bar(refScan);
% 	set(hbar,'FaceColor','r')

%Save the data in gca('UserData')
data.y =ROIamps(r,:);
data.refScan = refScan;
data.seY = ROIseZ(r,:); % this should probably be adapted

set(gca,'UserData',data);



% give all plots same y-axis

for r=1:nscans
    subplot(nrows,ncols,r);
    ylim([minylim maxylim]);
end

return;
