function ui = mrViewInit(mr);
%
% ui = mrViewInit(mr);
%
% Initialize a ui struct, containing info needed for 
% mrViewer. 
%
% I have attempted to structure this such that analyses 
% can be run outside the GUI, akin to hidden views in mrVista 1.0.
% In this case, running mrViewInit, without running mrViewer,
% would open the structure without opening a GUI. However, I
% haven't had a chance to test that everything would work 
% without needing a handle -- please feel free to correct 
% any dependence on a GUI.
%
% ras, 07/05.
if ~exist('mr','var') || isempty(mr),   mr = mrLoad;         end

% Key, important fields of the view:
ui.mr = mr;         % 'base' mr object, like the anatomy / underlay
ui.maps = [];       % overlays, or maps to use when thresholding
ui.tSeries = {};    % time series (paths / mr structs) files, cell
ui.stim = [];       % stimulus files
ui.session = [];    % optional session struct / handle to session viewer
                    % to which the data are attached (see sessionViewer)
ui.rois = [];       % ROIs defined on the viewer (but not necessarily
                    % saved yet
ui.fig = [];        % handle to the main figure for the GUI

% the GUI will comprise many uipanels (specifically, see mrvPanel for
% UI panels which can be toggled visible/hidden); the most important
% is the panel where the images of the data will be displayed:
ui.panels.display = [];  % display panel
ui.panels.nav = []; % navigation panel
ui.panels.roi = []; % ROI (region of interest) panel
ui.panels.grayscale = []; % grayscale (underlay image) panel
ui.panels.info = [];  % MR info panel
ui.panels.mesh = [];  % Mesh options panel
ui.panels.overlays = [];  % panels containing overlay info
ui.panels.colorbar = []; % panel containing colorbars for overlays

%%%%%%%%%%%%%
% settings: %
%%%%%%%%%%%%%
% (maybe we should sub-organize this, but I'm ok with having
% a long list...)
ui.settings.space = 1; % pixel space
ui.settings.segmentation = 0;  % selected segmentation
ui.settings.displayFormat = 3; % default is 3 -- single slice
ui.settings.ori = 3; % orientation / default is rows | columns
middleSlice = round(ui.mr.dims(3) / 2);
ui.settings.slice = middleSlice; % default slice for single / montage views
ui.settings.time = 1; % time point, for 4-D data
ui.settings.roi = 0; % index into current ROI (0 = none selected)
ui.settings.montageRows = 2; % # rows for montage view
ui.settings.montageCols = 2; % # cols for montage view
ui.settings.bounds = [1 1 1; ui.mr.dims([2 1 3])]';
ui.settings.cursorLoc = round(ui.mr.dims(1:3) ./ 2);
ui.settings.zoom = [1 size(mr.data,1); ...
                    1 size(mr.data,2); ...
                    1 size(mr.data,3);];
ui.settings.clim = []; % auto by default
ui.settings.cmap = gray(256); % underlay cmap
ui.settings.cbarColorScheme = 1;  % 1 = white-on-black, 2=black-on-white
ui.settings.brightness = 0; % how much to brighent the gray cmap
ui.settings.gamma = 2.0; % not implemented yet, but may be useful
ui.settings.labelAxes = 0; % show axis ticks and label axes
ui.settings.labelDirs = 0; % show direction text in display
ui.settings.labelSlices = 0; % label each slice in display
ui.settings.roiEditMode = 7; % mode for adding to / removing from ROIs:
                             % 1 -- rect
                             % 2 -- circle
                             % 3 -- cube
                             % 4 -- sphere
                             % 5 -- line
                             % 6 -- point
                             % 7 -- grow (3D)
ui.settings.roiViewMode = 3; % mode for showing / hiding ROIs
                             % 1 -- hide ROIs
                             % 2 -- show selected ROI
                             % 3 -- show all ROIs
ui.settings.eqAspect = 1; % preserve aspect ratio
ui.settings.showCursor = 0; % display cursor flag
ui.settings.cursorType = 4; % flag for cursor rendering style:
                            % 1 -- show + sign
                            % 2 -- show circle
                            % 3 -- show crosshairs
                            % 4 -- show crosshairs + gap
ui.settings.baseInterp = 'linear'; % Interpolation method for base
ui.settings.mapInterp = 'nearest'; % Interpolation method for maps
   
% ras 02/2007:
% instead of using 'auto' color limits for the object by default,
% I've found that it's easier to guess a good upper clip limit, but
% leave the lower limit at the min value.

% [ignore clipMin clipMax] = mrClipOptimal(ui.mr.data(:,:,:,1));
% ui.settings.clim = [ui.mr.dataRange(1) clipMax];
[tmp minVal maxVal] = histoThresh(ui.mr.data(:,:,:,1));
ui.settings.clim = [minVal maxVal];

% if the mr object itself has saved settings, load these into the UI:
if isfield(ui.mr,'settings')
    for f = fieldnames(ui.mr.settings)'
        ui.settings.(f{1}) = ui.mr.settings.(f{1});
    end
end

% form a unique object tag for this viewer
i = 1; ui.tag = sprintf('mrViewer%i',i);
while ~isempty(findobj('Tag',ui.tag))
    i = i + 1; ui.tag = sprintf('mrViewer%i',i);
end

return