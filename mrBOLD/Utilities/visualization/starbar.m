function h = starbar(Y,E,sel,varargin);
% STARBAR: draw bar graph with asterisks over selected bars.
%
% Usage: h = starbar(Y,E,sel,[option]);
%
% This will draw a bar graph of the data in Y, overlay error 
% bars specified in E (which should be a vector the same size as
% Y), and adds asterisks over the data points in sel.
%
%  Y is a matrix of column vectors containing the 
% data to be plotted, E is a matrix the same size as Y containing 
% error lengths for each point. (In this respect, it is the same
% as calling ERRORBAR(Y,E).) sel can either be: 
%      1) a matrix the same size as Y and E, with a 1 at each
%         location which will get an asterisk and a 0 otherwise, or
%   
%      2) a vector equal to the # of rows or columns, selecting entire
%         rows or columns for asterisks.
%
% Options are:
%
%       'stacked':  plot bars stacked on top of each other, instead of
%                   side by side.
% 
%       'legend':   pass as the next entry a cell-of-strings containing
%                   legend text. (NOTE: haven't got it yet where future
%                   legend operations on a starbar plot work nicely;
%                   the colors are messed up.)
%
%       'color':    pass the color of the bars (1x3 vector or character)
%                   as the next option. Can also pass a cell array of
%                   colors for each set of bars, as per setLineColors.
%
%       'X':        pass a matrix X the size of Y and E, provding the X
%                   values of the bars.
%
%		'lineWidth': pass the line width of the edges of the bars as the
%					next option.
%
%
% Returns h, a 2x1 cell array with the handles to the bar series in the
% first entry, and the handles to the errorbar series in the second entry.
%
% 05/29/03 ras
% 02/01/04 ras: screwed with it a bunch. I think this makes it better. :)
% 07/04 ras: added little crossbars at Y-E and Y+E for each box.
% 05/08 ras: fixed bug which involves MATLAB 7.0+; restored the cla
% command, so this clears the current axes before plotting. Also added
% support for multiple colors, and line width option.
if notDefined('sel'),    sel = zeros(size(Y));		end

% defaults
stackedFlag = 0;
plotOptions = {};
col = 'b';
lineWidth = 1.5;
fontsz = 24;
X = [];

% parse the options
if ~isempty(varargin)
    for i = 1:length(varargin)
        if ischar(varargin{i})
            switch lower(varargin{i})
                case 'stacked',
                    stackedFlag = 1;
                case 'legend',
                    leg = varargin{i+1};
                case 'x',
                    X = varargin{i+1};
                case {'color', 'colors' 'col'}
                    col = varargin{i+1};
				case 'linewidth',
					lineWidth = varargin{i+1};
                    plotOptions{end+1} = varargin{i};
                    plotOptions{end+1} = varargin{i+1};
				case {'fontsize', 'fontsz'},
					fontsz = varargin{i+1};
                otherwise,
                    plotOptions{end+1} = varargin{i};
            end
        end
    end
end

% size check
if size(Y) ~= size(E)
    help(mfilename)
    error('Y and E should be the same size.')
end

if size(Y) ~= size(sel)
    help(mfilename)
    error('Y and sel should be the same size.')
end    

% allow for row vectors to be passed in
if size(Y,1)==1 & size(Y,2) > 1
    Y = Y';
    E = E';
    sel = sel';
end
        

%%%%% plot bars %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% to do this cleanly, we can't have other objects in the current axes
cla

if isempty(X)
    X = [1:size(Y,1)]';
end

if stackedFlag
    h{1} = bar(Y,'stacked', 'LineWidth', lineWidth);
else
    h{1} = bar(Y,'grouped', 'LineWidth', lineWidth);
end

if isempty(plotOptions)
    plotOptions = {};
end

if stackedFlag
    plotOptions = [{'stacked'} plotOptions];
else
    plotOptions = [{'grouped'} plotOptions];
