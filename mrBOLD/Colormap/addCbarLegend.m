function hPanel = addCbarLegend(vw, parent, sz)
% hPanel = addCbarLegend(vw, parent, sz);
%
% Add a uipanel below the parent figure, copying the colorbar from
% the selected view with as high fidelity as possible
%
% ras, 01/09/07.
if notDefined('vw'),	vw = getCurView;		end
if notDefined('sz'), sz = .16;					end
if notDefined('parent'), parent = gcf;			end

hPanel = mrvPanel('below', sz, parent);
set(hPanel, 'BackgroundColor', get(gcf,'Color'), 'BorderType', 'none');
  
h = vw.ui.colorbarHandle;
hcbar = axes('Parent', hPanel, 'Units', 'norm', 'Position', [.2 .3 .6 .3]);
tmpH = findobj('Type', 'Image', 'Parent', h);
cbarImg = get(tmpH, 'CData');
x = get(tmpH, 'XData'); y = get(tmpH, 'YData');

imagesc([x(1) x(end)], [y(1) y(end)], cbarImg, 'Parent', hcbar);

set(hcbar, 'Box', 'off', 'Visible', get(h, 'Visible'), ...
    'XTick', get(h, 'XTick'), 'YTick', get(h, 'YTick'), ...
    'XTickLabel', get(h, 'XTickLabel'), ...
    'YTickLabel', get(h, 'YTickLabel'), ...
    'DataAspectRatio', get(h, 'DataAspectRatio'), ...
    'DataAspectRatioMode', get(h, 'DataAspectRatioMode'), ...
    'PlotBoxAspectRatio', get(h, 'PlotBoxAspectRatio'), ...
    'PlotBoxAspectRatioMode', get(h, 'PlotBoxAspectRatioMode'));
ttl = get(h, 'Title');
if ishandle(ttl) % a title or xlabel exists, reproduce it
    uicontrol('Parent', hPanel, 'Style', 'text', ...
              'String', get(ttl, 'String'), 'FontSize', 12, ...
              'BackgroundColor', get(hPanel, 'BackgroundColor'), ...
              'Units', 'norm', 'Position', [.3 .7 .4 .3]);
end
% params = retinoGetParams(vw);
% if ~isempty(params) & isequal(params.type, 'polar_angle')
%     set(hcbar, 'Position', [.4 .05 .2 .2]);
% end
mode = sprintf('%sMode', vw.ui.displayMode);
nG = vw.ui.(mode).numGrays;       
colormap(vw.ui.(mode).cmap(nG+1:end,:));


return
