function [h, R, p] = regressPlot(X,Y,varargin);
% [h, R, p] = regressPlot(X,Y,[options]);
%
% Plots a bunch of data points in X and Y against each other,
% fits a regression line, and prints out R^2 in the corner of
% the plot.
%
% Options:
%
% 'x=y': in addition to plotting the fitted regression line, plot the line for
% x=y, and make the axes equal in the X and Y directions.
%
% 'angle': flag indicating that the X and Y data are angle measurements in
% radians. Angle data of this sort "wraps around": values near 0 and 2*pi
% are very similar to one another. When a simple linear regression is 
% applied to this data, the regression is often thrown off by the
% wraparound, since small variability around 0 and 2pi is estimated as a
% large residual from the fitted line. When the 'angle' option is set, the
% X and Y data are projected into the complex plane, and the amplitude of
% the projection is taken, preventing this error. (?)
% 
% 'alpha': change the confidence parameter for the regression
% fitting. It defaults to 0.05.
%
% 'nolabel': don't add text labels for R^2 and p to the graph.
%
% 'title': add the stats label as a title, instead of text to the side.
%
% 'font': set font name for reporting R^2 and p(default: 'Arial').
%
% 'fontsz': set font size for reporting R^2 and p (default: 12-pt.).
%
% 'symbol': set symbol for data points (default: '+').Can also enter it
% directly if it is one of the following: +, o, ., x, *, $.
%
% 'onecolor': if matrices are passed in, make into linear vectors before
% plotting, so symbols are all the same color. Not doing this is used to
% e.g. color-code data from different subjects, to eyeball
% inter-subject-driven regressions. NOTE: will do this automatically if
% either X or Y has NaNs in it.
%
% 'legend',{leglabels}: add a legend with the specified labels
% (cell-of-strings).
%
% 'symbols',[{values}] or 'multisymbol',[{values}]: if X is a matrix of columns,
% instead of coloring each column, use different symbols (useful if
% preparing
% black&white plots). If a cell is passed as the next argument, this will
% be interpreted as specifying the symbols for each column (symbol shape
% and color strings -- see HELP PLOT for options).
%
% 'colormap', [colors]: inflect each data point with a particular color. There
% are two ways to provide this parameter:
%       (1) colors is an N x 3 matrix, where N is the # of points in X and Y.
%       The n-th row will specify the [R G B] values of that point, from
%       0 - 1.
%       (2) colors is a cell with two elements: a weights vector and a
%        color map. The weights vector should have N points (same as X and
%        Y), while the color map is an Mx3 color map, or the name of a
%        color map such as 'hot' or 'jet'. In this case, the weights vector
%        determines the color of a given point; the weights are auto-scaled
%        such that the highest weight maps to the last entry in the color
%        map, and the lowest weight maps to the first.
%        E.g.: regressPlot(X, Y, 'colors', {W 'hot'}),
%              regressPlot(X, Y, 'colors', {W hsv(24)}).
%
% 'confidencebounds': plot 75% confidence bounds parallel to the regression
% line.
%
% 04/03 ras
% 10/03 ras: updated to deal w/ NaNs, added several optional arguments.
% 12/03 ras: intelligently places label depending on regression line slope,
% added multisymbol option, confidencebounds option.
% 06/06 ras: if can't locate stats toolbox REGRESS function, uses other
% tools instead.
% 09/09 ras: reports R instead of R^2 -- this gives the sign of the
% regression.
xyLine = 0;
angleFlag = 0;
alpha = 0.05;
labelOn = 1;
font = 'Arial';
fontsz = 12;
symbol = 'o';
multisymbol = 0;
confbounds = 0;
leg = {};  % if empty, no legend
colors = {'k'};

% default marker size depends on the # of samples -- for large samples,
% use a smaller marker
if length(X) < 100
	markerSize = 5;
elseif length(X) < 1000
	markerSize = 3;
else
	symbol = '.';
	markerSize = 1;
end

%%%%% parse the option flags
if ~isempty(varargin)
    for i = 1:length(varargin)
        if ischar(varargin{i})
            switch lower(varargin{i})
                case {'x=y' 'x==y' 'x = y'}
                    xyLine = 1;
				case {'angle' 'polar' 'radians'}
					angleFlag = 1;
                case 'alpha',
                    alpha = varargin{i+1};
                case {'nolabel','nolabels'},
                    labelOn = 0;
                case {'title','ttl','ttllabel'},
                    labelOn = 2; fontsz = 9;
                case {'labelfont','font'}
                    font = varargin{i+1};
                case {'labelfontsz','fontsz','fontsize'}
                    fontsz = varargin{i+1};
                case {'o','+','x','*','.','$'}
                    symbol = varargin{i};
                case 'legend',
                    leg = varargin{i+1};
                case 'symbol',
                    symbol = varargin{i+1};
                case 'onecolor',
                    X = X(1:size(X,1)*size(X,2)*size(X,3));
                    Y = Y(1:size(X,1)*size(X,2)*size(X,3));
                case {'color','colors'},
                    colors = {varargin{i+1}};
                case {'colormap' 'cmap'},
                    multisymbol = 1;
                    colors = parseColorMap(X, Y, varargin{i+1});
                    symbols = repmat({symbol}, [1 length(X)]);
                case 'extend',
                    bounds = varargin{i+1};
                case {'markersize' 'markersz' 'sz'}
                    markerSz = varargin{i+1};
                case {'multisymbol','symbols'}
                    multisymbol = 1;
                    if i < length(varargin) & iscell(varargin{i+1})
                        symbols = varargin{i+1};
                    else
                        symbols = {'o','s','x','*','+','d','<','>','^',...
                            'p','h'};
                        for j = 1:length(symbols)
                            symbols{j} = ['r' symbols{j}];
                        end
                    end
                case {'confidencebounds','confbounds'}
                    confbounds = 1;
                otherwise,
                    %                     fprintf('ras_regressPlot unrecognized flag.\n');
            end
        end
    end
