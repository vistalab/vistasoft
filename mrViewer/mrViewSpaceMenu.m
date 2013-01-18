function ui = mrViewSpaceMenu(ui);
%
% ui = mrViewSpaceMenu(ui);
%
% Attach a menu to a mrViewer UI for switching
% between spaces (coordinate systems) defined
% by the mr object. This should allow easy switching
% between e.g. pixel space and ac/pc or scanner coordinates,
% as well as doing simple things like flipping L/R or into
% radiological coords.
%
% ras 07/08/05.
if ~exist('ui','var') | isempty(ui), ui = get(gcf,'UserData'); end

ui.menus.space = uimenu(ui.fig,'Label','Coordinates');

ui.spaces = ui.mr.spaces;

for i = 1:length(ui.spaces)
    cb = sprintf('mrViewSet([],''Space'',%i); mrViewRefresh;',i);
    h = uimenu(ui.menus.space,'Label',ui.spaces(i).name,...
           'Callback',cb);
    ui.spaces(i).menuHandle = h;
end

set(ui.spaces(1).menuHandle,'Checked','on');

return