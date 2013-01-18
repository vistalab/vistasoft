function rx = rxDeleteSettings(rx);
%
% rx = rxDeleteSettings(rx);
%
% Delete a saved settings from the 
% stored settings list. (Gets the
% index from the ui controls).
%
% ras 03/05.
cfig = findobj('Tag','rxControlFig');

if ieNotDefined('rx')
    rx = get(cfig,'UserData');
end

selected = get(rx.ui.storedList,'Value') - 1;

if selected > 0
    N = length(rx.settings);
    remaining = setdiff(1:N,selected);
    rx.settings = rx.settings(remaining);
else
    return
end

if N==1
    newStr = {'(Default)'};
else
    newNames = {rx.settings.name};
    newStr = {'(Default)' newNames{:}};
end

set(rx.ui.storedList,'String',newStr,'Value',selected);
set(cfig,'UserData',rx);

return