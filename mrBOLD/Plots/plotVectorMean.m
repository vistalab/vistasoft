function plotVectorMean(view)
%
% plotVectorMean(view)
% 
% Polar plot of the vector mean for each scan, averaging across
% all pixels (in all slices) in the current ROI.
% 
% djh 4/24/98

% Compute vector means across scans, for all pixels in the
% currently selected ROI.
[meanAmps,meanPhs] = vectorMeans(view);
  
selectGraphWin

% Header
ROIname = view.ROIs(view.selectedROI).name;
headerStr = ['Vector mean, ROI ',ROIname];
set(gcf,'Name',headerStr);

% polar plot parameters
fontSize = 14;
symbolSize = 18;
params.grid = 'on';
params.line = 'off';
params.gridColor = [0.6,0.6,0.6];
params.fontSize = fontSize;
params.symbol = 'o';
params.size = 1;
params.color = 'w';
params.fillColor = 'w';
params.maxAmp = round(max(meanAmps)*2)/2+.5;
params.ringTicks = linspace(0,params.maxAmp,5);

% Use 'polarPlot' to set up grid'
clf
polarPlot(0,params);
x = meanAmps.*cos(meanPhs);
y = meanAmps.*sin(meanPhs);

hold on

% plot and label the symbols
for i=1:length(x)
  h=plot(x(i),y(i),'bo','MarkerSize',symbolSize,'LineWidth',2);

  set(h,'MarkerFaceColor','b')
  hold on
  text(x(i),y(i),int2str(i),'Color','w',...
            'HorizontalAlignment','center','FontWeight','bold');
end

%Save the data in gca('UserData')
data.x = x;
data.y = y;
set(gca,'UserData',data);
