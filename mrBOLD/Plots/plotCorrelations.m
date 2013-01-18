function plotCorrelations(view)
%
% plotCorrelations(view)
% 
% Bar plot of the correlations for each scan, averaging across
% all pixels (in all slices) in the current ROI.
% 
% djh 5/25/98

% Compute means across scans, for all pixels in the
% currently selected ROI.
[meanCoherence,meanAmps] = meanCos(view);
  
selectGraphWin

% Header
ROIname = view.ROIs(view.selectedROI).name;
headerStr = ['Mean of correlations, ROI ',ROIname];
set(gcf,'Name',headerStr);

% Plot the bar graph
fontSize = 14;
clf
mybar(meanCoherence);
xlabel('Scan','FontSize',fontSize);
ylabel('Mean Correlation','FontSize',fontSize);
ylim =get(gca,'YLim');
set(gca,'YLim',ylim*1.1);
set(gca,'FontSize',fontSize);

%Save the data in gca('UserData')
data.y = meanCoherence;

set(gca,'UserData',data);


