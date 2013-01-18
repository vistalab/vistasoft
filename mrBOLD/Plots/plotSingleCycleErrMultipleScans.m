function plotSingleCycleErrMultipleScans(vw,scans)
%Plot the time series data of a single cycle.
%
%  plotSingleCycleErrMultipleScans(vw,scans)
%
%  JW, Jan, 2009: Hacked from plotMultipleSingleCycleErr, which plots
%                 a single cycle from each of multiple ROIs in one scan.
%                 This function plots a single cycle from multiple scans in
%                 one ROI. It works but it could be cleaned up.
%
%
% All cycles (blocks) in a scan are collapsed into one cycle. This is meant
% to be somthing like the average over repetitions in the scan. The mean is
% plotted with standard error bars.
%
% When called from the GRAY/VOLUME or FLAT views, the ROI is converted to
% INPLANE to retrieve the time series.
%
% Example:
%   scans = [2 4 6];
%   vw = getCurView;
%   plotSingleCycleErrMultipleScans(vw, scans)
%

mrGlobals;

% ----------------------------------
% define variables
% ----------------------------------
if (notDefined('scans')), scans = er_selectScans(vw); end
if isempty('scans'), display('User aborted'); return; end



nScans=length(scans);
scanList=cell(1,nScans);
for s=1:nScans
    scanList{s}=viewGet(vw, 'annotation', scans(s));
end

% ----------------------------------
% xform ROI if not in INPLANE view 
% ----------------------------------
% This should be a separate function. Lots of functions duplicate this
% code.
% Yes. Now it is. JW
roiXformView(vw);


% ----------------------------------
% Compute the mean tSeries
% ----------------------------------
% This should also be a separate function. Lots of other functions use
% this.
% Yes. Now it is. JW
tSeries = roiMeanTSeries(scans);

% ----------------------------------
% Compute the average singlge cycle
% ----------------------------------
for s=1:nScans
    
    % These should be converted to some kind of viewGet() calls. OK - done.
    nCycles     = viewGet(vw, 'ncycles' ,scans(s));
    frameRate   = viewGet(vw, 'frameRate' ,scans(s));
    framesToUse = viewGet(vw, 'frames to use', scans(s));
    nFrames        =length(framesToUse);
    framesPerCycle = nFrames/nCycles;

    
    tSeries{s} = tSeries{s}(framesToUse, :);
    multiCycle{s}  = reshape(tSeries{s},nFrames/nCycles,nCycles);
    singleCycle{s} = mean(multiCycle{s},2);
    singleCycleStdErr{s} = (std(multiCycle{s},[],2)/sqrt(nCycles));
    singleCycle{s}(end+1)=singleCycle{s}(1);
    singleCycleStdErr{s}(end+1)=singleCycleStdErr{s}(1);
    [co(s), amp(s), ph(s)] = computeCorAnalTSeries(vw, scans(s), tSeries{s});

end
framesPerCycle=framesPerCycle+1;

% ----------------------------------
% Plot
% ----------------------------------

newGraphWin;
hold on

fontSize = 14;
t = linspace(0,(framesPerCycle-1)*frameRate,framesPerCycle)';

 ROIname = viewGet(vw, 'roiName');
 headerStr = ['Mean Cycle, ROI ',ROIname,', scans ',num2str(scans)];

set(gcf,'Name',headerStr);
color_tmp=jet(nScans);

for s=1:nScans
    plot(t, amp(s) * sin(2*pi*t/max(t)-ph(s)), 'Color', color_tmp(s,:), 'LineWidth',4);
end

h_legend = legend(scanList);
set(h_legend, 'FontSize', 10);

for s=1:nScans
    hh = errorbar(t,singleCycle{s},singleCycleStdErr{s},'Color',color_tmp(s,:), 'LineStyle', 'none');
    set(hh,'LineWidth',2);
end

hold off;

% nTicks = size(tSeries,1);
xtick = (0:frameRate:framesPerCycle*frameRate);

set(gca,'xtick',xtick)
set(gca,'FontSize',fontSize)
xlabel('Time (sec)','FontSize',fontSize)
ylabel('Percent modulation','FontSize',fontSize)
set(gca,'XLim',[0,framesPerCycle*frameRate]);
grid on



% ---------------------------------------------
%Save the data 
%   to retrieve: get(gca, 'UserData')
% ---------------------------------------------

data.x = t;
data.y = singleCycle;
data.e = singleCycleStdErr;
set(gca,'UserData',data);


return;
