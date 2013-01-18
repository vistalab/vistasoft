function tc_plotScans(view, groupFlag, queryFlag);
% tc_plotScans(view, [groupFlag], [queryFlag=1]);
%
% Shell/dialog for calling rory's time course viewer (ras_tc) for multiple scans.
%
% The idea here is to concatenate similar scans together and view the
% concatenated time course (mainly event-related or non-AB block designs,
% but can also be used if you have many cyclic scans and want to see all
% the cycles w/o averaging). If the scans have parfiles assigned, ras_tc will
% concatenate them together also.
%
% groupFlag: if passed as 1, rather than prompting for the scans to plot
% the code will look for a 'scanGroup' field in the dataTYPES.scanParams
% struct, which specifies which scans to use. If 2, will launch a TCUI for
% the current scan. If groupFlag is 0 or omitted it
% will create it calling er_groupScans. [default 0:select scans]
%
% For simplicity, assumes the data will be from the currently-selected ROI.
%
% 02/18/04 ras: wrote it.
% 04/07/04 ras: added option to plot scans in pre-assigned group.
% (see also er_groupScans)
% 04/04/07 ras: added groupFlag==2 option, queryFlag, 
% checks for 'GLMs' data type
global dataTYPES;

if nargin < 1
    help tc_plotScans;
end

if notDefined('groupFlag'),    groupFlag = 0;		end
if notDefined('queryFlag'),    queryFlag = 1;		end

cdt = view.curDataType;

%% special case:
% check if we're in the GLMs data type; if so, we need to
% use groupFlag==1. If this is not the case, clarify w/ the
% user:
if isequal(dataTYPES(cdt).name, 'GLMs') 
	if groupFlag ~= 1
		q = ['You''re in the GLMs data type. You can only plot ' ...
			 'a time course for the assigned scan group (there ' ...
			 'are not saved time series for this scan). Is this ' ...
			 'what you''d like to do?'];
		 resp = questdlg(q, mfilename);

		 if isequal(resp, 'Yes')
			 groupFlag = 1;

		 else
			 disp('TCUI aborted.')
			 return

		 end
	end
	
	queryFlag = 0; % don't bother folks with this every time.
end		 

if groupFlag==1     % use pre-assigned group of scans
	[scans,dt] = er_getScanGroup(view);
elseif groupFlag==2		% current scan
	dt = cdt;
	scans = view.curScan;
else
    [scans ok] = er_selectScans(view,'View time course from which scans?');
    if ~ok  return;  end
    dt = cdt; % data type is current data type
end

timeCourseUI(view,[ ], scans, dt, queryFlag);

return

