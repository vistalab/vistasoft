function GUI = sessionGUI(session, dt, scan, varargin);
%
% Open a GUI for navigating within and across sessions in mrVista 2.
%
%  GUI = sessionGUI(<session>, <dt>, <scans>, <options>);
%
% This is the first piece of code for the newer, 'compatible'
% mrVista 2. A brief background:
%   summer 2005-early 2006: Rory wrote a bunch of code (w/ some
%   contributions from RFD and BAW) on mrVista2, based on the
%   idea that existing mrVista sessions would be converted to a new
%   format (e.g., NIFTI). This ambitious new code would combine
%   different 'views' like INPLANE and VOLUME into a common view,
%   and transform to different coordinates on the fly.
%
%   july 2006: since there's a huge incentive to not duplicate data
%   sets, Rory decides to rename this existing code base 'mrVista 3',
%   and to change 'mrVista 2' to be a newer set of tools for the
%   existing session structure. This structure is centered around
%   the mrSESSION.mat file, and separate INPLANE, VOLUME views.
%   The new mrVista 2 will use the mrVista 3 interface and conventions,
%   but load data from the old format.
%
%   sessionGUI is the first piece of code written towards this end.
%   It produces a control figure that allows navigation within the
%   scans, data types, maps, and ROIs within a selected session, as
%   before. However, it also allows flipping between sessions readily
%   (updating the mrSESSION and dataTYPES variables as you flip), and
%   keeping track of which sessions logically belong together in session
%   groups called studies.
%
%   The information for the interface is kept in the new global variable
%   GUI. This code also initializes 'hidden' inplane and volume views,
%   to keep track of things like the current data type / scan for tSeries
%   analyses, and the gray edges / nodes in one place. These are always
%   kept as INPLANE{1} and VOLUME{1}.
%
%
%
% ras, 07/01/06.
if notDefined('session'), session = pwd; end
if notDefined('dt'), dt = []; end
if notDefined('scan'), scan = 1; end
if ischar(scan), scan = str2num(scan); end

%%%%%% parse the options
for i = 1:length(varargin)
    switch lower(varargin{i})
        case 'study', study = varargin{i+i}; i = i + 1;
    end
end

mrGlobals2;

% open the figure
GUI = sessionGUI_openFig;   % code below

% attach menus
GUI = sessionGUI_fileMenu(GUI);
GUI = sessionGUI_editMenu(GUI);
GUI = sessionGUI_viewMenu(GUI);
GUI = sessionGUI_analysisMenu(GUI);
GUI = sessionGUI_helpMenu(GUI);

% add panels with extra controls
GUI = sessionGUI_shortcutPanel(GUI);
GUI = sessionGUI_statusPanel(GUI);

% open a slot for MR viewers; attach settings:
GUI.viewers = [];
GUI.settings.viewer = 0; % no viewer loaded
GUI.settings.study = 1;
GUI.settings.session = '';
GUI.settings.dataType = 1;
GUI.settings.scan = 1;
GUI.settings.roiType = 1;
GUI.settings.segmentation = ''; % most recently loaded segmentation

% load set of saved studies (session groupings), from the save
% file studies.mat within the current repository
GUI.studies = studyLoad;
set(GUI.controls.study, 'String', {GUI.studies.name});

% select the specified data type, scans
% if exist('study', 'var') & ~isempty(study)
%     GUI = sessionGUI_selectStudy(study);
%     
% else
if exist( fullfile(pwd, 'mrSESSION.mat'), 'file' )
    % add/select the current session to the Recent Sessions list
    GUI = sessionGUI_addSession(pwd);    
    
else
    % point at recent sessions
    GUI = sessionGUI_selectStudy('(Recent Sessions)');
    
end


return
% /------------------------------------------------------------------/ %





% /------------------------------------------------------------------/ %
function GUI = sessionGUI_openFig
% Create the figure containing the mrVista 2 session GUI.
mrGlobals2;

GUI.fig = figure('Color', [.9 .9 .9], 'Name', 'mrVista 2 Session GUI', ...
    'Units', 'Normalized', 'Position', [0 .75 .5 .2], ...
    'NumberTitle', 'off', 'MenuBar', 'none', ...
    'Tag', 'mrVista Session GUI', ...
    'CloseRequestFcn', 'sessionGUI_close; ');

%%%%% 'panel' 1: study / session selection
% study label
uicontrol('Units', 'normalized', 'Position', [.02 .88 .2 .1], 'Style', 'text', ...
    'String', 'Study', 'FontSize', 10, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'BackgroundColor', [.9 .9 .9]);

