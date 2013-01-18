function plotProjAmpVsPosition(view)
%
% plotProjAmpVsPosition(view)
% 
% Plot of projected amplitude versus linear position for the current scan, for all
% pixels in the current ROI.  (The current ROI should be a line ROI,
% otherwise, this plot doesn't make much sense.)
%
%
% fwc   12/07/02    adapted to projected amplitude vs position

% Get selpts from current ROI
if view.selectedROI
  ROIcoords = getCurROIcoords(view);
else
  myErrorDlg('No current ROI');
end

% Get co and ph (vectors) for the current scan, within the
% current ROI.
%
curScan = getCurScan(view);
ph = getCurDataROI(view,'ph',curScan,ROIcoords);
amp = getCurDataROI(view,'amp',curScan,ROIcoords);
co = getCurDataROI(view,'co',curScan,ROIcoords);

% Remove NaNs from ph that may be there if ROI
% includes volume voxels where there are no data.
NaNs = find(isnan(co));
if ~isempty(NaNs)
  myWarnDlg('ROI includes voxels that have no data.  These voxels are being ignored.');
  notNaNs = find(~isnan(co));
  co = co(notNaNs);
  ph = ph(notNaNs);
  amp = amp(notNaNs);
end

% Compute the amplitude projected onto the phase of first pixel
projectedAmp = amp.*cos(ph-ph(1));


% Figure out the x-axis by the coordinates in ROIcoords
dLinePos = diff(ROIcoords');
dx = sqrt(dLinePos(:,1).^2 + dLinePos(:,2).^2);
x = [0;cumsum(dx)];

y = ph;
y = projectedAmp;

selectGraphWin

% Window header
ROIname = view.ROIs(view.selectedROI).name;
headerStr = ['Projected Amplitude vs. position, ROI ',ROIname,', scan ',num2str(curScan)];
set(gcf,'Name',headerStr);

% Plot it
fontSize = 14;
symbolSize = 4;

clf
h = plot(x, y, 'b-', x, y, 'bo','MarkerSize', symbolSize);
set(h, 'MarkerFaceColor', 'b')
ylabel('Projected Amplitude','FontSize',fontSize);
xlabel('Distance along flat line roi(pixels)');
% set(gca,'ylim',[-pi pi]);
% set(gca,'ylim',[0 2*pi]);

LEGEND(['scan ',num2str(curScan)], -1);

set(gca,'FontSize',fontSize)

% Save the data in gca('UserData')
data.position = x;
data.amp = y;
set(gca,'UserData',data);