end
cmd = ['bar(X, Y'];
for i = 1:length(plotOptions)
	if isnumeric(plotOptions{i})
		cmd = [cmd ', ' num2str(plotOptions{i})];
	else
	    cmd = [cmd ', ''' plotOptions{i} ''''];
	end
end
cmd = [cmd ');'];
htmp = eval(cmd);
% set(htmp,'FaceColor',col);
if ~iscell(col), col = {col}; end
setLineColors(col);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% add legend if selected
if exist('leg','var')
	if iscell(leg)
		cmd = ['legend(''' leg{1} ''''];
		for i = 2:length(leg)
			cmd = [cmd ',''' leg{i} ''''];
		end
		cmd = [cmd ');'];
		eval(cmd);
	else
		legend(leg);
	end
end

% figure out if entire rows/colums are selected for asterisks
if length(sel)==size(Y,1) & isequal(unique(sel),[0 1])
    sel = repmat(sel,size(Y,2),1)';
elseif length(sel)==size(Y,2) & isequal(unique(sel),[0 1])
    sel = repmat(sel,size(Y,1),1);
end

%% a tricky bit, necessary only for when Y is a matrix:
% (if Y is e.g. 4 x 2, then at each X location of 1,2,3,4,
% there will be two bars plotted -- one slightly to the left
% and one slightly to the right of each integer. So, we need to
% find where exactly the x locations are)
if size(Y,1) > 1 & size(Y,2) > 1
	% we re-set the Y and X matrices to be zero: we'll recollect the
	% positions from the existing bar plots, but with the X positions more
	% accurately recorded:
	oldY = Y; oldX = X;  % save these values for debugging purposes
	Y = []; X = [];
	
	% there's the added wrinkle that older MATLAB versions render bars as
	% straight-up sets of PATCH objects, while newer MATLAB (7.0+) group
	% them into an 'hggroup' type. Here I try to check all my bases. 
	barseries = findobj('Type', 'hggroup', 'Parent', gca);
	
	for obj_handle = [gca barseries(1:size(E, 2))']
		boxes = findobj('Type', 'patch', 'Parent', obj_handle);
		for i = 1:length(boxes)
			tmp = get(boxes(i),'XData');
			X = [X mean(tmp(2:3,:))'];
			tmp = get(boxes(i),'YData');
			Y = [Y mean(tmp(2:3,:))'];    
		end

		% The 'bar' command seems to make the bars in an unpredictable
		% order. It seems that the columns in X are not always ascending.
		% Here we re-sort the columns to be ascending, and sort Y
		% correspondingly:
		[vals I] = sortrows(X'); 
		X = X(:,I);
		Y = Y(:,I);
	end
end

%%%%%% plot error bars
hold on, h{2} = errorbar(X, Y, E, 'k', 'LineStyle', 'none', 'LineWidth', lineWidth);

%%%%%% add little cross lines at X+E and X-E, tricky
% boxes = findobj('Type','patch','parent',gca);
% boxWidth = get(boxes(1),'Vertices');
% boxWidth = max(boxWidth(:,1)) - min(boxWidth(:,1));
% xWidth = 0.05 * boxWidth; % width of cross bars
xWidth = 0.05; % width of cross bars
for i = 1:size(X,1)
    for j = 1:size(X,2)
        htmp = line([X(i,j)-xWidth X(i,j)+xWidth],[Y(i,j)-E(i,j) Y(i,j)-E(i,j)]);
        set(htmp, 'Color', 'k', 'LineWidth', lineWidth);
        htmp = line([X(i,j)-xWidth X(i,j)+xWidth],[Y(i,j)+E(i,j) Y(i,j)+E(i,j)]);
        set(htmp, 'Color', 'k', 'LineWidth', lineWidth);
    end
end

%%%%%% add asterisks
AX = axis;
xSz = AX(2) - AX(1);
ySz = AX(4) - AX(3);

whichPoints = find(sel);

for i = 1:length(whichPoints)
    pt = whichPoints(i);
    xLoc = X(pt);
    yLoc = Y(pt) + E(pt) + 0.02*ySz;
    h2 = text(xLoc,yLoc,'*');
    set(h2,'Fontsize',fontsz,'HorizontalAlignment','center');
end

return
