function plotMultipleRelAmps(view)
%
% plotMultipleRelAmps(view)
% 
% Bar plot of the amplitudes for each scan, averaging across
% all pixels (in all slices) in a selection of ROIs and relative to the current scan.  The bar heights
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

%Reference scan is the current scan
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

% Plot it
selectGraphWin
clf
fontSize = 9;
headerStr = ['Mean Amplitudes relative to scan ',num2str(refScan)];
set(gcf,'Name',headerStr);

minylim=0;
maxylim=0;
nrows=0;
ncols=0;

if nROIs<=3
    nrows=1;
    ncols=nROIs;
    fontSize = 9;
elseif nROIs<=8
    nrows=2;
    ncols=ceil(nROIs/nrows);
    fontSize = 8;
else
    nrows=ceil(sqrt(nROIs));
    ncols=ceil(nROIs/nrows);
    fontSize = 6;
end

for r=1:nROIs
    
    subplot(nrows,ncols,r);
    n=selectedROIs(r);
    view = selectROI(view,n); % is there another way?
    
    [meanAmps,meanPhs,seZ] = vectorMeans(view);
    
    % make it relative to refscan
    meanRelAmps=meanAmps/meanAmps(refScan);

	%plot the bar graph
	h=mybar(meanRelAmps);
	xlabel('Scan','FontSize',fontSize);
	ylabel('Relative Mean Amplitudes','FontSize',fontSize);
	ylim =get(gca,'YLim');
	set(gca,'YLim',ylim*1.1);
    % slightly bigger title
	set(gca,'FontSize',ceil(fontSize*1.2));
	title(['ROI: ' view.ROIs(selectedROIs(r)).name]);

	foo=cell2struct(h,'bar');
	hbar=foo.bar(refScan);
	set(hbar,'FaceColor','r')
	
	%Save the data in gca('UserData')
	data.y = meanRelAmps;
	data.refScan = refScan;
	data.seY = seZ/meanAmps(refScan); % this should probably be adapted
	
	set(gca,'UserData',data);
    
    ylim=YLIM;
    if ylim(1)< minylim
        minylim=ylim(1);
    end
    if ylim(2)> maxylim
        maxylim=ylim(2);
    end
end

% give all plots same y-axis

for r=1:nROIs
    subplot(nrows,ncols,r);
    YLIM([minylim maxylim]);
end

return;
