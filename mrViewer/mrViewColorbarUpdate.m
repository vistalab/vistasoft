function ui = mrViewColorbarUpdate(ui, whichOverlays);
% Update colorbars on a mrViewer UI.
%
% ui = mrViewColorbarUpdate(ui, [whichOverlays=all overlays]);
%
% The optional 'o' argument can provide the index in the overlays
% to update. By default it will update the colorbar for all overlays.
%
%
% ras, 12/2006.
if ~exist('ui', 'var') | isempty(ui), ui = mrViewGet; end
if ~exist('whichOverlays', 'var') | isempty(whichOverlays),
    whichOverlays = 1:length(ui.overlays);
end

for o = whichOverlays
    % get legend text (msg)
    m = ui.overlays(o).mapNum;      
    if isequal(ui.maps(m).name, ui.maps(m).dataUnits) | ...
            isempty(ui.maps(m).dataUnits)
        msg = ui.maps(m).name;      % avoid redundant text
    else
        msg = sprintf('%s   [%s]', ui.maps(m).name, ui.maps(m).dataUnits);
    end
    msg(msg=='_') = '-';
    ui.overlays(o).cbar.label = msg;
    
    % draw color bar image, make axes nice
    h = cbarDraw(ui.overlays(o).cbar, ui.overlays(o).cbarAxes);
    set(ui.overlays(o).cbarAxes, 'YColor', 'w', 'XColor', 'w');
    
    % set context menu to allow user to right-click and edit
    set(h, 'UIContextMenu', ui.overlays(o).contextMenu);

    % adjust axes to nicely fit either linear color bar or color wheel
    % (TO DO: accomodate vertical color bars)
    if ui.overlays(o).cbar.colorWheel==1    % make axes a bit larger
        set(ui.overlays(o).cbarAxes, 'Position', [.25 .2 .5 .5]);              
    else                                    % set to default size
        set(ui.overlays(o).cbarAxes, 'Position', [.15 .7 .7 .25]);
        delete( findobj('Tag', 'colorWheelText') )
        
    end        
    
end

return