function tc = tc_init(view, roi, scans, dt, queryFlag);
% tc = tc_init(view, roi, scans, dt, [queryFlag=1]);
%
% Initialize a time course UI struct from a mrVista view.
%
% roi: name or # of ROI in the view.ROIs substruct. 
%
% scans: scans for which to get the time course.
%
% dt: data type from whicht o get the time course
%
% ras,  broken off from tc_openFig,  04/06/05.
% ras,  09/22/05,  removed the settings field; all the
% relevant info should be in the params field instead.
global dataTYPES mrSESSION;
if notDefined('view'),    view = getCurView;                end
if notDefined('roi'),     roi = viewGet(view, 'curRoi');    end
if notDefined('dt'),     dt = viewGet(view, 'curDataType'); end
if notDefined('queryFlag'), queryFlag = 1;					end

if notDefined('scans')
    [scans dt] = er_getScanGroup(view);
    view = selectDataType(view, dt);
	view.curScan = scans(1);
end

% get prefs
if ispref('VISTA', 'recomputeVoxData') 
    recomputeFlag = getpref('VISTA', 'recomputeVoxData');
else
    recomputeFlag = 0;
end

% get roi substruct 
roi = tc_roiStruct(view, roi);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check if data are from a different data type
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ischar(dt)
    % convert dt name -> index #
    mrGlobals;
    dt = existDataType(dt, dataTYPES, 1);
end

if ~isequal(dt, view.curDataType) & queryFlag==1
    names = {dataTYPES.name};
    msg = sprintf('The selected scans are: \n %s %s\n', ...
            names{dt}, num2str(scans));
    msg = [msg 'This is in a different data type. '];
    msg = [msg 'Do you want to analyze this data? '];
    resp = questdlg(msg, 'Time Course UI', 'Yes', 'No', 'No');
    if ~isequal(resp, 'Yes')
        error('TC UI init aborted.')
    end
end

% get the parameters before setting the view's data type: 
% so, if you're in the GLMs data type, you get the SAVED params, not the
% CURRENT params
params = er_getParams(view);

% this temporarily changes the data type w/o affecting the GUI
% (since the modified view is not returned)
view.curDataType = dt;  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check if parfiles are assigned (if ABAB block design or cyclic,  make 'em)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
status = tc_parfilesCheck(view, scans);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load the data from scans,  parfiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% tc = er_chopTSeries(view, roi.coords, scans, 'mrvWaitbar');

% alternate way: use voxelData function,  then avg 
% across voxels.
% b/c this saves/loads ROI tSeries,  it may be much
% faster in many circumstances
data = er_voxelData(view, roi, scans, recomputeFlag, 0);
tc.wholeTc = nanmeanDims(data.tSeries, 2);
tc = er_chopTSeries2(tc.wholeTc, data.trials, data.params);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialize additional fields in tc struct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tc.TR = dataTYPES(dt).scanParams(scans(1)).framePeriod;
tc.plotType = 7;

% add params
tc.params = params;
tc.params.dataType = dataTYPES(dt).name;
tc.params.scans = scans;
tc.params.viewName = view.name;
tc.params.sessionCode = mrSESSION.sessionCode;
tc.params.description = mrSESSION.description; %remus 10/07, used in plots.
tc.params.legend = 1;
tc.params.showPkBsl = 1;
tc.params.markEachTrial = 0; % color setting for all trials plot
tc.params.grid = 0; % show grid
tc.params.axisBounds = []; 
tc.params.parfiles = {dataTYPES(dt).scanParams(scans).parfile};

tc.trials = er_concatParfiles(view, scans);
nConds = length(tc.condNums);

% check if we're in a deconvolved data type
curdt = viewGet(view, 'curDataType');
dtName = dataTYPES(curdt).name;
if isequal(dtName, 'Deconvolved')
    % fix to be compatible with deconvolved format
    tc = tc_deconvolvedTcs(view, tc);
end

tc.roi = roi;

return
