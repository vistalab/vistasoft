function vw = er_groupScans(vw,scans,assignFlag,dt)
% vw = er_groupScans(vw,[scans],[assignFlag],[datatype])
%
% Create a functional grouping of scans for future
% analyses / plotting.
%
% This is useful if you have run more than one different
% scan type in a session, and want to plot the concatenated
% tSeries from similar scans together, or apply analyses (like
% GLM) to them, without manually selecting them each time.
%
% Note that the assignment can cross data type: you can group
% a bunch of Original scans together, then assign that group
% to the average of those scans in Averages, for instance. Then
% you can e.g. look at a corAnal from the average scan, invoke
% time course UI to look at the time series from the original scans,
% and not have to switch back to the Originals data type.
%
% scans: which scans to group. default: prompt for scans.
%
% assignFlag: flag describing which scans to assign the scan
% group to. 1 -- assign to current scan; 2 -- assign
% to each scan in the group. [Default: 2]
%
% datatype: # or name of the data type in dataTYPES to which the grouped
% scans belong. If choosing the scans with a dialog, you can choose
% this as well. Otherwise, defaults to the current data type.
%
% written by ras 2004.04.07.
global dataTYPES HOMEDIR;

names = {dataTYPES.name};

cdt = vw.curDataType;


if ieNotDefined('assignFlag'),assignFlag = 2; end

% if dt hasn't already been assigned, set to current
if ieNotDefined('dt'), dt = cdt; end

% if a string specified for dt, find # of data type
if ischar(dt), dt = existDataType(dt); end

if ieNotDefined('scans')
    % get scans w/ dialog:
    
    % first choose data type
    if assignFlag==2, dt = menu('Group scans in which data type?',names);
    else              dt = vw.curDataType; end
    
    % get list of scans in this data type
    vw.curDataType = dt;
    scans = er_selectScans(vw);
    vw.curDataType = cdt;
end


switch assignFlag
    case 1, tgtScans = viewGet(vw, 'curScan');
        tgtDt = cdt;
    case 2, tgtScans = scans;
        tgtDt = dt;
    otherwise,
        error('assignFlag must be 1 or 2.');
end

% check if there's already a scanGroup field
% in dataTYPES.scanParams for the tgt data type:
for j = 1:length(dataTYPES)
    if ~isfield(dataTYPES(j).scanParams(end),'scanGroup')
        dataTYPES(j).scanParams(end).scanGroup = [];
    end
end

% assign the scans to the scanGroup field for the relevant
% scans:
grpTxt = sprintf('%s: %s',dataTYPES(dt).name,num2str(scans));
for s = tgtScans
    dataTYPES(tgtDt).scanParams(s).scanGroup = grpTxt;
end

mrSessPath = fullfile(HOMEDIR,'mrSESSION.mat');
save(mrSessPath,'dataTYPES','-append');

return
