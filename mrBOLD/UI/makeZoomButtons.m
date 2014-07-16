function vw = makeZoomButtons(vw)
% Adds buttons for zooming in/out of a view.
%
% vw = makeZoomButtons(vw);
%
% 
% 09/04 ras.
% 02/06: made callbacks just call the axis command, rather than
% refreshing the zoom -- should be much faster.

name = viewGet(vw,'Name');
type = viewGet(vw,'View Type');
dims = viewGet(vw,'Size');

switch type
    case {'Inplane', 'Flat'},
		cb1 = sprintf('%s = zoomInplane(%s);', viewGet(vw,'Name'), viewGet(vw,'Name'));
		cb2 = sprintf('%s = zoomInplane(%s, 1);', viewGet(vw,'Name'), viewGet(vw,'Name'));                     
                     
    case {'Volume', 'Gray','generalGray'},        
		cb1 = sprintf('%s = zoom3view(%s);', viewGet(vw,'Name'), viewGet(vw,'Name'));
		cb2 = sprintf('%s = zoom3view(%s, 1);', viewGet(vw,'Name'), viewGet(vw,'Name'));     
        
    otherwise,
        error('Huh? Weird view type.');
end

but1 = uicontrol('Style', 'pushbutton', 'String', 'Zoom',...
             'Value', 0, 'Callback', cb1,...
             'BackgroundColor', [.6 .6 .6], ...
             'ForegroundColor', [0 0 0],...
             'Units', 'Normalized', ...
             'Position', [0 0.2 0.1 0.05]);

but2 = uicontrol('Style', 'pushbutton', ...
                 'String', 'Reset Zoom',...
                 'Value', 0, 'Callback', cb2,...
                 'BackgroundColor', [.8 .8 .8], ...
                 'ForegroundColor', [0 0 0],...
                 'Units', 'Normalized', ...
                 'Position', [0 0.15 0.1 0.05]); 

vw.ui.zoomButtons.zoom = but1;
vw.ui.zoomButtons.resetZoom = but2;

% init zoom field in view
switch type
    case {'Inplane','Flat'},
		%vw.ui.zoom = [1 max(2, dims(2)) 1 max(2, dims(1))];
        vw.ui.zoom = [1 max(1, dims(2)) 1 max(1, dims(1))];
    case {'Volume','Gray'},
        vw.ui.zoom = [1 dims(1); 1 dims(2); 1 dims(3)];
end

return