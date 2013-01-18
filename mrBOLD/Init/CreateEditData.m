function data = CreateEditData(fieldCells, session)
%
%  data = CreateEditData(fieldCells, session)
%
% Compare the field names in the session structure with
% those specified by fieldCells. If they match, add
% field name, label, contents, edit flat, and length to the
% output data struct array. 
%
% See GetReconEdit.m for more information. 
%
% DBR, 4/99

sessionFields = fieldnames(session);
iMatch = 0;

for iField=1:size(fieldCells, 1)
  field = fieldCells{iField, 1};

  if strmatch(field, sessionFields, 'exact')
    iMatch = iMatch + 1;
    data(iMatch).field = field;
    label = fieldCells{iField, 2};
    data(iMatch).label = label;
    fieldName = fieldCells{iField, 1}; 
    content = num2str(session.(fieldName));
    data(iMatch).content = content;
    data(iMatch).edit = fieldCells{iField, 3};
    data(iMatch).width = length(label) + length(content);
  end

end

return;
