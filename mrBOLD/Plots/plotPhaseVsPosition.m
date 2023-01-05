function plotPhaseVsPosition(view, scanList)
%
% plotPhaseVsPosition(view, [scanList])
% 
% Plot of phase versus linear position for the current scan, for all
% pixels in the current ROI.  (The current ROI should be a line ROI,
% otherwise, this plot doesn't make much sense.)%% If scanList is omitted, defaults to curScan.
%
% Get selpts from current ROI
if view.selectedROI
  ROIcoords = getCurROIcoords(view);
else
  myErrorDlg('No current ROI');
endplotColors = 'brgycm';fontSize = 14;symbolSize = 4;    if(~exist('scanList','var'))    scanList = getCurScan(view);endif(isempty(scanList))    return;endselectGraphWin;clf;hold on;legendNames = {};for(curScan=scanList)
    % Get co and ph (vectors) this scan
    ph = getCurDataROI(view,'ph',curScan,ROIcoords);
    co = getCurDataROI(view,'co',curScan,ROIcoords);    
    % Remove NaNs from ph that may be there if ROI
    % includes volume voxels where there are no data.
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
    cothresh = getCothresh(view);
    phWindow = getPhWindow(view);
    phIndices = phWindowIndices(ph,phWindow);
    coIndices = find(co > cothresh);
    bothIndices = intersect(phIndices,coIndices);    
    % Pull out ph for desired pixels
    subPh = ph(bothIndices);    
    % Figure out the x-axis by the coordinates in ROIcoords
    dLinePos = diff(ROIcoords');
    dx = sqrt(dLinePos(:,1).^2 + dLinePos(:,2).^2);
    x = [0;cumsum(dx)];    
    % convert to degrees
    % cxPhase = exp(sqrt(-1)*ph);
    % cxPhase = cxPhase*exp(-1*sqrt(-1)*ph(1));
    % y = angle(cxPhase);
    y(curScan,:) = ph;    
    % Window header
    ROIname = view.ROIs(view.selectedROI).name;
    headerStr = ['Phase vs. position, ROI ',ROIname,', scan ',num2str(curScan)];
    set(gcf,'Name',headerStr);    
    % Plot it    color = plotColors(mod(curScan-1,length(plotColors))+1);
    %h = plot(x, y(curScan,:), [color '-'], x, y(curScan,:), [color 'o'],'MarkerSize', symbolSize);    h = plot(x, y(curScan,:), [color '-']);
    set(h, 'MarkerFaceColor', color);    legendNames{end+1} = ['Scan ',num2str(curScan)];endlegend(legendNames);for(curScan=scanList)    color = plotColors(mod(curScan-1,length(plotColors))+1);    h = plot(x, y(curScan,:), [color 'o'],'MarkerSize', symbolSize);    set(h, 'MarkerFaceColor', color);end
ylabel('Phase (rad)','FontSize',fontSize);
xlabel('Distance along flat line roi(pixels)');
% set(gca,'ylim',[-pi pi]);
set(gca,'ylim',[0 2*pi]);
set(gca,'FontSize',fontSize)
% Save the data in gca('UserData')
data.position = x;
data.ph = y;
set(gca,'UserData',data);