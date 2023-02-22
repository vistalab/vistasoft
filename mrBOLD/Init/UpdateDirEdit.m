function OK = UpdateEdit(topH)

% OK = UpdateEdit(topH);
%
% Reads off all the editable fields in the directory-edit dialog and 
% evaluate them into the directory structure.
%
% DBR 6/99


uiData = get(topH, 'UserData');
nDir = length(uiData.dirData);
ok = [];
for iField=1:nDir
  editFlag = uiData.dirData(iField).edit;
  if editFlag
    fName = uiData.dirData(iField).field;
    curDir = eval(['uiData.dirS.', fName]);
    hContent = uiData.dirData(iField).handle;
    newDir = get(hContent, 'string');
    ok1 = exist(newDir, 'dir');
    if ok1
      eval(['uiData.dirS.', fName, ' = newDir;']);
    else
      label = uiData.dirData(iField).label;
      alertStr = ['Could not find "', label, '" directory: ', newDir];
      Alert(alertStr);
      set(hContent, 'string', curDir);
    end
    ok = [ok, ok1];
  end
end

set(topH, 'UserData', uiData);
if nDir > 0
  OK = all(ok);
else
  OK = 1;
end
