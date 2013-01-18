function ui = mrViewRemoveMap(ui,m);
%
% ui = mrViewRemoveMap([ui],[m]);
% 
% Close/remove an overlay from a mrViewer UI.
% m is the index into the map; if omitted
% it removes the last map.
%
% ras 07/05.
if ~exist('ui','var') | isempty(ui), ui = mrViewGet;            end
if ishandle(ui), ui = get(ui, 'UserData');                      end

if isempty(ui.maps), warning('No Maps to remove!'); return;     end

if ~exist('m','var') | isempty(m), 
    % dialog
    str = {ui.maps.name};
    [m ok] = listdlg('PromptString','Remove which map?',...
                       'SelectionMode','multiple',...
                       'ListString',str);
    if ~ok, return; end
end

% new overlay order
newInd = setdiff(1:length(ui.maps),m);

% remove the overlay field
ui.maps = ui.maps(newInd);

% if no more maps are available, and overlays
% are present, remove the overlays:
if isempty(newInd) & isfield(ui,'overlays') & ~isempty(ui.overlays)
    for o = length(ui.overlays):-1:1
        ui = mrViewRemoveOverlay(ui,o);
    end
end 

ui = mrViewRefresh(ui);

return