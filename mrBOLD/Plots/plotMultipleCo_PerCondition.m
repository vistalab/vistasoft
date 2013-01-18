function dataOut=plotMultipleCo_PerCondition(view,plotFlag)
%
% dataOut=plotMultipleCo_PerCondition(view)
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


% Compute means across scans, for all pixels in the
% currently selected ROI.  The seZ value is the mean
% distance from the mean.
% This has no reference scan (it's an amplitude). 
% It plots a separate window for each condition. Within this windows, it
% plots the amplitudes in each ROI.

%Reference scan is the current scan
mrGlobals;

refScan = getCurScan(view);

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

if (ieNotDefined('plotFlag'))
    plotFlag=1; % Plot something by default
end


if (plotFlag)

% Plot it
selectGraphWin
clf
fontSize = 8;
headerStr = ['Mean Coherence'];
set(gcf,'Name',headerStr);
end

minylim=0;
maxylim=0;
nrows=0;
ncols=0;

nscans = numScans(view);
ROIamps=zeros(nscans,nROIs);
ROIseZ=zeros(nscans,nROIs);
ROImeanPhs=zeros(nscans,nROIs);
ROIperVoxSem=zeros(nscans,nROIs);

for r=1:nROIs
    
    n=selectedROIs(r);
    view = selectROI(view,n); % is there another way?
    [meanCo,meanAmp,stdCos,semCos] = meanCos(view);
    ROIco(:,r)=meanCo(:);
    ROIperVoxStd(:,r)=stdCos(:);
    ROIperVoxSem(:,r)=semCos(:);
    
    ROIseZ(:,r)=(meanAmp(:).^2)./meanCo(:);
    
    %xstr{r}=[view.ROIs(selectedROIs(r)).name];
    xstr{r}=int2str(r);
    roiName{r}=view.ROIs(selectedROIs(r)).name;
    fprintf(['\n#%d :',roiName{r}],r);
    
end
dataOut.ROIco=ROIco;
dataOut.ROIseZ=ROIseZ;
dataOut.ROIname=roiName;
dataOut.ROIperVoxStd=ROIperVoxStd;
dataOut.ROIperVoxSem=ROIperVoxSem;
% Now do the plotting

if (plotFlag)
    
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


for r=1:nscans
    
    
    subplot(nrows,ncols,r);
    
    %plot the bar graph
    h=mybar(ROIco(r,:)');% ,ROIseZ(r,:)',xstr);
    xlabel('ROI','FontSize',fontSize);
    ylabel('Mean Coherence','FontSize',fontSize);
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
data.y =ROIco(r,:);
data.refScan = refScan;
%data.seY = ROIseZ(r,:); % this should probably be adapted

set(gca,'UserData',data);



% give all plots same y-axis

for r=1:nscans
    subplot(nrows,ncols,r);
    ylim([minylim maxylim]);
end

end
return;
