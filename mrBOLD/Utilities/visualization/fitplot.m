function fitplot(varargin)
%FITPLOT adds a linear fit to each data series in a plot
%   With no input arguments, FITPLOT will plot a linear fit to each "line"
%   data series that has a "marker" in the current axes. It will also put
%   the equation describing the fit and the correlation coefficient in the
%   upper left corner of the plot. NaNs are removed from the data. A flag
%   is added to the equation if NaNs were present.
% 
%   FITPLOT(H) where H is a handle to a data series, will plot a linear fit
%   to the data series. H can be a vector with multiple handles.
% 
%   FITPLOT(...,'robust') uses a robust fit instead of a regular fit.
% 
%   FITPLOT could be extended to handle other types of curves (polynomials,
%   exponentials, etc).
%
%   Example:
%       x=(1:100)'; 
%       a=-3*x+400+100*rand(100,1); %Noisy data with NaNs
%       a([10 32 56])=nan;
%       b=2*x+20; %Simple data with a perfect correlation
%       c=10*x-200+50*randn(100,1); %More noisy data
%       figure
%       plot(x,a,'.',x,b,'r.',x,c,'g.')
%       fitplot
%
%   See also POLYFIT, CORRCOEF, ROBUSTFIT, and the Basic Fitting tool in
%   any figure window.
%
%   3/09 AL added a p-value for the line
%   7/09 kgs show r and p value without line formula
%   Copyright Andy Bliss. March 10, 2006

if nargin==0 || (nargin==1 && strcmp(varargin{1},'robust'))
    %get handles of current axes' children. The first series that was
    %   plotted will be last in this list
    datahandles=get(gca,'children');
    %check to see if child type is a line (possible axes children types
    %are: images, lights, lines, patches, surfaces, and text objects)
    lineH=strcmp(get(datahandles,'type'),'line');
    datahandles=datahandles(lineH);
    %and check to see that there is a marker (I don't want to fit line
    %objects, just scatter data that I plotted with a marker)
    linewithmarkerH = ~strcmp(get(datahandles,'Marker'),'none');
    datahandles=datahandles(linewithmarkerH);
    if nargin==0
        robust=0;
    else
        robust=1;
    end
elseif nargin==1 || (nargin==2 && strcmp(varargin{2},'robust'))
    datahandles=varargin{1};
    if ~strcmp(get(datahandles,'type'),'line') || strcmp(get(datahandles,'Marker'),'none')
        error('Handle input does not refer to a line data series with a marker')
    end
    if nargin==1
        robust=0;
    else
        robust=1;
    end
end

%get the parent axes and figure
axesH = get(datahandles(1),'parent');
% figH = get(axesH,'parent'); %turns out this wasn't needed
%make the proper axes current
axes(axesH)
%get the axes ranges to position the text and for polyval
XRange=get(axesH,'XLim');
YRange=get(axesH,'YLim');
%define the text position
XTextPos=XRange(1)+0.05*(XRange(2)-XRange(1));
YTextPos=YRange(2)-0.05*(YRange(2)-YRange(1));
YTextPosDiff=0.05*(YRange(2)-YRange(1));

for n=1:length(datahandles)
    %get data and line color
    XData=get(datahandles(n),'XData');
    YData=get(datahandles(n),'YData');
    Color=get(datahandles(n),'Color');
    %Do a regression and get the p-value
    x1=[ones(size(XData)); XData];
    [b,bint,r,rint,stats] = regress(YData', x1');
    p=stats(3);
    %remove NaNs from the data
    bad=isnan(XData) | isnan(YData);
    XData(bad)=[];
    YData(bad)=[];
    %set a flag if there are nans
    if sum(bad)
        nanflag='_{NaN}';
    else
        nanflag='';
    end
    %fit a line to the data
    if robust
        p=robustfit(XData,YData);
        p=flipud(p);
    else
        p=polyfit(XData,YData,1);
    end
    %evaluate line over the range of the current axis
    yfit=polyval(p,XRange);
    %add fit line to the plot
    hold on
    plot([min(XData) max(XData)],yfit,'-','Color','k', 'LineWidth', 1)
    %calculate the correlation between XData and YData
    XYcorr=corrcoef(XData,YData);
    %add the equation text to the plot
   % text(XTextPos,YTextPos-YTextPosDiff*(n-1),sprintf('Y%s = %.4g*X + %.4g, corr = %.3g, p-value= %0.3g ',nanflag,p(1),p(2),XYcorr(3),stats(3)),'Color',Color)
   if stats(3)<0.05
    text(XTextPos,YTextPos-YTextPosDiff*(n-1),sprintf('r=%.3g, p=%0.3g ',XYcorr(3),stats(3)),'Color',Color,'FontWeight','BOLD', 'FontSize', 10); 
   else
    text(XTextPos,YTextPos-YTextPosDiff*(n-1),sprintf('r=%.3g, p=%0.3g ',XYcorr(3),stats(3)),'Color',Color, 'FontWeight','BOLD', 'FontSize', 10); 
   
   end
   %reset axes
    
    set(axesH,'YLim',YRange)
end
