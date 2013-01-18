function dataOut=plotPercentVoxAboveThreshPerCondition(view)
%
% dataOut=plotPercentVoxAboveThreshPerCondition
% 
% Bar plot of the percentage of superthreshold voxels (based on the co) in a particular condition
% All y-axes are made the same. The bar heights
% and total voxels in each ROI can be obtained from the userdata 
% 
% arw 04/01/05


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
headerStr = ['Vox above thresh'];
set(gcf,'Name',headerStr);

minylim=0;
maxylim=0;
nrows=0;
ncols=0;


nscans = numScans(view);
ROIcos=zeros(nscans,nROIs);
thisCoThresh=get(view.ui.cothresh.sliderHandle,'value');
totalVoxels=zeros(nscans,nROIs);
voxAboveThresh=zeros(nscans,nROIs);

for r=1:nROIs
    
    n=selectedROIs(r);
    view = selectROI(view,n); % is there another way?
    ROIcoords=getCurROIcoords(view);
     
    for scanNum=1:nscans       
        
        subCo = getCurDataROI(view,'co',scanNum,ROIcoords);
        totalVoxels(scanNum,r)=size(subCo,2);
        voxAboveThresh(scanNum,r)=length(find(subCo>=thisCoThresh));
    end
    
    xstr{r}=int2str(r);
    roiName{r}=view.ROIs(selectedROIs(r)).name;
    fprintf(['\n#%d :',roiName{r}],r);
    
end
dataOut.totalVoxels=totalVoxels;
dataOut.voxAboveThresh=voxAboveThresh;
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

percentAboveThresh=voxAboveThresh./totalVoxels*100;

for r=1:nscans
    
    
    subplot(nrows,ncols,r);
    
    %plot the bar graph
    h=bar(percentAboveThresh(r,:));% ,ROIseZ(r,:)',xstr);
    xlabel('ROI','FontSize',fontSize);
    ylabel('Percent above threshold','FontSize',fontSize);
    set(gca,'FontSize',ceil(fontSize*1.2));
    conditionName{r}=dataTYPES(view.curDataType).scanParams(r).annotation;
    fprintf(['\nCondition #%d :',conditionName{r}],r);

    fprintf('\nTotalVoxels: %d',totalVoxels(r,:));
    
    title(['Condition #: ' int2str(r)]);
    yl=ylim;
 
    if yl(1)< minylim
        minylim=yl(1);
    end
    if yl(2)> maxylim
        maxylim=yl(2);
    end
end


set(gca,'UserData',dataOut);



% give all plots same y-axis

for r=1:nscans
    subplot(nrows,ncols,r);
    ylim([minylim maxylim]);
end

return;
