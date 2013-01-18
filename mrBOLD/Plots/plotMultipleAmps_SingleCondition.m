function plotMultipleAmps_SingleCondition(view)
%
% plotMultipleAmps_SingleCondition(view)
% 
% Bar plot of the amplitudes for each scan, averaging across
% all pixels (in all slices) in a selection of ROIs. All y-axes are made the same. The bar heights
% and a coarse SEM can be obtained from get(gca,'UserData').
% 
% gmb  5/25/98
% bw   2/19/99  Added seY field to the UserData field.
%	    seY is an estimate of the variability in the
%      amplitudes.  It is the SEM of the in the complex 
%      (amp*exp(-i*ph)) representation.  The values are
%      computed in vectorMean.m
% fwc   11/07/02 plots data relative to current view
%       added plotting of multiple ROIs
%       ROI selection copied from plotMultipleTSeries.m
% Plots the mean amplitudes for each ROI in the current scan
% Based on plotMultipleAmps ARW 072803

mrGlobals;

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
    ROIamps(:,r)=meanAmps(:);
    ROIseZ(:,r)=seZ(:);
    ROImeanPhs(:,r)=meanPhs(:);
    %xstr{r}=[view.ROIs(selectedROIs(r)).name];
   
    roiName{r}=view.ROIs(selectedROIs(r)).name;
    fprintf(['\nROI #%d :',roiName{r}],r);
    xstr{r}=roiName{r};
end

% Now do the plotting

% Only plotting the current scan
   r=getCurScan(view);
    
   subplot(1,1,1);
  
    %plot the bar graph
    h=mybar(ROIamps(r,:)',ROIseZ(r,:)',xstr);
    xlabel('ROI','FontSize',fontSize);
    ylabel('Mean Amplitude','FontSize',fontSize);
    set(gca,'FontSize',ceil(fontSize*1.2));
    conditionName{r}=dataTYPES(view.curDataType).scanParams(r).annotation;
    fprintf(['\nCondition #%d :',conditionName{r}],r);
    title(conditionName{r});

%Save the data in gca('UserData')
data.y =ROIamps(r,:);

data.seY = ROIseZ(r,:); % this should probably be adapted

set(gca,'UserData',data);



return;
