function cellOut = unNestCell(cellIn);
% cellOut = unNestCell(cellIn):
% 
% takes a cell which may have sub-cells as entries, and 'flattens out' the
% subentries. The output cell has no sub-cells: instead, wherever the cell
% entry would be, several entries are added containing the contents of that
% cell. Works recursively. Only works on cell arrays right now (not
% matrices of cells).
%
% 11/07/03 ras.
if nargin==0 | ~iscell(cellIn);
    help unNestCell;
    return;
end

cellOut = {};

for i = 1:length(cellIn)
    if iscell(cellIn{i})
        expand = unNestCell(cellIn{i});
        cellOut = {cellOut{1:end} expand{1:end}};
    else
        cellOut = {cellOut{1:end} cellIn{i}};
    end
end

return