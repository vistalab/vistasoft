function RevertEdit(topH)

% mrSESSION = RevertEdit(topH);
%
% Returns all the editable fields in the dialog to their original values,
% and reverts the session and directory structures.
%
% DBR 4/99

% Revert the session structures:
uiData = get(topH, 'UserData');
mrSESSION = uiData.original;
uiData.session = mrSESSION;
set(topH, 'UserData', uiData);

% Revert the top-level dialog fields
nTop = length(uiData.topData);
for iField=1:nTop
  editFlag = uiData.topData(iField).edit;
  if editFlag
    evalStr = ['mrSESSION.', uiData.topData(iField).field];
    set(uiData.topData(iField).handle, 'string', mat2str(eval(evalStr)));
  end
end

% Revert the scan-level dialog fields
iScan = uiData.iScan;
nScan = length(uiData.scanData);
for iField=1:nScan
  editFlag = uiData.scanData(iField).edit;
  if editFlag
    evalStr = ['mrSESSION.functionals(iScan).', uiData.scanData(iField).field];
    set(uiData.scanData(iField).handle, 'string', mat2str(eval(evalStr)));
  end
end
