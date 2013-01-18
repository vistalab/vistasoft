function plotRelativeAmps(view)
%
% plotAmps(view)
% 
% Bar plot of the amplitudes for each scan, averaging across
% all pixels (in all slices) in the current ROI.
% 
% gmb  5/25/98

% Compute means across scans, for all pixels in the
% currently selected ROI.
[meanAmps,meanPhs] = vectorMeans(view);

selectGraphWin

% Header
ROIname = view.ROIs(view.selectedROI).name;
headerStr = ['Mean of amplitudes, ROI ',ROIname];
set(gcf,'Name',headerStr);

% Plot the bar graph
clf
fontSize = 14;
mybar(meanAmps);
xlabel('Scan','FontSize',fontSize);
ylabel('Mean Amplitude','FontSize',fontSize);
ylim =get(gca,'YLim');
set(gca,'YLim',ylim*1.1);
set(gca,'FontSize',fontSize);

% Save the data in gca('UserData')
data.y = meanAmps;
set(gca,'UserData',data);
