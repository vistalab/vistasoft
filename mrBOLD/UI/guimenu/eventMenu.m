function view = eventMenu(view, parent);
% Adds an menu to the current view figure
%
% view = eventMenu(view, <parent=gcf>);
%
% This routine contains callbacks tolaunch event-related analyses. Attaches
% to the parent object, which is the view's figure if one isn't added (may
% start attaching to analysis or other menu).
%
% These analyses currently include:
%
%   Assign parfiles to scans: associate particular scans with paradigm
%   files (.par). Parfiles are looked for in the session's stim/parfiles/
%   subdir, and are text tab-delimited files with two columns: onset times
%   of each trial, and a condition number for each trial. Multiple scans
%   can be assigned to multiple parfiles with this interface, though it
%   maps each selected parfile to each selected scan in order from 1st to
%   last. Parfiles need to be assigned to do further analyses for a scan
%   (see er_assignParfilesToScans)
%
%
%   Deconvolve: Deconvolve time courses from rapid event-related scans,
%   creating a new scan in averages. This new scan contains time courses
%   for each voxel of the following format: average trial for cond 1,
%   variances for each time point for cond 1 avg trial, average trial for
%   cond 2, variances for each time point for cond 2 avg trial, etc.
%   Currently the settings are to deconvolve a 22-second time window for
%   each trial, the first 4 secs of which occur before trial onset.
%   (see er_selxavg)
%
%   Appy GLM: apply a GLM to the selected scans. This is the first
%   step in computing contrast maps below, if you select compute
%   contrast map and it doesn't find GLM files, it runs one automatically.
%
%   Compute Contrast Map: Create a parameter map representing
%   a statistic comparing two conditions from the current scan. Note there
%   are two steps here. First it needs to fit a GLM (er_selxavg), which can%   take 5-10 minutes, depending on the number of scans and their size;%   then it needs to compare the values obtained from the first step and%   compute the selected contrast. The first step needs to be done only%   once; the code detects if this has been done already and, if it hasn't,%   runs it.
%       The default statistic for contrast maps is -log10(p) of a t-test between
%   the selected conditions. Saves param maps in the view's dataDir, named
%   'contrastMap_[name].mat'. Also saves a file%   'contrastMap_[name]_ces.mat', which contains the contrast effect size%   in (something very like) % signal.%   (see computeContrastMap, er_mkcontrast(interface))
%
%   'New' GLM tools: A re-implementation of the same algorithms in Apply
%   GLM / Compute Contrast Map (but a little nicer and tailored to mrVista
%   processing params).
%
%   Time Course UI: Plot time courses from selected scan or scans, taking
%   into account condition data from the parfiles, for the selected ROI. If
%   multiple scans are selected, it concatenates them after applying the
%   currently selected detrend options. Allows various options for plotting
%   the data, including whole time course, all trials, mean trials, mean
%   amplitudes, relative fMRI amplitudes, and more.
%   (see timeCourseUI)
%
%   MultiVoxel UI: interface for analyzing data across voxels in the
%   current ROI. Contains many custom analysis tools. Can be used to
%   run Haxby-style pattern analyses, and compute selectivity maps.
%   (see multiVoxelUI)
%
% ras 03/10/04.
if notDefined('parent'), parent = view.ui.windowHandle;  end

mrGlobals;

% do we include a separator? Yes if it's a top-level menu, no if it's a
% submenu
if isequal( get(parent, 'Type'), 'figure' )
	sep = 'on';
else
	sep = 'off';
end

eventMenu = uimenu(parent, 'Label','GLM','Separator',sep);

% Edit Event-Related Parameters:
cb = sprintf('er_editParamsScanGroup(%s); ', view.name);
uimenu(eventMenu, 'Label', 'Edit Event-Related Parameters (scan group)', ...
    'Separator', 'off', 'Callback', cb);

% Assign parfiles callback:
%   view=er_assignParfilesToScans(view);
%   view=refreshScreen(view);
cb = ['er_assignParfilesToScans(',view.name,'); '...
    view.name,'=refreshScreen(',view.name,');'];
uimenu(eventMenu, 'Label', 'Assign parfiles to scans', ...
    'Separator', 'off', 'Callback', cb);

% Show current parfiles callback:
%  er_displayParfiles(view);
cb = sprintf('er_displayParfiles(%s); ,', view.name);
uimenu(eventMenu, 'Label', 'Show parfiles / scan group', ...
    'Separator', 'off', 'Callback', cb);

% group scans submenu
groupMenu = uimenu(eventMenu,'Label','Grouping...','Separator','off');

% group scans callback:
%  er_groupScans(view,[],2);
cb=['er_groupScans(' view.name ',[],2);'];
uimenu(groupMenu,'Label','Group Scans','Separator','off',...
    'Callback',cb);

% assign group to cur scan callback:
%  er_groupScans(view);
cb=['er_groupScans(' view.name ',[],1);'];
uimenu(groupMenu,'Label','Assign Group to Current Scan','Separator','off',...
    'Callback',cb);

