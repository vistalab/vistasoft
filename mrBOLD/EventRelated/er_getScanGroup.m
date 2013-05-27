function [scans,dt] = er_getScanGroup(vw,scan)
% [scans,dt] = er_getScanGroup(view,scan);
%
% Gets the group of scans assigned as a group to the
% current scan; if no group of scans is assigned, prompts
% to assign it. 
%
% See: er_groupScans.
%
% ras 04/07/04: wrote it.
global dataTYPES;

cdt = vw.curDataType;

if ieNotDefined('scan')
    scan = viewGet(vw, 'curScan');
end
    
% check if there's a scan group assigned to this scan
if ~isfield(dataTYPES(cdt).scanParams(scan),'scanGroup') || ...
        isempty(dataTYPES(cdt).scanParams(scan).scanGroup)
    er_groupScans(vw);
end

% parse the groupScans text into a data type series
% and a set of scans (e.g. 'Original: 1 2 3'):
txt = dataTYPES(cdt).scanParams(scan).scanGroup;
%colon = findstr(':',txt); %findstr is obsolete, using strfind instead
colon = strfind(txt,':');
dtName = txt(1:colon-1);
scans = str2num(txt(colon+2:end));
dt = cellfind({dataTYPES.name}, dtName);

return
