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
tScan          = (0:nFrames-1)*frameRate;

% If we don't have an integer number of data points per cycle, then
%   resample the data
if isinteger(framesPerCycle)
    resample = false;    
    tCycle = tScan(1:framesPerCycle+1);
    
else   
    resample = true;
    
    framesPerCycle      = round(framesPerCycle);
    nFrames             = framesPerCycle * nCycles;
    resampledT          = linspace(0,max(tScan), nFrames); 
    tCycle              = resampledT(1:framesPerCycle+1);

end

% Select ROIs
[selectedROIs, nROIs] = roiGetList(vw, ROIlist);

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
    
    if resample
        resampledTSeries        = interp1(tScan, tSeries{1}(framesToUse), resampledT);
        multiCycle              = reshape(resampledTSeries,nFrames/nCycles,nCycles);
        
    else
        multiCycle              = reshape(tSeries{1}(framesToUse),nFrames/nCycles,nCycles);
    end

    singleCycle{r}              = mean(multiCycle,2);
    singleCycleStdErr{r}        = (std(multiCycle, [], 2)/sqrt(nCycles));
    singleCycle{r}(end+1)       = singleCycle{r}(1);
    singleCycleStdErr{r}(end+1) = singleCycleStdErr{r}(1);
        
end

framesPerCycle=framesPerCycle+1;

% Plotting section 
newGraphWin;
hold on

fontSize = 14; 

% ROIname = view.ROIs(view.selectedROI).name;
% headerStr = ['Mean Cycle, ROI ',ROIname,', scan ',num2str(scan)];

% set(gcf,'Name',headerStr);
for r=1:nROIs
    hh = errorbar(tCycle,singleCycle{r},singleCycleStdErr{r});    
    
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
data.x = tCycle;
data.y = singleCycle;
data.e = singleCycleStdErr;
set(gca,'UserData',data);


return;
