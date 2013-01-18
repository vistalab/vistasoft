function plotMultiplePhs_SingleCondition(vw)
%
% plotMultiplePhs_SingleCondition(vw)
% 
% Bar plot of the phases for each scan, averaging across
% all pixels (in all slices) in a selection of ROIs. All y-axes are made the same. The bar heights
% and a coarse SEM can be obtained from get(gca,'UserData').
% 
% gmb  5/25/98
% bw   2/19/99  Added seY field to the UserData field.
%	    seY is an estimate of the variability in the
%      amplitudes.  It is the SEM of the in the complex 
%      (amp*exp(-i*ph)) representation.  The values are
%      computed in vectorMean.m
% fwc   11/07/02 plots data relative to current vw
%       added plotting of multiple ROIs
%       ROI selection copied from plotMultipleTSeries.m
% Plots the mean amplitudes for each ROI in the current scan
% Based on plotMultipleAmps ARW 072803
% Based on plotMultipleAmps_SingleCondition JW May, 2009

mrGlobals;

% Select ROIs
nROIs=size(vw.ROIs,2);
roiList=cell(1,nROIs);
for r=1:nROIs
    roiList{r}=vw.ROIs(r).name;
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


nscans = numScans(vw);
ROIph=zeros(nscans,nROIs);
ROIseZ=zeros(nscans,nROIs);
ROImeanPhs=zeros(nscans,nROIs);


for r=1:nROIs
    
    n=selectedROIs(r);
    vw = selectROI(vw,n); % is there another way?
    [meanAmps,meanPhs,seZ] = vectorMeans(vw);
    ROIph(:,r)=meanPhs(:);
    ROIseZ(:,r)=seZ(:);
    meanPhs(meanPhs<0) = 2*pi + meanPhs(meanPhs<0);
    ROImeanPhs(:,r)=meanPhs(:);
    
   
    roiName{r}=vw.ROIs(selectedROIs(r)).name;
    fprintf(['\nROI #%d :',roiName{r}],r);
    xstr{r}=roiName{r};
end

% Now do the plotting

% Only plotting the current scan
   r=getCurScan(vw);
    
   subplot(1,1,1);
  
    %plot the bar graph
    
    %h=mybar(ROImeanPhs(r,:)',ROIseZ(r,:)',xstr);
    h=mybar(ROImeanPhs(r,:)',ROIseZ(r,:)' * 0, xstr);
    xlabel('ROI','FontSize',fontSize);
    ylabel('Mean Phase','FontSize',fontSize);
    set(gca,'FontSize',ceil(fontSize*1.2));
    conditionName{r}=dataTYPES(vw.curDataType).scanParams(r).annotation;
    fprintf(['\nCondition #%d :',conditionName{r}],r);
    title(conditionName{r});

%Save the data in gca('UserData')
data.y =ROImeanPhs(r,:);

data.seY = ROIseZ(r,:); % this should probably be adapted

set(gca,'UserData',data);



return;
