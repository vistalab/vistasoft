function plotAmps(vw, scans)
%
% plotAmps(vw)
%
% Bar plot of the amplitudes for each scan, averaging across
% all pixels (in all slices) in the current ROI.
%
% gmb   5/25/98
% jw    6/7/08 added std to user data

% Compute means across scans, for all pixels in the
% currently selected ROI.
if exist('scans', 'var')
    [meanAmps,meanPhs,seAmps,meanStd] = vectorMeans(vw, scans);
else
    [meanAmps,meanPhs,seAmps,meanStd] = vectorMeans(vw);
end
selectGraphWin

% Header
ROIname     = vw.ROIs(vw.selectedROI).name;
headerStr   = ['Mean of amplitudes, ROI ',ROIname];
set(gcf,'Name',headerStr);

% Plot the bar graph
clf
fontSize = 14;
meanAmps
meanStd

mybar(meanAmps,meanStd);
xlabel('Scan','FontSize',fontSize);
ylabel('Mean Amplitude','FontSize',fontSize);
ylim =get(gca,'YLim');
set(gca,'YLim',ylim*1.1);
set(gca,'FontSize',fontSize);

% Save the data in gca('UserData')
data.y = meanAmps;
data.s = meanStd;
set(gca,'UserData',data);
