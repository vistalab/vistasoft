function h = mrViewer(mr, format, varargin)
% mrVista general-purpose MRI data viewer.
%
%   h = mrViewer([data file or mr struct], [format], [options]);
%
% This tool allows you to visualize various forms of 2D,  3D,  or
% 4D MRI data,  including structural and functional data.
%
% Returns a handle to the viewer UI. Info about the UI,  including
% the base MR object and any maps,  are contained in this object's
% UserData. To get the viewer struct alone,  without initializing a
% GUI,  use mrViewInit.
%
% Optional additional arguments:
%   'session', [val]:   session struct from which the data are taken, 
%                       or handle to a session viewer. Enables saving
%                       ROIs drawn using the viewer to the session.
%
%   'tSeries', [val]:   paths to time series file/files (string or cell
%                       of strings),  to associate with the data.
%
%   'stim', [val]:      stimulus files (.par files) to load and associate
%                       with the tSeries. Enables plotting time courses of
%                       ROIs drawn with the viewer.
%
%   'dock':             always dock all uipanels to a single figure, 
%                       rather than the default of putting some panels
%                       in their own figures.
%
%
% ras,  07/05.

% Code notes:
% this m-file opens the mrViewer figure. Other files refresh
% or perform operations on it.


if notDefined('format'),  format = ''; end

% if MRI data not specified,  prompt via mrLoad:
if notDefined('mr'),   mr = mrLoad([],  format);
elseif ischar(mr),     mr = mrLoad(mr,  format);
end

if ~ispref('VISTA', 'dockFlag'), setpref('VISTA', 'dockFlag', 1); end
dockFlag = getpref('VISTA', 'dockFlag');

% initialize the UI struct
ui = mrViewInit(mr);
clear mr;

% parse options here
for i = 1:length(varargin)
    switch lower(varargin{i})
        case 'dock',  dockFlag = 1;
        case 'undock',  dockFlag = 0;
        case 'session',  ui.session = varargin{i+1};
        case 'tseries',  ui = mrViewAttachTSeries(ui,  varargin{i+1});
        case 'stim',  ui = mrViewAttachStim(ui,  varargin{i+1});
    end
end

% open the figure
ui.fig = figure('Units', 'Normalized', ...
    'Position', [.12 .23 .4 .4], ...
    'UserData', ui, ...
    'Color', 'k', ...
    'NumberTitle', 'off', ...
    'MenuBar', 'none', ...
    'NextPlot', 'add', ...
    'Name', sprintf('%s [%s]', ui.mr.name, ui.tag), ...
    'CloseRequestFcn', sprintf('mrViewClose(''%s'');', ui.tag), ...
    'Tag', ui.tag);

% add main panel for axes
ui.panels.display = uipanel('Position', [0 0 1 1], ...
                           'BackgroundColor', [0 0 0], ...
                           'ShadowColor', [0 0 0], ...
                           'BorderType', 'none');       % [0 0 .4]

% add control panels 
ui = mrViewNavPanel(ui, dockFlag);
ui = mrViewGrayscalePanel(ui, dockFlag);
ui = mrViewROIPanel(ui, 1); % dockFlag
ui = mrViewInfoPanel(ui, 1);
ui = mrViewMeshPanel(ui, 1);
ui = mrViewColorbarPanel(ui, 1);

% add menus
ui = mrViewFileMenu(ui);
ui = mrViewEditMenu(ui);
ui = mrViewViewMenu(ui);
ui = mrViewPlotMenu(ui);
% uimenu(ui.fig, 'Label', 'Window', 'Callback', winmenu('callback'));
ui = mrViewSpaceMenu(ui);
ui = mrViewMeshMenu(ui);
uimenu('Label', '     '); % spacer
ui = mrViewHelpMenu(ui);

% set the initial coordinate space to pixel space
ui = mrViewSet(ui, 'space', ui.settings.space);

% % guess a good initial clip value for the anatomies
% [binCnt binCenters] = hist(ui.mr.data(:), 100);
% clipvals = binCenters( mrvMinmax(find(binCnt>histThresh) ));
% ui = mrViewSetGrayscale(ui, 'clip', clipvals);

% refresh view
ui = mrViewRefresh(ui);

h = ui.fig;

return
