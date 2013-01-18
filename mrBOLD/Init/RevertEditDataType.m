function RevertEditDataType(topH)

% RevertEditDataType(topH);
%
% Returns all the editable fields in the dialog to their original values.
%
% DBR 4/99

% Revert the session structures:
uiData = get(topH, 'UserData');
uiData.dataType = uiData.original;
set(topH, 'UserData', uiData);

iScan = uiData.iScan;
iStr = int2str(iScan);

% Revert the blockedAnalysisParams dialog fields
nFields = length(uiData.blockData);
for iField=1:nFields
    editFlag = uiData.blockData(iField).edit;
    if editFlag
        evalStr = ['uiData.dataType.blockedAnalysisParams(iScan).', uiData.blockData(iField).field];
        set(uiData.blockData(iField).handle, 'string', mat2str(eval(evalStr)));
    end
end

% Revert the eventAnalysisParams dialog fields
nFields = length(uiData.eventData);
for iField=1:nFields
    editFlag = uiData.eventData(iField).edit;
    if editFlag
        evalStr = ['uiData.dataType.eventAnalysisParams(iScan).', uiData.eventData(iField).field];
        set(uiData.eventData(iField).handle, 'string', mat2str(eval(evalStr)));
    end
end
