function DupEditDataType(topH)
% DupEditDataType(topH)
%
% Duplicate all the editable field contents in the present scan
% forward into all subsequent session fields. Input topH is the
% handle of the top-level edit figure.
%
% DBR 4/99
% ras 07/06: streamlined and simplified. This is very hard to debug.

% Unpack the user data from the edit figure
uiData = get(topH, 'UserData');

srcScan = uiData.iScan; % Present scan index
nScans = length(uiData.dataType.scanParams); % Number of scans in session
if srcScan == nScans, return; end % Nothing to copy
     
% Scan Params Fields
nFields = length(uiData.scanData); % Number of scan edit fields
for iField=1:nFields
    editFlag = uiData.scanData(iField).edit;
    if editFlag
        hContent = uiData.scanData(iField).handle;
        fName = uiData.scanData(iField).field;
        value = get(hContent, 'String');
        
        % if the value is normally numeric, run num2str
        oldVal = uiData.dataType.scanParams(srcScan).(fName);
        if isnumeric(oldVal)
            value = str2num(value);
        end

        for tgt = srcScan:nScans
            uiData.dataType.scanParams(tgt).(fName) = value;
        end
    end
end

% Blocked (Traveling-Wave) Params Fields
nFields = length(uiData.blockData); % Number of scan edit fields
for iField=1:nFields
    editFlag = uiData.blockData(iField).edit;
    if editFlag
        hContent = uiData.blockData(iField).handle;
        fName = uiData.blockData(iField).field;
        value = get(hContent, 'String');

        % if the value is normally numeric, run num2str
        oldVal = uiData.dataType.blockedAnalysisParams(srcScan).(fName);
        if isnumeric(oldVal)
            value = str2num(value);
        end

        for tgt = srcScan:nScans
            uiData.dataType.blockedAnalysisParams(tgt).(fName) = value;
        end
    end
end

% Scan Params Fields
nFields = length(uiData.eventData); % Number of scan edit fields
for iField=1:nFields
    editFlag = uiData.eventData(iField).edit;
    if editFlag
        hContent = uiData.eventData(iField).handle;
        fName = uiData.eventData(iField).field;
        value = get(hContent, 'String');

        % if the value is normally numeric, run num2str
        oldVal = uiData.dataType.eventAnalysisParams(srcScan).(fName);
        if isnumeric(oldVal)
            value = str2num(value);
        end
        
        for tgt = srcScan:nScans
            uiData.dataType.eventAnalysisParams(tgt).(fName) = value;
        end
    end
end

set(topH, 'UserData', uiData);


return
