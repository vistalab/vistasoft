function tc = timeCourseUI(view, roi, scans, dt, queryFlag);
%   tc = timeCourseUI(view, [roi, scans, dt, queryFlag])
%
% timeCourseUI: user interface for displaying mrLoadRet time course data.
%
% This provides a GUI that provides a growing number of 
% analysis and plotting options. It works for event-related
% (both rapid and long event-related),  block-design,  and cyclic
% data. 
%
% The one requirement is that your mrVista session dir has a
% stim/parfiles subdirectory. This will hold paradigm (.par)
% files,  based on the same format used by Freesurfer,  which
% specifies the design of each scan. For ABAB block design and
% cyclic designs (as w/ more convention mrVista data),  these 
% can be generated automatically. Or,  you can make them yourself:
% each .par file should be an ASCII text file w/ two columns:
% first,  the onset time in seconds of each block/trial/cycle; second, 
% an integer specifying the trial condition (e.g.,  for ABAB block, 
% this could be alternating 0 and 1). An optional third column
% provides labels. See writepar for more info.
%
% ARGS:
% input:
%       view: mrVista view struct
%        
%       roi: specify the ROI data to plot. Can be
%       a # (index into view's ROIs) or name(name of ROI), 
%       or the ROI substruct itself.
%
%       scans: scans in the current view/data dt to plot. Default is
%       currently-selected scan. For multiple scans,  will concatenate
%       together after detrending (using the detrend options saved in the
%       dataTYPES struct in the mrSESSION file).
%
%       dt: data type to use. Defaults to currently selected data
%       type.
%
%		queryFlag: flag to query the user if confirmation needed.
%		This currently applies to the case where the data to be plotted
%		come from a different data type than that for the view. If 0, will
%		plot the tc data from the other data type without asking. If 1,
%		will ask first. [defaults to 1]
%
%output:
%       tc: data structure with info about the data and UI.
%
% More notes:
% This is currently implemented as a small set of linked analysis tools, 
% all starting with the prefix 'tc_'. This particular piece of code
% decides,  based on the number of input args,  whether to open a new
% tc user interface or just update an existing one,  and then refreshes the 
% current tc view according to the time course data and user prefs.
%
% Here's how it decides to open a new UI or not: if a view is passed as the
% first argument,  it opens a new one. If there are no input args,  it
% assumes the current figure has the interface and refreshes it. (This is
% called by all the callbacks on the interface).
% 
% The time course data,  condition information,  user prefs,  and handles to 
% important controls are all kept in a tc struct stored in the user
% interface's 'UserData' field. I currently treat each UI as a separate
% figure; though in time I may find it useful to group several interfaces
% on multiple axes in the same figure.

% 1/3/04 ras: wrote it.
% 1/04: added signal to noise ratios,  ability to switch off different cond
% displays,  shift onsets,  change colors
% 2/04: added ability to read multiple scans / concat parfiles if it uses
% them
% 2/23/04: broke up into several functions,  under mrLoadRet sub-section
% Plots/TimeCourseUI. Also made an offshoot of this,  fancyplot2,  which
% doesn't use the mrLoadRet view info,  for kalanit. Renamed timeCourseUI
% (previously ras_tc -- saved that as an older,  stable version).
% 04/07/05: cleaned up logic to be slightly more "object oriented"
% (separate getting the data and putting up an interface),  changed
% how 2nd arg is defined (roi name/num/struct instead of coords).
% Also changed some var names (e.g. series) to be consistent w/ other
% functions.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1ST DECISION: extract new time course data (w/ corresponding
% axes figure) or just re-render existing data? This is decided by 
% the # args: if 1,  update data; otherwise,  just render.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin >= 1,  openFigFlag = 1;
else             openFigFlag = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Open the figure if needed %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if openFigFlag
    if notDefined('dt'),  dt = viewGet(view,'curDataType'); end
	if notDefined('queryFlag'), queryFlag = 1;				end
    
    if notDefined('scans'),
        % scans = viewGet(view,'curScan');
        [scans dt] = er_getScanGroup(view);
    end
        
    if notDefined('roi')
        r = viewGet(view,'curRoi');
        if r==0, myErrorDlg('ROI required for time course analysis.'); end
        % roi = view.ROIs(r);
	end
    
	
    % init a time course struct from params 
    % (this includes loading the data)
    tc = tc_init(view, roi, scans, dt, queryFlag);
    
    % check if we couldn't init the tc b/c of parfiles
    if isempty(tc)
        myWarnDlg('Couldn''t start Time Course UI. No parfiles assigned.'); 
        return
    end
    
    % put up the interface window
    tc = tc_openFig(tc);
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RENDER TIME COURSE (taking into account prefs as specified in the
% ui)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get the data struct -- in the current axes' UserData
tc = get(gcf, 'UserData');

% before rendering below,  check that the figure exists -- if it doesn't
% (e.g.,  for a saved tc struct),  don't update
if ~checkfields(tc, 'ui', 'fig') | ~ishandle(tc.ui.fig),  return; end

% clear previous axes in the figure
old = findobj('Type',  'axes',  'Parent', tc.ui.plot);
old = [old; findobj('Type', 'uicontrol', 'Parent', tc.ui.plot)];
old = [old; findobj('Type', 'axes', 'Parent', tc.ui.fig)];
old = [old; findobj('Type', 'uicontrol', 'Parent', tc.ui.fig)];
delete(old);

% parse the preferences set using the ui,  and plot
switch tc.plotType
    case 1,  tc_plotWholeTc(tc, tc.ui.plot);    
    case 2,  tc_plotSubplots(tc, 0); % tc_plotAllTrials(tc);    
    case 3,  tc_plotMeanTrials(tc, tc.ui.plot);
    case 4,  tc_plotRelamps(tc);
    case 5,  tc_barMeanAmplitudes(tc);
    case 6,  tc_plotSubplots(tc);
    case 7,  tc_meanAmpsPlusTcs(tc);
    case 8,  tc = tc_plotFFT(tc);
    case 9,  tc = tc_visualizeGlm(tc);
    case 10,  tc = tc_visualizeCorAnal(tc);
    case 11, tc = tc_sparklineWholeTc(tc);
    otherwise,  error('Invalid plot type.');
end

% stash the updated data struct
set(tc.ui.fig, 'UserData', tc);

return