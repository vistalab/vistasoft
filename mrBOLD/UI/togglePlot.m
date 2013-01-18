function h = togglePlot(Y, E, X, names, colors, styles);
% Plot time curves with errorbars, and toggles for individual curves.
%
% h = togglePlot(Y, [E], [X], [names], [colors], [styles]);
%
% This is an updated version of my old function FANCYPLOT. It produces
% a plot of the data Y, at points X, with error bar size E. For X, Y, and
% E, different columns represent different errorbar lines while rows
% represent different points along X. If X is omitted, it initializes to 
% [1:size(Y, 1)] for each column. A legend is appended, along with
% checkboxes for each column in Y, which toggles the visibility of that
% data line.
%
% names, colors, and styles are all optional cell arrays specifying the
% names of each column in Y for the legend, the colors associated with each
% line, and the line styles (as set per SETLINESTYLES). 
%
% Returns an aray of handles to the plot elements, in the format
%   [figure, axes, legendPanel, (errorbar handles) (checkbox handles)].
%
% EXAMPLE:
%   X = linspace(0, 2*pi, 40);
%   Y = [cos(X); sin(X); cos(X).^2; tan(X)]';
%   E = .1 * rand(40, 4);
%   names = {'cos' 'sin' 'cos^2' 'tan'};
%   colors = {[1 0 0] [.9 .2 0] [.7 .3 .1] [.5 .5 .3]};
%   styles = {'-2' '--2' '.-2' ':2'};
%   h = togglePlot(Y, E, X, names, colors, styles);
%
% ras, 03/2007.
if notDefined('Y'),     error('Need to specify data Y.');       end
if notDefined('X'),     X = repmat([1:size(Y,1)]', [1 size(Y,2)]);  end
if notDefined('E'),     E = zeros(size(Y));                     end
if notDefined('styles'),    styles = {};                    end

nCols = size(Y, 2); 

if notDefined('names'), 
    for i = 1:nCols
        names{i} = sprintf('Col %i', i);                             
    end
end

% size check on X
if ~isequal(size(X), size(Y))
    if numel(X)==size(Y, 1)
        % single X vec for all columns
        X = repmat(X(:), [1 nCols]);
        
    else
        error('X and Y should be same size.')
        
    end
end


%% create figure, axes
h(1) = figure('Color', 'w');

h(2) = axes;


%% plot the data 
hBars = errorbar(X, Y, E);

% get default colors if not specified
if notDefined('colors'),
    colorOrder = get(h(2), 'ColorOrder');
    while size(colorOrder, 1) < nCols
        colorOrder = [colorOrder; colorOrder];
    end
    
    for col = 1:nCols  
        colors{col} = colorOrder(col,:);                            
    end
end

setLineColors(colors);

if ~isempty(styles)
    setLineStyles(styles);
end


%% add legend panel, checkboxes
hLeg = legendPanel(names, colors);

% callback for each checkbox
cb = ['if get(gcbo,''Value'')==1, TMP=''on''; else, TMP=''off''; end; ' ...
      'set(get(gcbo,''UserData''), ''Visible'', TMP); ' ...
      'clear TMP; '];

% add checkboxes
for n = 1:nCols     
    % these are positions of the axes in LEGENDPANEL
    row = mod(n-1, 20) + 1;
    pos = [.4,  .96-row*.05,  .1,  .025];
        
    hCheck(n) = uicontrol('Parent', hLeg, 'Style', 'checkbox', ...
                    'Units', 'normalized', 'Position', pos, ...
                    'UserData', hBars(n), 'Callback', cb, ...
                    'String', '', 'BackgroundColor', 'w', 'Value', 1);
end


%% append all handles to h
h = [h hLeg hBars hCheck];


return