% study popup
studies = {'(Recent Sessions)' 'Load New Study...'};
GUI.controls.study = uicontrol('Units', 'normalized', 'Position', [.02 .8 .2 .08], ...
    'Style', 'popup', 'String', studies, ...
    'Callback', 'sessionGUI_selectStudy(gcbo);', ...
    'Value', 1);

% session label
uicontrol('Units', 'normalized', 'Position', [.02 .65 .2 .1], 'Style', 'text', ...
    'String', 'Session', 'FontSize', 10, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'BackgroundColor', [.9 .9 .9]);

% session listbox
GUI.controls.session = uicontrol('Units', 'normalized', 'Position', [.02 .15 .2 .5], ...
    'Style', 'listbox', 'String', {''}, 'Value', 1, 'Min', 0, 'Max', 1); 

% session load pushbutton
uicontrol('Units', 'normalized', 'Position', [.02 .05 .2 .1], ...
    'Style', 'pushbutton', 'String', 'Load', ...
    'Callback', 'sessionGUI_selectSession; ', ...
    'BackgroundColor', [.9 .9 .9], 'HorizontalAlignment', 'center');


%%%%% 'panel' 2: data type / scan selection
% data type label
uicontrol('Units', 'normalized', 'Position', [.27 .88 .2 .1], 'Style', 'text', ...
    'String', 'Data Type', 'FontSize', 10, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'BackgroundColor', [.9 .9 .9]);

% data type popup
GUI.controls.dataType = uicontrol('Units', 'normalized', 'Position', [.27 .8 .2 .08], ...
    'Callback', 'sessionGUI_selectDataType(gcbo);', ...
    'Style', 'popup', 'String', {''}, 'Value', 1);

% scan label
uicontrol('Units', 'normalized', 'Position', [.27 .65 .16 .1], 'Style', 'text', ...
    'String', 'Scan(s)', 'FontSize', 10, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'BackgroundColor', [.9 .9 .9]);

% scan listbox
GUI.controls.scan = uicontrol('Units', 'normalized', 'Position', [.27 .15 .2 .5], ...
    'Style', 'listbox', 'String', {''}, ...
    'Callback', 'sessionGUI_selectScans(gcbo);', ...
    'Value', 1, 'Min', 0, 'Max', 3); % multi selection

% select all scans pushbutton
uicontrol('Units', 'normalized', 'Position', [.27 .05 .2 .1], ...
    'Style', 'pushbutton', 'String', 'Select All', ...
    'Callback', 'guiSet(''scans'', ''all''); ', ...
    'BackgroundColor', [.9 .9 .9], 'HorizontalAlignment', 'center');


%%%%% 'panel' 3: map selection
% map label
uicontrol('Units', 'normalized', 'Position', [.52 .88 .2 .1], 'Style', 'text', ...
    'String', 'Maps', 'FontSize', 10, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'BackgroundColor', [.9 .9 .9]);

% map listbox
GUI.controls.map = uicontrol('Units', 'normalized', 'Position', [.52 .15 .2 .75], ...
    'Style', 'listbox', 'String', {''}, ...
    'Value', 1, 'Min', 0, 'Max', 3);  % multi selection

% map load pushbutton
uicontrol('Units', 'normalized', 'Position', [.52 .05 .2 .1], ...
    'Style', 'pushbutton', 'String', 'Load', ...
    'Callback', 'sessionGUI_loadMap;', ...
    'BackgroundColor', [.9 .9 .9], 'HorizontalAlignment', 'center');

%%%%% 'panel' 4: ROI selection
% ROI label
uicontrol('Units', 'normalized', 'Position', [.77 .88 .2 .1], 'Style', 'text', ...
    'String', 'ROIs', 'FontSize', 10, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'BackgroundColor', [.9 .9 .9]);

% ROI type popup
roiTypes = {'Inplane' 'Volume Shared' 'Gray Local' 'Volume Local' 'Browse...'};
GUI.controls.roiType = uicontrol('Units', 'normalized', 'Position', [.77 .8 .2 .08], ...
    'Callback', 'sessionGUI_selectROIType; ', ...
    'Style', 'popup', 'String', roiTypes, 'Value', 1);


% ROI listbox
GUI.controls.roi = uicontrol('Units', 'normalized', 'Position', [.77 .15 .2 .5], ...
    'Style', 'listbox', 'String', {''}, ...
    'Value', 1, 'Min', 0, 'Max', 3);  % multi selection
% ROI load pushbutton
uicontrol('Units', 'normalized', 'Position', [.77 .05 .2 .1], ...
    'Style', 'pushbutton', 'String', 'Load', ...
    'Callback', 'sessionGUI_loadROI; ', ...
    'BackgroundColor', [.9 .9 .9], 'HorizontalAlignment', 'center');

return
