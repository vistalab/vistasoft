function OK = UpdateEdit(topH)
%
% OK = UpdateEdit(topH);
%
% Reads off all the editable fields in the dialog and evaluates
% them into the session structure.
%
% DBR 4/99
% DAR 1/22/07 - edited for compatibility with PC matlab 7.1

uiData = get(topH, 'UserData');
nTop = length(uiData.topData);
for iField=1:nTop
    editFlag = uiData.topData(iField).edit;
    if editFlag
        fname = uiData.topData(iField).field;
        curValue = get(uiData.topData(iField).handle,'string');
        uiData.session.(fname) = curValue;
    end
end

iScan = uiData.iScan;
nScan = length(uiData.scanData);
for iField=1:nScan
    editFlag = uiData.scanData(iField).edit;
    if editFlag
        hContent = uiData.scanData(iField).handle;
        fName = uiData.scanData(iField).field;
        curValue = get(hContent,'string');
        oldValue = uiData.session.functionals(iScan).(fName);

        if isnumeric(oldValue), curValue = str2num(curValue); end %#ok<ST2NM>

        % Check the editable fields for consistency and correct
        % if necessary:
        switch fName
            case 'junkFirstFrames'
                curValue = round(abs(curValue)); % Force positive integer input
                totalFrames = uiData.session.functionals(iScan).totalFrames;
                if curValue >= totalFrames
                    curValue = totalFrames - 1;
                end
                uiData.session.functionals(iScan).nFrames = totalFrames - curValue;
            case 'nFrames'
                curValue = round(abs(curValue)); % Force positive integer input
                availFrames = uiData.session.functionals(iScan).totalFrames - ...
                    uiData.session.functionals(iScan).junkFirstFrames;
                if curValue > availFrames
                    curValue = availFrames;
                end
            case 'slices'
                curValue = unique(round(abs(curValue))); % Force positive integer input
                nInplaneSlices = uiData.session.inplanes.nSlices;
                nSlices = uiData.session.functionals(iScan).reconParams.slquant;
                iOK = find(curValue >= 1 & curValue <= nInplaneSlices);
                if isempty(iOK)
                    curValue = 1:nSlices;
                else
                    curValue = curValue(iOK);
                end
                curValue = curValue(1:length(iOK));
        end
        set(hContent, 'string', num2str(curValue));
        uiData.session.functionals(iScan).(fName) = curValue;
    end
end
set(topH, 'UserData', uiData);
OK=1;
return