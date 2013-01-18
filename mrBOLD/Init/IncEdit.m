function IncEdit(topH, inc)

% function IncEdit(topH, inc);
%
% Update the session structure with the present information, then
% increment the scan index by the specified amount [inc] from its
% present value. Load the scan content fields that correspond to
% the new index. Input topH is the handle id of the top-level
% edit figure.
%
% DBR 4/99
% DAR 1/22/07 - edited for compatibility with PC matlab 7.1

UpdateEdit(topH);

% Increment the present contents of the scan-index field:
uiData = get(topH, 'UserData');
iScan = inc + round(str2num(get(uiData.hScan, 'string')));
nScans = length(uiData.session.functionals);
if iScan > nScans
    iScan = nScans;
end
if iScan < 1
    iScan = 1;
end
set(uiData.hScan, 'string', num2str(iScan));
uiData.iScan = iScan;
set(topH, 'UserData', uiData);

% Load the scan-content fields based on the new scan index and
% the present contents of the session structure.
nScan = length(uiData.scanData);
for iField=1:nScan
    oldValue = uiData.session.functionals(iScan).(uiData.scanData(iField).field);
    set(uiData.scanData(iField).handle, 'string', num2str(oldValue));
end
