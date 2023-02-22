function ShowButtons(buttonHandles)
% ShowButtons(buttonHandles)%% Makes visible all of the items in the input vector of buttonHandles.%% ress, 6/03
for i=1:length(buttonHandles)  set(buttonHandles(i), 'Visible', 'on');end