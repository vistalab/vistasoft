function blurTSeriesPlot(blurFcn)
% Blurs the tseries data in the current graph window
%
%   blurTSeriesPlot(blurFcn)
%
% The blurring function, by default, sums to one to preserve the mean. It
% is [0.2500    0.5000    0.2500].  For more blurring, repeat this call.
%
% The plot is created either from plotting mean tSeries, or multiple
% tSeries.  This routine also runs on Single Cycle Plots.  
% 
% Re-written so that it might be extended in the future.  We should
% probably add identifiers to the userData structure in the plot windows.
% (BW)
%
% djh, 3/2001
global GRAPHWIN
if (isempty(GRAPHWIN) || GRAPHWIN==0), myErrorDlg('blurPlot: no graph to blur');
else  set(0,'CurrentFigure',GRAPHWIN);
end
if notDefined('blurFcn'), blurFcn = [1 2 1]; blurFcn = blurFcn/sum(blurFcn); end
axisHandles = get(gcf,'Children');
for h = 1:length(axisHandles)
    subplot(axisHandles(h));
    data = get(gca,'userData');
    
    if isfield(data,'tSeries')
        typeOfPlot = 'tseries';
        data.time = data.frameNumbers;
        data.tSeries = conv2(data.tSeries,blurFcn,'same');
    elseif isfield(data,'x') && isfield(data,'y')
        typeOfPlot = 'singlecycle';
        data.time = data.x;
        data.tSeries = conv2(data.y,blurFcn,'same');
    else
        myErrorDlg('blurPlot: cannot identify plot type.  Edit blurTseriesPlot')
    end
    
    % get plot properties
    xLim = get(gca,'xLim');    yLim = get(gca,'yLim');
    xTick = get(gca,'xTick');  yTick = get(gca,'yTick');
    xGrid = get(gca,'xGrid');  yGrid = get(gca,'yGrid');
    fontName = get(get(gca,'xlabel'),'fontName');
    fontSize = get(get(gca,'xLabel'),'fontSize');
    xLabel   = get(get(gca,'xLabel'),'String');
    yLabel   = get(get(gca,'yLabel'),'String');
    titleStr = get(get(gca,'title'),'String');
    
    color = get(get(gca,'Children'),'Color');
    if iscell(color), color = color{1}; end
    lineWidth = get(get(gca,'Children'),'lineWidth');
    if iscell(lineWidth), lineWidth = lineWidth{1}; end
        
    switch lower(typeOfPlot)
        case 'tseries'
            p = plot(data.time,data.tSeries);
        case 'singlecycle'
            p = errorbar(data.time,data.tSeries,data.e);
        otherwise
    end
    
    % Replot the data
    set(p,'lineWidth',lineWidth);
    set(p,'Color',color);
    
    % reset properties
    set(gca,'xLim',xLim);   set(gca,'yLim',yLim);
    set(gca,'xTick',xTick); set(gca,'yTick',yTick);
    set(gca,'xGrid',xGrid); set(gca,'yGrid',yGrid);
    xlabel(xLabel,'fontName',fontName,'fontSize',fontSize);   
    ylabel(yLabel,'fontName',fontName,'fontSize',fontSize);
    title(titleStr,'fontName',fontName,'fontSize',fontSize);
    set(gca,'UserData',data);
    
end
return
    
