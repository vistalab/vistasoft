function cbarImg = cbarCopy(vw, destination)
% Copy the colorbar in a mrVista view to a figure or the clipboard
%
%  cbarImg = cbarCopy(vw, [destination='figure']);
%
% vw: mrVista view structure.
%
% destination: can be one of 'clipboard' or 'figure'.
%
% ras, 07/2007.
if notDefined('vw'),			vw = getCurView;		end
if notDefined('destination'),	destination = 'figure';		end

% get the handle for the view's colorbar
if ~checkfields(vw, 'ui', 'colorbarHandle')
	error('No Colorbar exists for this view.')
end
h = vw.ui.colorbarHandle;

% using this handle, get the colorbar image
hCbarImg = findobj('Type', 'Image', 'Parent', h);
cbarImg = get(hCbarImg, 'CData');


% create the figure
hFig = figure('Color', 'w');
hCbar = subplot('Position', [.2 .15 .7 .12]);
x = get(hCbarImg, 'XData'); y = get(hCbarImg, 'YData');

imagesc([x(1) x(end)], [y(1) y(end)], cbarImg, 'Parent', hCbar);

set(hCbar, 'Box', 'off', 'Visible', get(h, 'Visible'), ...
    'XTick', get(h, 'XTick'), 'YTick', get(h, 'YTick'), ...
    'XTickLabel', get(h, 'XTickLabel'), ...
    'YTickLabel', get(h, 'YTickLabel'), ...
    'DataAspectRatio', get(h, 'DataAspectRatio'), ...
    'DataAspectRatioMode', get(h, 'DataAspectRatioMode'), ...
    'PlotBoxAspectRatio', get(h, 'PlotBoxAspectRatio'), ...
    'PlotBoxAspectRatioMode', get(h, 'PlotBoxAspectRatioMode'));
ttl = get(h, 'Title');
if ishandle(ttl) % a title or xlabel exists, reproduce it
    uicontrol('Style', 'text', 'String', get(ttl, 'String'), ...
			  'BackgroundColor', 'w', 'FontSize', 12, ...
              'Units', 'norm', 'Position', [.3 .7 .4 .3]);
end

% get the colormap from the view, set in new figure
nG = viewGet(vw, 'ngrays');
cmap = viewGet(vw, 'cmap');
colormap(cmap(nG+1:end,:));

% if copying to clipboard, copy and close the figure
if isequal( lower(destination), 'clipboard' )
    if isa(hFig, 'matlab.ui.Figure'), fignum = get(hFig, 'Number');
    else fignum = hFig; end
	print( sprintf('-f%i', fignum), '-dmeta' )
	close(hFig);
end

return
