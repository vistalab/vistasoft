function handles = starbarweb(barvalues, errors, width, groupnames, bw_title, bw_xlabel, bw_ylabel, bw_colormap, gridstatus, bw_legend, asterisks)

%
% Usage: handles = starbarweb(barvalues, errors, width, groupnames, bw_title, bw_xlabel, bw_ylabel, bw_colormap, gridstatus, bw_legend, asterisks)
%
% Ex: handles = starbarweb(my_barvalues, my_errors, [], [], [], [], [], bone, [], [],asterisks)
%
% barweb is the m-by-n matrix of barvalues to be plotted.
% barweb calls the MATLAB bar function and plots m groups of n bars using the width and bw_colormap parameters.
% If you want all the bars to be the same color, then set bw_colormap equal to the RBG matrix value ie. (bw_colormap = [1 0 0] for all red bars)
% barweb then calls the MATLAB errorbar function to draw barvalues with error bars of length error.
% groupnames is an m-length cellstr vector of groupnames (i.e. groupnames = {'group 1'; 'group 2'}).  For no groupnames, enter [] or {}
% The errors matrix is of the same form of the barvalues matrix, namely m group of n errors.
% Gridstatus is either 'x','xy', 'y', or 'none' for no grid.
% No legend will be shown if the legend paramter is not provided
% asterisks is a matrix (same form as barvalues & errors) will place asterisks above the relevant bar
%
% The following default values are used if parameters are left out or skipped by using [].
% width = 1 (0 < width < 1; widths greater than 1 will produce overlapping bars)
% groupnames = '1', '2', ... number_of_groups
% bw_title, bw_xlabel, bw_ylabel = []
% bw_color_map = jet
% gridstatus = 'none'
% bw_legend = []
% asterisks = []
%
% A list of handles are returned so that the user can change the properties of the plot
% handles.curr_axis: handle to current axis
% handles.bars: handle to bar plot
% handles.errors: a vector of handles to the error plots, with each handle corresponding to a column in the error matrix
% handles.title: handle to plot title
% handles.xlabel: handle to xlabel
% handles.ylabel: handle to ylabel
% handles.legend: handle to legend
% handles.ca: handle to current axis
%
%
% See the MATLAB functions bar and errorbar for more information
%
% Author: Bolu Ajiboye
% Created: October 18, 2005 (ver 1.0)
% Updated: Dec 07, 2006 (ver 2.1)
% remus 6/2009: branched from barweb (availble from Matlab Central)-added option of drawing asterisks

% Get function arguments
if nargin < 2
    error('Must have at least the first two arguments:  barweb(barvalues, errors, width, groupnames, bw_title, bw_xlabel, bw_ylabel, bw_colormap, gridstatus, bw_legend)');
elseif nargin == 2
    width = 1;
    groupnames = 1:size(barvalues,1);
    bw_title = [];
    bw_xlabel = [];
    bw_ylabel = [];
    bw_colormap = jet;
    gridstatus = 'none';
    bw_legend = [];
    asterisks = [];
elseif nargin == 3
    groupnames = 1:size(barvalues,1);
    bw_title = [];
    bw_xlabel = [];
    bw_ylabel = [];
    bw_colormap = jet;
    gridstatus = 'none';
    bw_legend = [];
    asterisks = [];
elseif nargin == 4
    bw_title = [];
    bw_xlabel = [];
    bw_ylabel = [];
    bw_colormap = jet;
    gridstatus = 'none';
    bw_legend = [];
    asterisks = [];
elseif nargin == 5
    bw_xlabel = [];
    bw_ylabel = [];
    bw_colormap = jet;
    gridstatus = 'none';
    bw_legend = [];
    asterisks = [];
elseif nargin == 6
    bw_ylabel = [];
    bw_colormap = jet;
    gridstatus = 'none';
    bw_legend = [];
    asterisks = [];
elseif nargin == 7
    bw_colormap = jet;
    gridstatus = 'none';
    bw_legend = [];
    asterisks = [];
elseif nargin == 8
    gridstatus = 'none';
    bw_legend = [];
    asterisks = [];
elseif nargin == 9
    bw_legend = [];
    asterisks = [];
elseif nargin == 10
    asterisks = [];
end

change_axis = 0;

if isempty(asterisks)
    asterisks = zeros(size(barvalues));
end

if size(barvalues,1) ~= size(errors,1) || size(barvalues,2) ~= size(errors,2) || size(barvalues,1) ~= size(asterisks,1) || size(barvalues,2) ~= size(asterisks,2)
    error('barvalues, error, and asterisks matrices must be of same dimension');
else
    if size(barvalues,2) == 1
        barvalues = barvalues';
        errors = errors';
        asterisks = asterisks';
    end
    if size(barvalues,1) == 1
        barvalues = [barvalues; zeros(1,length(barvalues))];
        errors = [errors; zeros(1,size(barvalues,2))];
        asterisks = [asterisks; zeros(1,size(barvalues,2))];
        change_axis = 1;
    end
    numgroups = size(barvalues, 1); % number of groups
    numbars = size(barvalues, 2); % number of bars in a group
    if isempty(width)
        width = 1;
    end

    % Plot bars and errors
    handles.bars = bar(barvalues, width); hold on
    if ~isempty(bw_colormap)
        colormap(bw_colormap);
    else
        colormap(jet);
    end
    groupwidth = min(0.8, numbars/(numbars+1.5));

    astDist = .05*max(max(barvalues));
    
    for i = 1:numbars
        x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);
        handles.errors(i) = errorbar(x, barvalues(:,i), errors(:,i), 'k', 'linestyle', 'none');
        errorInfo = get(handles.errors(i));
        
        astX = errorInfo.XData.*asterisks(:,i);
        astX(~astX)=[];

        astY = (errorInfo.YData+errorInfo.UData+astDist).*asterisks(:,i);
        astY(~astY)=[];

        text(astX,astY,'*','FontSize',16, 'HorizontalAlignment','center');       
    end
    set(gcf, 'color', 'white')
    
    if ~isempty(bw_title)
        handles.title = title(bw_title, 'fontsize',14);
    else
        handles.title = [];
    end
    if ~isempty(bw_xlabel)
        handles.xlabel =xlabel(bw_xlabel, 'fontsize',14);
    else
        handles.xlabel = [];
    end
    if ~isempty(bw_ylabel)
        handles.ylabel =ylabel(bw_ylabel, 'fontsize',14);
    else
        handles.ylabel = [];
    end

%     set(gca, 'xticklabel', groupnames, 'box', 'off', 'ticklength', [0 0], 'fontsize', 14, 'xtick',1:numgroups);
    set(gca, 'xticklabel', groupnames, 'box', 'off', 'fontsize', 14, 'xtick',1:numgroups);
    if isequal(gridstatus, 'x')
        set(gca,'xgrid','on');
        set(gca,'ygrid','off');
    elseif isequal(gridstatus, 'y')
        set(gca,'xgrid','off');
        set(gca,'ygrid','on');
    elseif isequal(gridstatus, 'xy')
        set(gca,'xgrid','on');
        set(gca,'ygrid','on');
    else
        set(gca,'xgrid','off');
        set(gca,'ygrid','off');
    end

    xlim([0.5 numgroups-change_axis+0.5]);

    if ~isempty(bw_legend)
        handles.legend = legend(bw_legend, 'Location', 'Best', 'fontsize',8);
        legend boxoff;
    else
        handles.legend = [];
    end

    handles.ca = gca;

    hold off
end

return
