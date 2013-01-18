function status = plotMultipleSingleCycleErr(vw,scan,ROIlist)
%Plot the time series data of a single cycle.
%
%  status = plotMultipleSingleCycle(vw,[scan], [ROIlist]) 
%
% All cycles (blocks) in a scan are collapsed into one cycle. This is meant
% to be somthing like the average over repetitions in the scan. The mean is
% plotted with standard error bars. 
%
% When called from the GRAY/VOLUME or FLAT views, the ROIs are converted to
% INPLANE to retrieve the time series.
%
% Example:
%   plotMultipleSingleCycleErr(INPLANE{1},1)
%
%  08/06 KA wrote it

mrGlobals;

% Normal status is OK
status = 1;

if notDefined('vw'),        vw       = getCurView;              end
if notDefined('scan'),      scan    = viewGet(vw,'curScan');    end
if notDefined('ROIlist'),   ROIlist =[];                        end

% Get coranal parameters
nCycles        = viewGet(vw, 'num cycles', scan);
frameRate      = viewGet(vw, 'frame rate', scan);
framesToUse    = viewGet(vw, 'frames to use', scan);
nFrames        =length(framesToUse);
framesPerCycle = nFrames/nCycles;

% Select ROIs
[selectedROIs nROIs] = roiGetList(vw, ROIlist);

% Get coords
ROIcoords = cell(1,nROIs);
for r=1:nROIs
    ROIcoords{r}=viewGet(vw, 'ROIcoords', selectedROIs(r));
end


%% Specifics for Flat, Gray, or Inplane views - xform ROI to INPLANE view
% This whole section is duplicated in other functions, like
% plotMultipleSingleCycleErr.m Maybe it should be split off to its own
% function. 

%Compute the average single cycle
for r=1:nROIs
	tSeries                     = meanTSeriesForPlotting(vw, selectedROIs(r));
    multiCycle{r}               = reshape(tSeries{1}(framesToUse),nFrames/nCycles,nCycles);
    singleCycle{r}              = mean(multiCycle{r},2);
    singleCycleStdErr{r}        = (std(multiCycle{r}, [], 2)/sqrt(nCycles));
    singleCycle{r}(end+1)       = singleCycle{r}(1);
    singleCycleStdErr{r}(end+1) = singleCycleStdErr{r}(1);
end
framesPerCycle=framesPerCycle+1;

% Plotting section 
newGraphWin;
hold on

fontSize = 14; 
t = linspace(0,(framesPerCycle-1)*frameRate,framesPerCycle)';

% ROIname = view.ROIs(view.selectedROI).name;
% headerStr = ['Mean Cycle, ROI ',ROIname,', scan ',num2str(scan)];

% set(gcf,'Name',headerStr);
for r=1:nROIs
    hh = errorbar(t,singleCycle{r},singleCycleStdErr{r});    
    
    % set the line color to be the same as the ROI color
    set(hh,'Color',vw.ROIs(selectedROIs(r)).color);
  
    % but if the line color and plot color are the same, the line will be
    % invisible (e.g., if the ROI color is white)
    if isequal(get(hh, 'Color'), get(gca, 'Color'))
        set(hh, 'Color', 1 - get(hh, 'Color')); 
    end

    set(hh,'LineWidth',4);
    
    tmp{r} = viewGet(vw, 'roiName', selectedROIs(r));
end
legend(tmp)
hold off;

% nTicks = size(tSeries,1);
xtick = (0:frameRate:framesPerCycle*frameRate);

set(gca,'xtick',xtick)
set(gca,'FontSize',fontSize)
xlabel('Time (sec)','FontSize',fontSize) 
ylabel('Percent modulation','FontSize',fontSize) 
set(gca,'XLim',[0,framesPerCycle*frameRate]);
grid on

%Save the data in gca('UserData')
data.x = t;
data.y = singleCycle;
data.e = singleCycleStdErr;
set(gca,'UserData',data);


return;
