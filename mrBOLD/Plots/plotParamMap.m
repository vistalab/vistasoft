function [data]=plotParamMap(view)
%
% plotCorrelations(view)
% 
% Bar plot of the map values for each scan, averaging across
% all pixels (in all slices) in the current ROI.
% 
% rmk, 1/20/99

% Compute means across scans, for all pixels in the
% currently selected ROI.
mnMap = meanMaps(view);
  
selectGraphWin

% Header
ROIname = view.ROIs(view.selectedROI).name;
headerStr = ['Mean of map, ROI ',ROIname];
set(gcf,'Name',headerStr);

% Plot the bar graph
fontSize = 14;
clf
mybar(mnMap);
xlabel('Scan','FontSize',fontSize);
ylabel('Mean Map Value','FontSize',fontSize);
ylim =get(gca,'YLim');
set(gca,'YLim',ylim*1.1);
set(gca,'FontSize',fontSize);

%Save the data in gca('UserData')
data.y = mnMap;
set(gca,'UserData',data);


