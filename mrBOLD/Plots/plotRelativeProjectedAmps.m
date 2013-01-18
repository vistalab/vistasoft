function plotRelativeProjectedAmps(view)
%
% plotRelativeProjectedAmplitudes(view)
% 
% Bar plot of the amplitudes for each scan, averaging across
% all pixels (in all slices) in the current ROI.  The bar heights
% and a coarse SEM can be obtained from get(gca,'UserData').
% 
% gmb  5/25/98
% bw   2/19/99  Added seY field to the UserData field.
%	    seY is an estimate of the variability in the
%      amplitudes.  It is the SEM of the in the complex 
%      (amp*exp(-i*ph)) representation.  The values are
%      computed in vectorMean.m
% fwc   11/07/02 plots data relative to current view


% Compute means across scans, for all pixels in the
% currently selected ROI.  The seZ value is the mean
% distance from the mean.
[meanAmps,meanPhs,seZ] = vectorMeans(view);

%Reference scan is the current scan
refScan = getCurScan(view);

% Compute the amplitude projected onto the reference phase
meanProjectedAmps = meanAmps.*cos(meanPhs-meanPhs(refScan));

meanRelProjAmps=meanProjectedAmps/meanProjectedAmps(refScan);

selectGraphWin

% Header
ROIname = view.ROIs(view.selectedROI).name;
headerStr = ['Mean of projected amplitudes relative to reference scan, ROI ',ROIname];
set(gcf,'Name',headerStr);

%plot the bar graph
clf
fontSize = 14;
h=mybar(meanRelProjAmps);
xlabel('Scan','FontSize',fontSize);
ylabel('Relative Mean Projected Amplitude','FontSize',fontSize);
ylim =get(gca,'YLim');
set(gca,'YLim',ylim*1.1);
set(gca,'FontSize',fontSize);

foo=cell2struct(h,'bar');
hbar=foo(refScan).bar;
set(hbar,'FaceColor','r')

%Save the data in gca('UserData')
data.y = meanRelProjAmps;
data.refScan = refScan;
data.seY = seZ/meanProjectedAmps(refScan); % this should probably be adapted

set(gca,'UserData',data);

return;
