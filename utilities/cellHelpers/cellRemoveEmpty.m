function c = cellRemoveEmpty(inCell)
%Remove empty entries from a cell array
%
%   c = cellRemoveEmpty(inCell)
%
% GB/BW
% See removeListElement for another way to do this.
%

if isempty(inCell), c = {}; return; end
n = length(inCell);
emptyList = [];
for ii=1:n
    if isempty(inCell{ii}), emptyList = [emptyList,ii]; end
end
if isempty(emptyList), c = inCell; return; end
c = {};
for ii=setdiff(1:n,emptyList)
    c{end+1} = inCell{ii};
end
return;
