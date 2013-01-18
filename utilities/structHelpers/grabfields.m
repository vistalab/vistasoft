function fieldsCell = grabfields(structIn,fieldName);
% grabfields(scructIn,'fieldName') will grab the named field off of
% each struct in a struct array, and return the results as a
% cell. If the cell contains character strings, it will sort the
% resulting cell alphabetically
%
%E.g., grabfields(dir,'name') will return a cell with an alphabetized list 
% of all the names in the dir struct; grabfields(dir,'bytes') will return
% the byte size of each dir entry.
%
% 2/03 by ras
if length(structIn)==0
    fieldsCell = [];
    return;
end

for i = 1:length(structIn)
    fieldsCell{i} = getfield(structIn(i),fieldName);
end

if ischar(fieldsCell{i})
    fieldsCell = sort(fieldsCell);
end

return