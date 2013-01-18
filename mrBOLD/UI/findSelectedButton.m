function buttonNum=findSelectedButton(buttonHandles)
%
% buttonNum=findSelectedButton(buttonHandles)
%
% Loops through buttonHandles, returns the first one whose Value
% is 1.
%
% djh, 1/16/97
% ras, 07/05, imported into mrVista 2.0
for buttonNum=1:length(buttonHandles)
    val = get(buttonHandles(buttonNum),'Value');
    if val, return; end
end

% if we get here, something's wrong, probably
disp('findSelectedButton: no button selected!')
buttonNum = [];
return
