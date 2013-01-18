function h = fancyplot(data,E,varargin);
% FANCYPLOT: plot, fancy style.
% h = fancyplot(data,[E],[options]);
%
% This function opens/updates a window with data for several conditions,
% adding selection buttons for things like error bars, which conditions 
% to display, and a button to set the "zero" point (by default the first 
% time point, but can be set to something else as an option) equal for all
% conditions. Returns a handle to the figure.
%
% This was designed originally to plot time course data, e.g. a matrix
% of time courses for responses to different conditions.
%
%   data: an n x p matrix to be plotted. The p columns will be treated as
%   different conditions, so there will be p traces on the plot.
%
%   E: a matrix the same size as data, containing error bar sizes.
%
% Options:
%
%   'X': pass the values for the X axes as the next argument (should be
%       an n-vector, where n is the number of rows in data). By default
%       it plots the points on X values from 0:n-1.
%
%   'leg':  add a legend (should be passed as the next argument, as a
%       cell-of-strings).
%
%   'zeroPoint': the time point (<= number of rows in data) to consider the
%       "zero time point", for zeroing across conditions. Pass as the next 
%       argument. Default is first point.
%
% 10/02 by ras (ras_refreshAvgTrialsWindow)
% 11/04/02 ras: allows input of data, legend labels, and prestim size
% 04/25/03 ras: now fancy.
% 04/28/03 ras: added my custom homebrew colormap to the plot. This may not
% be a good thing.
if ~exist('data','var')         data = [];                     end
if ~exist('E','var')            E = [];                        end

%%%%% defaults
leg = [];
zeroPoint = [];
X = [];

%%%%% parse the option flags 
for i = 1:length(varargin)
    if ischar(varargin{i})
        switch lower(varargin{i})
            case 'leg',
                leg = varargin{i+1};
            case 'zeropoint',
                zeroPoint = varargin{i+1};
            case 'x',
                X = varargin{i+1};
        end
    end
end

% check for existing windows; get handle of current window
existingWindows = findobj('Tag','fancyplotAxes');
if  nargin >= 1
    h = openfancyplot(data,E,leg,zeroPoint);
elseif ~isempty(existingWindows)
    h = gcf;
else
    % need either to have an existing window, or data arg
    fprintf('Usage: h = fancyplot(data,[SEMs],[options]);\n')
	return    
end

figure(h);

% # of conditions stored in userData of current figure
nConds = get(gcf,'UserData');
for cond = 1:nConds 
    tag = ['Cond',num2str(cond),'Check'];
    whichConds(cond) = get(findobj('Tag',tag,'Parent',h),'Value');
end
addErrorBars = get(findobj('Tag','SEMCheck','Parent',h),'Value');
zeroT0Flag = get(findobj('Tag','zeroT0Check','Parent',h),'value');

% zeroPoint is stored in zeroT0Check box -- if not passed as an option
if isempty(zeroPoint)
    zeroPoint = get(findobj('Tag','zeroT0Check','Parent',gcf),'UserData');
    if isempty(zeroPoint)        zeroPoint = 1;    end
end

% get data to plot, either from data or from the axes' UserData
axs = findobj('Tag','fancyplotAxes','Parent',h);
if isempty(data)
	plotData = get(axs,'UserData');
    winSz = size(plotData,1)/2;
    data = plotData(1:winSz,:);
    E = plotData(winSz+1:end,:);
    tmp = get(axs,'Children');
    X = get(tmp(1),'XData');
end

if isempty(E)
    E = zeros(size(data));
    addErrorBars = 0;
    set(findobj('Tag','SEMCheck'),'Value',0);
end

plotData = [data; E];

if isempty(X)
    X = [1:size(data,1)] - zeroPoint;
end

% using rory's custom colormap
colOrder = ras_colorOrder(nConds);

% if some conditions are selected not to be plotted,
% remove them from data/variances
if sum(whichConds) ~= length(whichConds)
    data = data(:,find(whichConds));
    E = E(:,find(whichConds));
    colOrder = colOrder(find(whichConds),:);
end

% if flag is set to align conditions at time 0, do so
if zeroT0Flag
    for cond = 1:size(data,2)
        offset = data(zeroPoint,cond);
        data(:,cond) = data(:,cond) - offset;
    end
end

% set rory's custom colormap
set(gca,'NextPlot','replacechildren');
set(gca,'ColorOrder',colOrder);

% plot the data
axes(findobj('Tag','fancyplotAxes','Parent',h));
if addErrorBars
    X = repmat(X(:),1,size(data,2));
    errorbar(X,data,E);
else
    plot(X,data);
end

% axis auto;

set(gca,'UserData',plotData);
set(gca,'Tag','fancyplotAxes');

% add labels, legends etc.
leg = {};
whichConds = find(whichConds);
for cnt = 1:length(whichConds)
    i = whichConds(cnt);
    checkbox = findobj('Tag',['Cond',num2str(i),'Check'],'Parent',h);
    leg{cnt} = get(checkbox,'UserData');
	if cnt > length(leg) | isempty(leg{cnt})
        leg{cnt} = ['Condition ',num2str(i)];
	end
    set(checkbox,'String',leg{cnt});
end
legend(gca,leg,-1);

set(get(gca,'Children'),'LineWidth',2);
% set(gca,'XTick',X(:,1));


return
% /-----------------------------------------------------------/ %



% /-----------------------------------------------------------/ %
function h = openfancyplot(data,E,leg,zeroPoint);
% opens a fancyplot window when one doesn't exist.
% (I store information in the 'UserData' field of various objects.) 
nConds = size(data,2);
whichConds = ones(nConds,1);
plotAllFlag = 0;
addErrorBars = 1;

% check for other average trial windows
existingWindows = findobj('Tag','fancyplotAxes');
winNum = length(existingWindows) + 1;

% open window 
h = figure;
set(h,'Tag',['fancyplot',num2str(winNum)]);

% set up buttons:
uicontrol('Style','checkbox','Units','Normalized','Position',[0.05 0.05 0.12 0.04],...
   'String','Error bars','Value',1,'Callback','fancyplot;','Tag','SEMCheck');

% Zero at T0 button callback:
h1 = uicontrol('Style','checkbox','Units','Normalized','Position',[0.15 0.05 0.12 0.04],...
   'String','Align traces','Value',0,'Callback','fancyplot;','Tag','zeroT0Check');
set(h1,'UserData',zeroPoint);

% set up axes
axes('Position',[0.2 0.1 0.7 0.8]);

% default legend
for cond = 1:nConds
	if cond > length(leg) | isempty(leg{cond})
        leg{cond} = ['Condition ',num2str(cond)];
	end
end

% for each condition set up a separate check box
% to activate / inactivate display of that condition
for cond = 1:nConds
    pos = [0 1-(0.04*cond) 0.12 0.04];
    str1 = ['Condition ',num2str(cond)];
    tag = ['Cond',num2str(cond),'Check'];
    h1 = uicontrol('Style','checkbox','Units','Normalized','Position',pos,...
        'String',str1,'Value',1,'Callback','fancyplot;','Tag',tag);
    set(h1,'UserData',leg{cond});
end

% put plot data in 'UserData' of the Axes
plotData = [data; E];
set(gca,'Tag','fancyplotAxes');
set(gca,'UserData',plotData);
set(gcf,'UserData',nConds);

return
