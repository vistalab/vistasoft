function ui = mrViewRenderCursor(ui, ori, slice, par);
%
% ui = mrViewRenderCursor(ui, ori, slice, [parent]);
%
% Render the cursor in a mrViewer UI,
% according to the specified style and
% orientation. Will only render the cursor
% if the cursor fields point to the displayed slice
% 
% par: parent axes on which to draw the cursor.
%
% ras, 07/05.
if ~exist('ui','var') | isempty(ui), ui = mrViewGet; end
if ~exist('ori','var') | isempty(ori), return; end
if ~exist('slice','var') | isempty(slice), return; end
if ~exist('par','var') | isempty(par), par = gca; end

if abs(ui.settings.cursorLoc(ori)-slice) > 0.5
    % cursor not in this slice, within 1 voxel
    return
end
otherDims = setdiff(1:3,ori);
loc = ui.settings.cursorLoc(otherDims);

if ispref('VISTA','cursorColor')
    col = getpref('VISTA','cursorColor');
else
    col = [1 0.5 0.5];
end

% % delete old cursor objects
% delete(findobj('Tag',sprintf('%scursor',ui.tag),'Parent',par));

type = ui.settings.cursorType;

switch type
    case 1, % + sign
        ui.handles.cursor = text(loc(2),loc(1),'+','Parent',par,...
            'HorizontalAlignment','center','FontSize',14,'Color',col);
    case 2, % circle
        ui.handles.cursor = text(loc(2),loc(1),'o','Parent',par,...
            'HorizontalAlignment','center','FontSize',18,'Color',col);
    case 3, % crosshairs
        AX = axis(par);
        l(1) = line([loc(2) loc(2)],[AX(3) AX(4)],'Parent',par);
        l(2) = line([AX(1) AX(2)],[loc(1) loc(1)],'Parent',par);
        set(l,'Color',col);    
        ui.handles.cursor = l;
        
    case 4, % crosshairs + gap (BV style)
        hold(par, 'on');
        AX = axis(par);
        d = [.05 .05] .* [AX(4)-AX(3) AX(2)-AX(1)];
        l(1) = line([loc(2) loc(2)], [AX(3) loc(1)-d(1)],'Parent',par);
        l(2) = line([loc(2) loc(2)], [loc(1)+d(1) AX(4)],'Parent',par);
        l(3) = line([AX(1) loc(2)-d(2)], [loc(1) loc(1)],'Parent',par);
        l(4) = line([loc(2)+d(2) AX(2)], [loc(1) loc(1)],'Parent',par);
%         l(5) = plot(loc(2),loc(1),'.','Parent',par);
        set(l,'Color',col);  
        set(l(1:4),'LineWidth',1);
        ui.handles.cursor = l;
end

% tag the cursor objects, so we can delete them when we refresh
set(ui.handles.cursor,'Tag',sprintf('%scursor',ui.tag));

return
