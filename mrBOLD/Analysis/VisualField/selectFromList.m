function selectedItemList = selectFromList(listItems, title)
% selectedItemList = selectFromList(listItems, [title]);
%
%   Query the user to select an item from the list.
%
% Output:
%  selectedItemList: list of selected items.
%
% HISTORY:
%   2002.03.07 RFD (bob@white.stanford.edu) wrote it.

if ~exist('title','var')
    title = 'Choose Items';
end

selectedItemList = [];

if length(listItems) == 0
    return;
end

iSel = buttondlg(title, listItems);
selectedItemList = listItems(find(iSel));

return;
