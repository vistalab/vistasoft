function OK = UpdateEditDataType(topH)
% OK = UpdateEditDataType(topH);
%
% Reads off all the editable fields in the dialog and evaluates
% them into the dataType structure.
%
% DBR 4/99
% ras, removed a lot of old code that was creating problems, which
% involved disabling the OK check (code was too complicated to figure out
% how to keep it -- actually I also find it helpful if the editor
% is robust, and doesn't crash, even if it lets the user set a parameter
% to an unexpected value.) Also disabled the forcing of a positive integer for
% nCycles: the corAnal code no longer requires this, and it's sometimes
% useful to have non-integers.
OK = 1; 
uiData = get(topH, 'UserData');

scan = uiData.iScan;

nFields = length(uiData.scanData);
ok = [];
for iField=1:nFields
    editFlag = uiData.scanData(iField).edit;
    if editFlag
        hContent = uiData.scanData(iField).handle;
        fName = uiData.scanData(iField).field;
        curValue = get(hContent, 'String');

        % if the value is normally numeric, run num2str
        oldVal = uiData.dataType.scanParams(scan).(fName);
        if isnumeric(oldVal)
            curValue = str2num(curValue);
        end
        
        % update the UI data with this value
        uiData.dataType.scanParams(scan).(fName) = curValue;        
    end
end

nFields = length(uiData.blockData);
ok = [];
for iField=1:nFields
    editFlag = uiData.blockData(iField).edit;
    if editFlag
        hContent = uiData.blockData(iField).handle;
        fName = uiData.blockData(iField).field;
        curValue = get(hContent, 'String');
        curValue = str2num(curValue); % all these params are numeric
        
        % Check the editable fields for consistency and correct
        % if necessary:
        switch fName
            case 'blockedAnalysis'
                curValue = round(double(curValue)); % Force integer
                if (curValue < 0) | (curValue > 1)
                    curValue = 0;
                end
            case 'detrend'
                curValue = round(double(curValue)); % Force integer
                if (curValue < -1) | (curValue > 2)
                    curValue = 0;
                end
            case 'inhomoCorrect'
                curValue = round(double(curValue)); % Force integer
                if (curValue < 0) | (curValue > 3)
                    curValue = 0;
                end

            set(hContent, 'string', num2str(curValue));
        end
        
        % update the UI data with this value
        uiData.dataType.blockedAnalysisParams(scan).(fName) = curValue;        
    end
end

nFields = length(uiData.eventData);
defaults = er_defaultParams;
for iField=1:nFields
    editFlag = uiData.eventData(iField).edit;
    if editFlag
        hContent = uiData.eventData(iField).handle;
        fName = uiData.eventData(iField).field;
        curValue = get(hContent, 'String');

        % if the value is normally numeric, run num2str
        oldVal = defaults.(fName);
        if isnumeric(oldVal)
            curValue = str2num(curValue);
        end        
        
        % update the UI data with this value
        uiData.dataType.eventAnalysisParams(scan).(fName) = curValue;        
    end
end

set(topH, 'UserData', uiData);

return

