function DupEdit(topH)

% DupEdit(topH)
%
% Duplicate all the editable field contents in the present scan
% forward into all subsequent session fields. Input topH is the
% handle of the top-level edit figure.
%
% DBR 4/99
% DAR 1/22/07 - edited for compatibility with PC matlab 7.1


% Unpack the user data from the edit figure
uiData = get(topH, 'UserData');

iS = uiData.iScan; % Present scan index
nScans = length(uiData.session.functionals); % Number of scans in session

if iS == nScans, return; end % Nothing to copy
nFields = length(uiData.scanData); % Number of scan edit fields
for iScan=iS+1:nScans
    for iField=1:nFields
        editFlag = uiData.scanData(iField).edit;
        if editFlag
            hContent = uiData.scanData(iField).handle;
            fName = uiData.scanData(iField).field;
            origValue = uiData.original.functionals(iScan).(fName);
            curValue = get(hContent,'string');
            if isnumeric(origValue)
                curValue = str2num(curValue);
            end

            label = uiData.scanData(iField).label;
            uiData.session.functionals(iScan).(fName) = curValue;
        end
    end
end
set(topH, 'UserData', uiData);