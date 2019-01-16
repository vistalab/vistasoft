function data = plotMeanTSeries(vw,scans, useScanDialog, getRawData)
% Plots the mean tSeries for the current scan
%
%   data = plotMeanTSeries(vw,scans, useScanDialog, [getRawData])
%
% The data are averaged across all pixels (in all slices) in the current
% ROI.
%
% If you change this function make parallel changes in:
%   plotMultipleTSeries, plotFFTTseries, plotMultipleFFTSeries
%
% djh whenever
% 2005.04.04 AB added sections to transfer ROI to INPLANE from gray of flat
% so that plots could be made from the gray and flat views as well as from
% inplane.
% 2008 RAS: doesn't auto-xfer for inplanes. I will put this code in a
% separate function, and only have it auto-xform for FLAT views. This code
% should always look for time series in a given view (e.g., if you transfer
% time series to volume/gray, it should look at those time series, not the
% inplane ones. We should revisit the issue of xforming time series to flat
% as well.) But the auto-xforming should be a separate function.
% 2009: JW: added multiscan compatibility

%------------------------------------------------------------------------
% get scan params
if ~exist('scans','var'),       scans           = viewGet(vw, 'curScan');   end
if notDefined('useScanDialog'), useScanDialog   = false;                    end
if useScanDialog,               scans           = er_selectScans(vw);       end
if isempty('scans'),            disp('User aborted');    return;            end
if ~exist('getRawData', 'var'), getRawData      = false;                    end
%------------------------------------------------------------------------

% Special case: if this is a FLAT view, auto-xform the ROI to INPLANE and
% plot the time series from the INPLANE. (This is because we don't have an
% agreed-upon way of xforming time series to FLAT). Otherwise, we proceed
% on the current view.
if isequal(vw.viewType, 'Flat')
    data = flat2ipPlotMeanTSeries(vw, scans);
    return
end

graphwin = selectGraphWin;

for scan = scans
    ind = find(scans == scan);

    nCycles   = viewGet(vw, 'numCycles', scan);
    frameRate = viewGet(vw, 'framerate', scan);
    framesToUse = viewGet(vw, 'frames to use', scan);
    
    % Get ROI coords
    if viewGet(vw, 'selected ROI'), ROIcoords = viewGet(vw, 'ROI coords');
    else,  myErrorDlg('No current ROI');
    end

    % compute the mean tSeries
    try
        tSeries = meanTSeries(vw,scan,ROIcoords, getRawData);
    catch ME
        warning(ME.identifier, '%s', ME.message);
        if scan == scans(1), roiXformView(vw); end
        tSeries = roiMeanTSeries(scan, getRawData);
        if iscell(tSeries), tSeries = tSeries{1}; end
    end
    
    %tSeries
    nFrames = length(tSeries);
    
    % plot it
    figure(graphwin);
    fontSize = 14;
    t = linspace(0,(nFrames-1)*frameRate,nFrames)';
    ROIname = vw.ROIs(vw.selectedROI).name;
    headerStr = ['Mean tSeries, ROI ',ROIname,', scan ',num2str(scans)];
    set(gcf,'Name',headerStr);    
    h(ind) = plot(t,tSeries,'LineWidth',2);
    xtick = frameRate*linspace(framesToUse(1)-1, framesToUse(end), nCycles+1) ;
    %  0:length(framesToUse)*frameRate/nCycles:length(framesToUse)*frameRate;
    
    set(gca,'xtick',xtick)
    set(gca,'FontSize',fontSize)
    xlabel('Time (sec)','FontSize',fontSize)
    ylabel('Percent modulation','FontSize',fontSize)
    if getRawData, ylabel('Raw Signal','FontSize',fontSize); end
    
    set(gca,'XLim',[0,nFrames*frameRate]);
    grid on
    
    hold on;
    %Specify data to be saved as 'UserData'
    data.scan{ind}.frameNumbers = t;
    data.scan{ind}.tSeries = tSeries;
end

% if multiple scans, make each t-series a diff color and make a legend
if length(scans) > 1
    color_tmp=hsv(length(scans));
    
    scanList = cell(1, length(scans));
    for ii = 1:length(scans)
        set(h(ii), 'color', color_tmp(ii, :));
        scanList{ii}=viewGet(vw, 'annotation', scans(ii));
    end
    h_legend = legend(scanList); 
    set(h_legend, 'FontSize', 10);
    
    % if we plot multiple scans, check which one has the most time points,
    % and use this one to set the limits and tick marks on the x-axis
    [nFrames, whichscan] = max(viewGet(vw, 'nFrames', scans));        
    frameRate = viewGet(vw, 'frameRate', whichscan);
    nCycles = viewGet(vw, 'nCycles', whichscan);
    framesToUse = viewGet(vw, 'framesToUse', whichscan);
    set(gca,'XLim',[0,nFrames*frameRate]);    
    xtick = 0:length(framesToUse)*frameRate/nCycles:length(framesToUse)*frameRate;
    set(gca,'xtick',xtick)
end

% if only one scan, return a struct instead of a cell
if length(scans) == 1, data = data.scan{1}; end

% set user data
set(gca,'UserData',data);

return;
