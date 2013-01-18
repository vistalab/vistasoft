function IncEditDataType(topH, inc)

% function IncEditDataType(topH, inc);
%
% Update the dataType structure with the present information, then
% increment the scan index by the specified amount [inc] from its
% present value. Load the scan content fields that correspond to
% the new index. Input topH is the handle id of the top-level
% edit figure.
%
% DBR 4/99

UpdateEditDataType(topH);

% Increment the present contents of the scan-index field:
uiData = get(topH, 'UserData');
iScan = inc + round(str2num(get(uiData.hScan, 'string')));
nScans = length(uiData.dataType.scanParams);
if iScan > nScans
    iScan = nScans;
end
if iScan < 1
    iScan = 1;
end
set(uiData.hScan, 'string', int2str(iScan));
uiData.iScan = iScan;
set(topH, 'UserData', uiData);

% Load the fields based on the new scan index and
% the present contents of the dataType structure.
nFields = length(uiData.scanData);
for iField=1:nFields
    fieldName = uiData.scanData(iField).field;
    val = uiData.dataType.scanParams(iScan).(fieldName);
    set(uiData.scanData(iField).handle, 'string', num2str(val));
end

nFields = length(uiData.blockData);
for iField=1:nFields
    fieldName = uiData.blockData(iField).field;
    val = uiData.dataType.blockedAnalysisParams(iScan).(fieldName);
    set(uiData.blockData(iField).handle, 'string', num2str(val));
end

nFields = length(uiData.eventData);
for iField=1:nFields
    fieldName = uiData.eventData(iField).field;
    val = uiData.dataType.eventAnalysisParams(iScan).(fieldName);
    set(uiData.eventData(iField).handle, 'string', num2str(val));
end

set(topH, 'UserData', uiData);

return
