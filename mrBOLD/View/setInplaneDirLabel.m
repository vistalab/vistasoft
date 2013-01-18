function view = setInplaneDirLabel(view,flag,textSize);
%
% view = setInplaneDirLabel(view,[flag],[textSize]);
%
% Allows the user to set the value of the direction
% text for an inplane view.
%
% Possible values for the flag are:
% 0 -- don't show this text
% 1 -- indicate L/R direction
% 2 -- indicate A/P direction
% 
% If flag is omitted, a dialog gets it.
%
% ras, 05/06/05.
if ieNotDefined('view')
    view = getSelectedInplane;
end

if ieNotDefined('flag')
    % dialog
    ui(1).string = 'Show direction label?';
    ui(1).list = {'Don''t show','Indicate Left/Right','Indicate Ant/Pos'};
    ui(1).style = 'popup';
    ui(1).fieldName = 'flag';
    ui(1).value = 1;
    
    ui(2).string = 'Text Size?';
    ui(2).list = {'10' '12' '14' '16'};
    ui(2).style = 'popup';
    ui(2).fieldName = 'textSize';
    ui(2).value = '14';
    
    resp = generalDialog(ui,'Label Direction On Inplane');
    
    flag = cellfind(ui(1).list,resp.flag)-1;
    textSize = str2num(resp.textSize);
end

if ieNotDefined('textSize')
    textSize = 14;
end

delete(get(view.ui.dirLabel.axisHandle,'Children'));
% if ishandle(view.ui.dirLabel.textHandle)
%     delete(view.ui.dirLabel.textHandle);
% end

switch flag
    case 0, return;
    case 1, dirText = view.ui.dirLabel.textRL;
    case 2, dirText = view.ui.dirLabel.textAP;
end

% put up the label
axes(view.ui.dirLabel.axisHandle);
AX = axis;
h = text(AX(1)+(AX(2)-AX(1))/2,.4,dirText);
set(h,'FontSize',textSize,'FontName','Helvetica',...
    'HorizontalAlignment','center');

view.ui.dirLabel.textLabel = h;

return
