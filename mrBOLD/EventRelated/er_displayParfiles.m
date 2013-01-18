function msg = er_displayParfiles(view);
%
% msg = er_displayParfiles(view);
%
% Pop up a message box with the scan group currently assigned
% to the present scan (if any), and the parfiles for each 
% scan in the group. Returns the message text.
%
%
% ras, 02/06.
if notDefined('view'), view = getSelectedInplane;   end

mrGlobals;

dt = view.curDataType; 
scan = view.curScan;
dtName = dataTYPES(dt).name;

if ~isfield(dataTYPES(dt).scanParams(scan), 'scanGroup') | ...
        ~isfield(dataTYPES(dt).scanParams(scan), 'parfile')
    msg = 'Parfiles and/or scan group not assigned for this scan.';
    myWarnDlg(msg);
    return
end

if ~isempty(dataTYPES(dt).scanParams(scan).scanGroup)
    [scans dt] = er_getScanGroup(view);
    scanGroup = sprintf('%s scans %s', dataTYPES(dt).name, num2str(scans));
else
    % just use cur scan / dt
    scans = scan;
    scanGroup = 'none';
end


msg = [sprintf('%s %s scan %i \n', view.name, dtName, scan) ...
       sprintf('Scan Group: %s \n\n', scanGroup) ...
       sprintf('Parfiles: \n')];
for s = scans
    msg = [msg sprintf('%i: %s \n', s, dataTYPES(dt).scanParams(s).parfile)]; 
end
       
msgbox(msg, 'Event-Related Info');

return

