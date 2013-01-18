function mv = mv_init(view, roi, scans, dt, preserveCoords);
% mv = mv_init(view, <roi>, <scans>, <dt>, <preserveCoords>);
%
% Initialize a time course UI struct from a mrVista view.
%
% roi: name or # of ROI in the view.ROIs substruct. 
%
% ras,  broken off from tc_openFig,  04/06/05.
global dataTYPES mrSESSION;

if notDefined('view'),    view = getCurView;                    end
if notDefined('roi'),     roi = viewGet(view, 'curRoi');        end
if notDefined('dt'),      dt = view.curDataType;				end
if notDefined('scans'),   [scans dt] = er_getScanGroup(view);	end
if notDefined('preserveCoords'),   preserveCoords = 0;			end

% get prefs
if ispref('VISTA', 'recomputeVoxData') 
    recomputeFlag = getpref('VISTA', 'recomputeVoxData');
else
    recomputeFlag = 0;
end

tic

% get roi substruct 
roi = tc_roiStruct(view, roi);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set to proper data type
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ischar(dt)
    % convert dt name -> index #
    mrGlobals;
    dt = existDataType(dt, dataTYPES, 1);
end

if ~isequal(dt, viewGet(view, 'curdt'))
    curDt = viewGet(view, 'curdt');
    view = selectDataType(view, dt);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check if parfiles are assigned (if ABAB block design or cyclic,  make 'em)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
status = tc_parfilesCheck(view, scans);
if status==0
    fprintf('mv_init aborted. No parfiles assigned.\n');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load the data from scans,  parfiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mv = er_voxelData(view, roi, scans, recomputeFlag, preserveCoords);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialize additional fields in mv struct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mv.params.sessionCode = mrSESSION.sessionCode;
mv.params.dataType = dataTYPES(dt).name;
mv.params.scans = scans;
mv.params.roiName = roi.name;
if ~isfield(mv.params,  'ampType')
    mv.params.ampType = 'betas';
end

mv.roi = roi;

%%
% Create two separate coordinate fields - coordsAnatomy and coordsInplane
% coordsAnatomy - those corresponding to rois seen in mrVista windows
% coordsInplane - those corresponding to inplane parameter maps in mrVista
%%%

roiCoords = mv.coords;
rsFactor = upSampleFactor(view);
if length(rsFactor)==1
    roiCoords(1:2,:) = round(roiCoords(1:2,:)/rsFactor(1));
else
    roiCoords(1,:) = round(roiCoords(1,:)/rsFactor(1));
    roiCoords(2,:) = round(roiCoords(2,:)/rsFactor(2));
end

mv.coordsAnatomy    = mv.coords;
mv.coordsInplane    = roiCoords;
%%

mv.params.parfiles = {dataTYPES(dt).scanParams(scans).parfile};
nConds = length(unique(mv.trials.cond));

% display legend pref
mv.params.legend = 0;

% prefs for plotting graphs,  images
mv.params.cmap = jet(256);
mv.params.font = 'Helvetica';
mv.params.fontsz = 12;

% default plot type: mean amps sparklines
mv.ui.plotType = 3;

% check if we're in a deconvolved data type
curdt = viewGet(view, 'curDataType');
dtName = dataTYPES(curdt).name;
if isequal(dtName, 'Deconvolved')
    % fix to be compatible with deconvolved format
    mv = tc_deconvolvedTcs(view, mv);
end

% if we've had to change data type to get
% the data,  change back now:
if exist('curDt', 'var')
    view = selectDataType(view, curDt);
end

% toc

return


