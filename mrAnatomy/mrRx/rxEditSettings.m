function rx = rxEditSettings(rx);
%
% rx = rxEditSettings(rx);
%
% Edit the name of the selected, stored
% settings
%
% ras 03/05.
cfig = findobj('Tag','rxControlFig');

if ieNotDefined('rx')
    rx = get(cfig,'UserData');
end

selected = get(rx.ui.storedList,'Value') - 1;

if selected > 0
    oldName = rx.settings(selected).name;
    newName = inputdlg({'New Name:'},'Rename Setting...',1,{oldName});
    newName = newName{1};
    rx.settings(selected).name = newName;
end
    
names = {rx.settings.name};
newStr = {'(Default)' names{:}};

set(rx.ui.storedList,'String',newStr);
set(cfig,'UserData',rx);

return