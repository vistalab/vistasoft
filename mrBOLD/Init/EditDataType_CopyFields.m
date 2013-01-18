function EditDataType_CopyFields(topH);
%
% For the Edit Data Type dialog, copy fields to user-selected scans.
%
% EditDataType_CopyFields(topH);
%
%
% ras, 02/06.
% ras, 07/06: streamlined and simplified.

% Unpack the user data from the edit figure
uiData = get(topH, 'UserData');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% have the user select the target scans %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
scanList = {uiData.dataType.scanParams.annotation};
for i=1:length(scanList)
    scanList{i} = sprintf('Scan %i: %s', i, scanList{i});
end
title = 'Copy Current Params to which scans?';
[tgtScans, ok] = listdlg('PromptString', title,...
    'ListSize', [300 400], 'ListString',scanList, ...
    'InitialValue', 1 ,'OKString', 'OK');
if ~ok, return; end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% copy over the fields, one by one %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
% Scan Params Fields
nFields = length(uiData.scanData); % Number of scan edit fields
for iField=1:nFields
    editFlag = uiData.scanData(iField).edit;
    if editFlag
        hContent = uiData.scanData(iField).handle;
        fName = uiData.scanData(iField).field;
        value = get(hContent, 'String');
        
        % if the value is normally numeric, run num2str
        oldVal = uiData.dataType.scanParams(tgtScans(1)).(fName);
        if isnumeric(oldVal)
            value = str2num(value);
        end

        for tgt = tgtScans
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
        oldVal = uiData.dataType.blockedAnalysisParams(tgtScans(1)).(fName);
        if isnumeric(oldVal)
            value = str2num(value);
        end

        for tgt = tgtScans
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
        oldVal = uiData.dataType.eventAnalysisParams(tgtScans(1)).(fName);
        if isnumeric(oldVal)
            value = str2num(value);
        end
        
        for tgt = tgtScans
            uiData.dataType.eventAnalysisParams(tgt).(fName) = value;
        end
    end
end

set(topH, 'UserData', uiData);


return
