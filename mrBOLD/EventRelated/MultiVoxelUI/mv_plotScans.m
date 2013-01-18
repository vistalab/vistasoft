function mv_plotScans(view,groupFlag);
% mv_plotScans(view,[groupFlag]);
%
% Shell/dialog for calling multi voxel UI for multiple scans.
%
% The idea here is to concatenate similar scans together and view the
% concatenated time course (mainly event-related or non-AB block designs,
% but can also be used if you have many cyclic scans and want to see all
% the cycles w/o averaging). If the scans have parfiles assigned, ras_tc will
% concatenate them together also.
%
% groupFlag, if passed as 1, rather than prompting for the scans to plot
% the code will look for a 'scanGroup' field in the dataTYPES.scanParams
% struct, which specifies which scans to use. If it can't find it, it
% will create it calling er_groupScans.
%
% For simplicity, assumes the data will be from the currently-selected ROI.
%
% 04/12/05 ras: adapted from tc_plotScans.
global dataTYPES HOMEDIR;

if nargin < 1
    help mv_plotScans;
    return
end

if ~exist('groupFlag','var')
    groupFlag = 0;
end

cdt = view.curDataType;

if groupFlag==1     % use pre-assigned group of scans
	[scans,dt] = er_getScanGroup(view);
else
    [scans ok] = er_selectScans(view,'View voxel data from which scans?');
    if ~ok  return;  end
    dt = cdt; % data type is current data type
end

view.curDataType = dt;

multiVoxelUI(view,[],scans);

view.curDataType = cdt; % switch back to orig. data type

return

