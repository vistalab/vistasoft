function plotCorVsPhase(vw,format, drawROI)
%
% plotCorVsPhase(vw,format)
% 
% Plot of correlation versus phase for the current scan, for all
% pixels (in all slices) in the current ROI.
%
% format can be either 'polar' or 'cartesian'
%
% If there is no current ROI, then the entire data set is plotted.  This is
% sometimes useful for examining left FLAT, or right FLAT.
%

if ieNotDefined('format'), format = 'polar'; end
if ieNotDefined('vw'), error('View must be defined.'); end
if ieNotDefined('drawROI'), drawROI = false; end

curScan = getCurScan(vw);

% Get selpts from current ROI
if vw.selectedROI, 
    ROIcoords = getCurROIcoords(vw);
    ROIname = vw.ROIs(vw.selectedROI).name;
    % Get co and ph (vectors) for the current scan, within the
    % current ROI.
    %
    co = getCurDataROI(vw,'co',curScan,ROIcoords);
    ph = getCurDataROI(vw,'ph',curScan,ROIcoords);
else  
    co = viewGet(vw,'scancoherence',curScan);
    ph = viewGet(vw,'scanphase',curScan);
    ROIname = 'All data';
end

% Remove NaNs from subCo and subAmp that may be there if ROI
% includes volume voxels where there is no data.
NaNs = find(isnan(co));
if ~isempty(NaNs)
  myWarnDlg('ROI includes voxels that have no data.  These voxels are being ignored.');
  notNaNs = find(~isnan(co));
  co = co(notNaNs);
  ph = ph(notNaNs);
end

% Read cothresh and phWindow from the slide bars, and get indices
% of the co and ph vectors that satisfy the cothresh and phWindow.
%
cothresh = getCothresh(vw);
phWindow = getPhWindow(vw);
phIndices = phWindowIndices(ph,phWindow);
coIndices = find(co > cothresh);
bothIndices = intersect(phIndices,coIndices);

% Pull out co and ph for desired pixels
subCo = co(bothIndices);
subPh = ph(bothIndices);

selectGraphWin;

% Window header
headerStr = ['Phase vs. coherence, ROI ',ROIname,', scan ',num2str(curScan)];
set(gcf,'Name',headerStr);

% Plot it
fontSize = 14;
symbolSize = 4;

if strcmp(format,'cartesian')

  % cartesian plot
  clf
  h=plot(ph*180/pi,co,'bo','MarkerSize',symbolSize);
  set(h,'MarkerFaceColor','b')
  hold on
  h=plot(subPh*180/pi,subCo,'ro','MarkerSize',symbolSize);
  set(h,'MarkerFaceColor','r')
  hold off
  set(gca,'yTick',[0:0.25:1]);
  set(gca,'yLim',[0,1]);
  set(gca,'xTick',[0:45:360]);
  set(gca,'xLim',[0,360]);
  xlabel('Phase (deg)','FontSize',fontSize);
  ylabel('Correlation','FontSize',fontSize);
  set(gca,'FontSize',fontSize)

else					

  % polar plot
  x = co.*cos(ph);
  y = co.*sin(ph);
  subX = subCo.*cos(subPh);
  subY = subCo.*sin(subPh);

  % polar plot params
  params.grid = 'on';
  params.line = 'off';
  params.gridColor = [0.6,0.6,0.6];
  params.fontSize = fontSize;
  params.symbol = 'o';
  params.size = symbolSize;
  params.color = 'w';
  params.fillColor = 'w';
  params.maxAmp = 1;
  params.ringTicks = [0:0.2:1];

  % Use 'polarPlot' to set up grid'
  clf
  polarPlot(0,params); 

  % finish plotting it
  h=plot(x,y,'bo','MarkerSize',symbolSize);
  set(h,'MarkerFaceColor','b')
  hold on
  h=plot(subX,subY,'ro','MarkerSize',symbolSize);
  set(h,'MarkerFaceColor','r')
  hold off
end

if drawROI, 
    vw = roiCapturePointsFromPlot(vw, subX, subY, coIndices, ROIcoords);
end

% Save the data in gca('UserData')
data.co = co;
data.ph = ph;
data.subCo = subCo;
data.subPh = subPh;
set(gca,'UserData',data);

return;