% preprocess scans submenu
% (Disabled by ras, 06/06 -- do people still use this?
% I tend not too anymore, but can turn it back on)
% (turned back on, ras, 01/07 -- we'll try using it again.)
preprocessMenu = uimenu(eventMenu,'Label','Preprocess...','Separator','off');

% preprocess selected scans callback:
%  concatenateScans(view);
cb = sprintf('%s = concatenateScans(%s)', view.name, view.name);
uimenu(preprocessMenu,'Label','Preprocess (Select Scans)','Separator','on',...
    'Callback',cb);

% preprocess scan group callback:
%  concatenateScans(view,er_getScanGroup(view));
cb = sprintf('%s = concatenateScans(%s,er_getScanGroup(%s))', ...
    view.name, view.name, view.name);
uimenu(preprocessMenu,'Label','Preprocess (Scan Group)','Separator','on',...
    'Callback',cb);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% New Code GLM/Contrast submenu       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
newGLMMenu = uimenu(eventMenu,'Label', 'GLM/Contrast...',...
    'Separator', 'on');

% apply GLM (new code) scan group callback:
% applyGlm(view,er_getScanGroup(view));
cb = sprintf('%s = applyGlm(%s);', view.name, view.name);
uimenu(newGLMMenu,'Label','Apply GLM, scan group','Separator','off',...
    'Callback',cb);

% Compute Contrast Map (new code) callback:
% computeContrastMap2(view);
cb = sprintf('%s = contrastGUI(%s);', view.name, view.name);
uimenu(newGLMMenu,'Label','Compute Contrast Map','Separator','off',...
    'Accelerator', '4', 'Callback',cb);

% Compute Many Contrast Maps (new code) callback:
% contrastBatchGUI(view);
cb = sprintf('contrastBatchGUI(%s);', view.name);
uimenu(newGLMMenu,'Label','Compute Many Contrasts','Separator','off',...
    'Accelerator', '5', 'Callback',cb);



% % GLM submenu:
% glmMenu = uimenu(eventMenu,'Label','Apply GLM (Old Version)...','Separator','off');
% 
% % apply GLM (current scan) callback:
% %   er_runSelxavgBlock(view);
% %   view=refreshScreen(view);
% cb=['er_runSelxavgBlock(',view.name,'); '...
%     view.name,'=refreshScreen(',view.name,');'];
% uimenu(glmMenu,'Label','Current Scan','Separator','off',...
%     'Callback',cb);
% 
% % apply GLM (block-design) callback:
% %   er_runSelxavgBlock(view,0);
% %   view=refreshScreen(view);
% cb=['er_runSelxavgBlock(',view.name,',0,1); '...
%     view.name,'=refreshScreen(',view.name,');'];
% uimenu(glmMenu,'Label','Select Scans','Separator','off',...
%     'Callback',cb);
% 
% % apply GLM (scan group) callback:
% %   er_runSelxavgBlock(view,-1);
% %   view=refreshScreen(view);
% cb=['er_runSelxavgBlock(',view.name,',-1,1); '...
%     view.name,'=refreshScreen(',view.name,');'];
% uimenu(glmMenu,'Label','Scan Group','Separator','off',...
%     'Callback',cb);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % contrast map submenu       %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% contrastMenu = uimenu(eventMenu,'Label','Contrast Map (Old Code)...','Separator','off');
% 
% % contrast map (current scan) callback:
% % view = er_mkcontrast(view,0);
% cb = sprintf('%s = er_mkcontrast(%s,0);',view.name,view.name);
% uimenu(contrastMenu,'Label','Contrast Map (Current Scan)','Separator','off',...
%     'Callback',cb);
% 
% % contrast map (select scans) callback:
% % view = er_mkcontrast(view);
% cb = sprintf('%s = er_mkcontrast(%s);',view.name,view.name);
% uimenu(contrastMenu,'Label','Contrast Map (Select Scans)','Separator','off',...
%     'Callback',cb);
% % contrast map (scan group) callback:
% % view = er_mkcontrast(view,-1);
% cb = sprintf('%s = er_mkcontrast(%s,-1);',view.name,view.name);
% uimenu(contrastMenu,'Label','Contrast Map (Scan Group)','Separator','off',...
%     'Callback',cb);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% time course UI submenu:    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tcMenu = uimenu(eventMenu,'Label','Time Course UI','Separator','off');
% time course UI callback (current scan):
%  timeCourseUI(view);
cb = sprintf('tc_plotScans(%s,2);', view.name);
uimenu(tcMenu,'Label','Current Scan','Separator','off',...
    'Accelerator','T','Callback',cb);

% time course UI callback (multiple scans):
%  tc_plotScans(view);
cb=['tc_plotScans(' view.name ');'];
uimenu(tcMenu,'Label','Select Scans','Separator','off',...
    'Accelerator','6','Callback',cb);

% time course UI callback (scan group):
%  tc_plotScans(view,1);
cb=['tc_plotScans(' view.name ',1);'];
uimenu(tcMenu,'Label','Scan Group','Separator','off',...
    'Accelerator','G','Callback',cb);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MultiVoxel UI (Same as above w/ TCUI)                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mvMenu = uimenu(eventMenu,'Label','Multi Voxel UI','Separator','off');

cb=['multiVoxelUI(' view.name ', getCurScan(' view.name '));'];
uimenu(mvMenu,'Label','Current Scan','Separator','off',...
    'CallBack',cb);

cb=['mv_plotScans(' view.name ');'];
uimenu(mvMenu,'Label','Select Scans','Separator','off',...
    'CallBack',cb);

cb=['mv_plotScans(' view.name ',1);'];
uimenu(mvMenu,'Label','Scan Group','Separator','off',...
    'Accelerator', 'M', 'CallBack',cb);


return
