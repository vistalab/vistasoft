function mv = multiVoxelUI(view, roi , scans, dt);
%   mv = multiVoxelUI(view, [roi , scans, dt])
%
% multiVoxelUI: user interface for displaying time course / amplitude
% data across roi  within an ROI.
%
%
%
% ARGS:
% input:
%       view: mrVista view struct
%        
%       roi : coords (by the current view's conventions) of the roi 
%       from which to plot data. May also be a string providing the name of
%       the ROI to plot. Default is view's currently-selected ROI.
%
%       scans: scans in the current view/data dt to plot. Default is
%       currently-selected scan. For multiple scans,  will concatenate
%       together after detrending (using the detrend options saved in the
%       dataTYPES struct in the mrSESSION file).
%
%       dt: data type to use. Defaults to currently selected data
%       type.
%
%output:
%       h: handle to time course interface.
%       
%       data: array containing time course data from selected voxels /scans.
%
% More notes:
% This is currently implemented as a small set of linked analysis tools, 
% all starting with the prefix 'tc_'. This particular piece of code
% decides,  based on the number of input args,  whether to open a new
% mv user interface or just update an existing one,  and then refreshes the 
% current mv view according to the time course data and user prefs.
%
% Here's how it decides to open a new UI or not: if a view is passed as the
% first argument,  it opens a new one. If there are no input args,  it
% assumes the current figure has the interface and refreshes it. (This is
% called by all the callbacks on the interface).
% 
% The time course data,  condition information,  user prefs,  and handles to 
% important controls are all kept in a mv struct stored in the user
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
% doesn't use the mrLoadRet view info,  for kalanit. Renamed multiVoxelUI
% (previously ras_tc -- saved that as an older,  stable version).
mrGlobals

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1ST DECISION: extract new time course data (w/ corresponding
% axes figure) or just re-render existing data? This is decided by 
% the # args: if 1,  update data; otherwise,  just render.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin >= 1
    openFigFlag = 1;
else
    openFigFlag = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Open the figure if needed %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if openFigFlag
    if notDefined('dt')
        dt = viewGet(view, 'curDataType');
    end
    
    if notDefined('scans')
        scans = er_getScanGroup(view); %viewGet(view, 'curScan');
    end
        
    if notDefined('roi')
        r = viewGet(view, 'curRoi');
        if r==0
            myErrorDlg('Sorry, you need to load an ROI first.')
        end
        roi = view.ROIs(r);
    end
    
    % want roi to be a struct: parse
    % how it's passed in and make a struct
    roi = tc_roiStruct(view, roi);
       
    % init a voxel data struct from params 
    % (this includes loading the data)
    mv = mv_init(view, roi, scans, dt);
        
    % put up the interface window
    mv = mv_openFig(mv);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RENDER TIME COURSE (taking into account prefs as specified in the
% ui)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get the data struct -- in the current axes' UserData
mv = get(gcf, 'UserData');

% clear previous axes in the figure
old = findobj('Type', 'axes', 'Parent', gcf);
old = [old; findobj('Type', 'uicontrol', 'Parent', gcf)];
delete(old);

% legend (kind of a hack -- legends are tricky)
if mv.params.legend==1
    sel = find(tc_selectedConds(mv));
    co = [];
    for i = 1:length(sel)
        % The legend text should be the specified condition names
        leg{i} = mv.condNames{sel(i)};
        % remove underscores -- the teX interpreter is weird about em
        leg{i}(findstr(leg{i}, '_')) = ' ';
        % also get appropriate colors
        co = [co; mv.condColors{sel(i)}];
    end
    set(gca, 'NextPlot', 'ReplaceChildren');
    if length(sel) > 0
        % Plot some random data,  just to get the legend put up        
        set(gca, 'ColorOrder', co);
        plot(rand(2, length(sel)), 'LineWidth', 4); 
        legend(gca, leg, -1);
    end
end

% select the current plot type
eval( get(mv.ui.plotHandles(mv.ui.plotType), 'Callback') )

% stash the updated data struct
set(gcf, 'UserData', mv);

return