function vw = plotMultipleTSeries(vw,scan,ROIlist,sameaxis, getRawData)
% function vw = plotMultipleTSeries(vw,[scan],[ROIlist],[sameaxis], [getRawData] )
%
% plots tSeries for multiple ROIs simultaneously
%
% If you change this function make parallel changes in:
%   plotMeanTSeries, plotFFTTseries, plotMultipleFFTSeries
%
% 11/22/98 rmk
% 7/2001, djh, updated to 3.0
% 2005.04.04 AB added sections to transfer ROI to INPLANE from gray of flat
% so that plots could be made from the gray and flat views as well as from
% inplane.

mrGlobals;

if notDefined('vw'),            vw          = getCurView;               end
if notDefined('scan'),          scan        = viewGet(vw,'curScan');    end
if notDefined('ROIlist'),       ROIlist     = [];                       end
if notDefined('sameaxis'),      sameaxis    = false;                    end
if ~exist('getRawData', 'var'), getRawData  = false;                    end

% Get scan parameters
nCycles     = viewGet(vw, 'numCycles', scan);
frameRate   = viewGet(vw, 'frameRate', scan);
nFrames     = viewGet(vw, 'nFrames', scan);

% Select ROIs
[selectedROIs, nROIs] = roiGetList(vw, ROIlist);

ROIcoords = cell(1,nROIs);
for r=1:nROIs
    ROIcoords{r}=vw.ROIs(selectedROIs(r)).coords;
end


%% Specifics for Flat, Gray, or Inplane views - xform ROI to INPLANE view
% This whole section is duplicated in other functions, like
% plotMultipleSingleCycleErr.m Maybe it should be split off to its own
% function. 

% OK, now it is split off:
tSeries = meanTSeriesForPlotting(vw, selectedROIs, getRawData);

%% Plot it

% selectGraphWin
newGraphWin
hold on;

headerStr = ['Mean tSeries scan ',num2str(scan)];
set(gcf,'Name',headerStr);

% pre-compute the y axis limits
maxY=0;
for t=1:nROIs
    if (max(abs(tSeries{t}))>maxY)
        maxY=max(abs(tSeries{t}));
    end
end

maxY=ceil(maxY+maxY/5);
for r=1:nROIs
    
    % check to see whether we will plot the multiple ROIs as mulitple
    % series in one plot, or in separate subplots
    if ~sameaxis, subplot(nROIs,1,r); end
    
    t = linspace(0,(nFrames-1)*frameRate,nFrames)';
    p = plot(t,tSeries{r}, 'LineWidth', 2);
    % set the line color to be the same as the ROI color 
    set(p,'Color',vw.ROIs(selectedROIs(r)).color);
    % but if the line color and plot color are the same, the line will be
    % invisible (e.g., if the ROI color is white)
    if isequal(get(p, 'Color'), get(gca, 'Color'))
        set(p, 'Color', 1 - get(p, 'Color')); 
    end

    fontSize = 14-nROIs+1;
    if (fontSize<6) 
        fontSize=6;
    end
    
    xtick = 0:nFrames*frameRate/nCycles:nFrames*frameRate;
    set(gca,'xtick',xtick)
    
    set(gca,'FontSize',fontSize)
    if (r==nROIs) % Only lable the bottom graph
        xlabel('Time (sec)','FontSize',fontSize) 
    end
    
    ylabel('Percent modulation','FontSize',fontSize) 

    set(gca,'XLim',[0,nFrames*frameRate]);
    set(gca,'YLim',[-maxY,maxY]);

    if getRawData,
        ylabel('Raw Signal','FontSize',fontSize)
        set(gca,'YLim',[0 maxY]);
    end
    
    name = viewGet(vw, 'roiName', selectedROIs(r));
    if sameaxis,    tmp{r} = name;
    else            title(name);    end

    grid on
    
end


%Save the data in gca('UserData')
data.frameNumbers = t;
data.tSeries = tSeries;
set(gca,'UserData',data);
    
if sameaxis, legend(tmp); end
