function RevertDirEdit(topH)

% dirS = RevertDirEdit(topH);
%
% Returns all the editable fields in the dialog to their original values,
% and reverts the directory structure.
%
% DBR 6/99

% Revert the session and directory structures:
uiData = get(topH, 'UserData');
dirS = uiData.origDirS;
uiData.dirS = dirS;
set(topH, 'UserData', uiData)

% Revert the directory dialog fields
nDir = length(uiData.dirData);
for iField=1:nDir
  editFlag = uiData.dirData(iField).edit;
  if editFlag
    evalStr = ['dirS.', uiData.dirData(iField).field];
    set(uiData.dirData(iField).handle, 'string', mat2str(eval(evalStr)));
  end
end