end

% remove any NaNs in the inputs
if any(any(isnan(X))) | any(any(isnan(Y)))
    ind = find(~isnan(X) & ~isnan(Y));
    X = X(ind);
    Y = Y(ind);
end

% deal w/ angular data
if angleFlag==1
	%% not yet implemented
end

%%%%% plot the points
cla
hold on
plot(X, Y, symbol, 'markersize', 2);
if multisymbol
    while length(symbols) < size(X,2)
        symbols = [symbols symbols];
    end
    cla;
    for j = 1:size(X,2)
        plot(X(:,j), Y(:,j), symbols{j}, 'markersize', markerSz);
    end
end
axis square
axis tight

%%%%%% set symbol colors
setLineColors(colors);

%%%%% add legend if specified
if ~isempty(leg)
    legend(leg,-1);
end

%%%%% do regression analysis, add fitted line
% plot x=y line if requested
if xyLine==1
    AX = axis;
    newAX = [ min(AX([1 3])), max(AX([2 4])) ];
    line(newAX, newAX, 'LineWidth', 2, 'Color', [.5 .5 .5], 'LineStyle', '--');
    axis([newAX newAX]);    
end

Y = reshape(Y,[1 size(Y,1)*size(Y,2)]);
X = reshape(X,[1 size(X,1)*size(X,2)]);

% calculate a fitted line to the data
AX = axis;
pts = linspace(AX(1), AX(2), length(X));
[P S] = polyfit(X,Y,1); % this only does a first-order fit
[LN,delta] = polyval(P,pts,S);

if confbounds
    hold on, errorbar(pts,LN,delta,'m:');
    plot(pts,LN+delta,'m:');
    plot(pts,LN-delta,'m:');
end

hold on, plot(pts, LN, 'r', 'linewidth', 2);


%%%%% the main regression
if exist('regress', 'file')
    % original version, uses stats toolbox
    [B,BINT,R,RINT,stats] = regress(Y',[X' ones(length(X),1)],alpha);
    LN = B(1)*pts + B(2);

else
    % (alt version for w/o stats toolbox)
    stats = [R(2)^2 0 p(2)];
    B = 0; BINT = 0; R = 0; RINT = 0;
end

% let's report R instead of R^2
[R p] = corrcoef(X(:), Y(:));
R = R(2);
p = p(2); 

% set axes, text label
% AX = axis;
% AX(1) = 0.9*min(X); AX(2) = 1.1*max(X);
% AX(3) = 0.9*min(Y); AX(4) = 1.1*max(Y);
% axis(AX);
if labelOn > 0
    AX = axis;
    xloc = AX(1)+1*(AX(2)-AX(1));
    if B(1) > 0
        yloc = AX(3)+0.2*(AX(4)-AX(3));
    else
        yloc = AX(3)+0.9*(AX(4)-AX(3));
    end

    if labelOn==1 % label on side
        msg = sprintf('R: %1.2f \n%s', R, pvalText(p, 1));

        text(xloc,yloc,msg,'Color','k','HorizontalAlignment','left',...
            'FontSize',fontsz,'FontName',font);
    else
        msg = sprintf('R: %1.2f, %s', R, pvalText(p, 1));

        title(msg, 'FontSize', fontsz, 'FontName', font);
    end
end

% add some text in the stdout displaying the results nicely
if stats(3) < 10^(-2)
    bound = num2str(floor(log10(stats(3))));
    ptxt = sprintf('p < 10e%s',bound);
else
    ptxt = sprintf('p = %1.2f',stats(3));
end
fprintf('Regression Results: \t')
fprintf('Y = %3.2f*X + %3.2f, R^2 = %3.2f, F = %3.2f, %s\n', ...
		P(1), P(2), stats(1), stats(2), ptxt);

% set the output arguments nicely
h = gca;

tmp = stats; clear stats;
stats.R2 = tmp(1);
stats.F = tmp(2);
stats.p = tmp(3);
stats.betas = B;
stats.betaConfIntervals = BINT;
stats.residuals = R;
stats.resConfIntervals = RINT;
stats.lineCoefficients = P;
stats.linefitStruct = S;
stats.alpha = alpha;

return
% /-------------------------------------------------------------------/ %




% /-------------------------------------------------------------------/ %
function colors = parseColorMap(X, Y, arg);
% given a color map specification for the data points, translate this
% into [R G B] triplets for each data point. The 2 possible specifications
% are described in the regressPlot header comments.
% Hope this works...
if iscell(arg)   % {weights cmap}
    W = arg{1};
    cmap = arg{2};

    if ~isnumeric(W) | length(W) ~= length(X) | length(W) ~= length(Y)
        error('Invalid weight specification.')
    end

    if ischar(cmap)
        cmap = eval(cmap);
    elseif ~isnumeric(cmap) | size(cmap, 2) ~= 3
        error('Invalid color map specification.')
    end

    % auto-scale W to match the number of lines in cmap
    nColors = size(cmap, 1);
    W = rescale2(W, [], [1 nColors]);

    % map to an nDataPoints x 3 ([R G B]) color spec
    colors = cmap(W,:);

elseif isnumeric(arg) & size(arg, 2)==3 & size(arg, 1)==length(X)
    colors = arg;

else
    error('Invalid color map specification.')

end





return
