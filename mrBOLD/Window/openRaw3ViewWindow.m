function s=openRaw3ViewWindow
%
% Opens a volume 3-view (sag,axi,cor) window and initializes the corresponding data structure.
%
% VOLUME is a cell array of volume structures. 
% s is the index of the new one.
%
% This function should ONLY be called by either:
% openVolumeWindow or openGrayWindow.
%
% Modifications:
%
% djh and baw, 7/98
% djh, 2/99 modified to enable the window to be opened under
% either volume or gray mode
%
% djh, 4/99
% - Eliminate overlayClip sliders
% - Added mapWin sliders to show overlay only for pixels with parameter
%   map values that are in the appropriate range.
% bw, 12/29/00
% - scan slider instead of buttons
% djh 2/13/2001
% - open multiple volume windows simultaneously
% ras 10/28/02
% - adds 'Rory' menu for Rory's analysis; local version
% ras 03/06/03
% revamp: now makes a '3-view' showing sagittal, coronal, and axial views
% all at once, instead of paging through the slices

% Make sure the global variables exist
mrGlobals

disp('Initializing Volume view')

% s is the index of the new volume structure.
s = getNewViewIndex(VOLUME); %#ok<NODEF>

% Set name, viewType, & subdir
VOLUME{s} = []; 
VOLUME{s} = viewSet(VOLUME{s}, 'name', ['VOLUME{',num2str(s),'}']);
VOLUME{s} = viewSet(VOLUME{s}, 'viewType',  'Volume');
VOLUME{s} = viewSet(VOLUME{s}, 'subdir', 'Volume');

% Refresh function, gets called by refreshScreen
VOLUME{s} = viewSet(VOLUME{s}, 'refreshFn', 'volume3View'); 

%%%%%%%%%%%%%%%%%%
% Load Anatomies %
%%%%%%%%%%%%%%%%%%
VOLUME{s} = loadAnat(VOLUME{s});
%TODO: Change the functionality of loadAnat to bring it in line with the
%inplane load anat functionality

%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize data slots %
%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize slots for co, amp, and ph
VOLUME{s}.co = [];
VOLUME{s}.amp = [];
VOLUME{s}.ph = [];
VOLUME{s}.map = [];
VOLUME{s}.mapName = '';
VOLUME{s}.mapUnits = '';

% Initialize slots for tSeries
VOLUME{s}.tSeries = [];
VOLUME{s}.tSeriesScan = NaN;
VOLUME{s}.tSeriesSlice = NaN;

% Initialize ROIs
VOLUME{s}.ROIs = [];
VOLUME{s}.selectedROI = 0;

% Initialize curDataType / curScan
VOLUME{s}.curDataType = 1;
VOLUME{s}.curScan = 1;

% Initialize location in volume space
dims = viewGet(VOLUME{s},'Size');
VOLUME{s}.loc = round(dims./2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make displayModes and color maps %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize displayModes
VOLUME{s} = resetDisplayModes(VOLUME{s});
VOLUME{s}.ui.displayMode = 'anat';

%%%%%%%%%%%%%%%%%%%
% Open the window %
%%%%%%%%%%%%%%%%%%%
% Figure number for volume view window
figName = sprintf('Volume %i', s);
if isfield(mrSESSION,'sessionCode') && isfield(mrSESSION,'description'),
  figName = sprintf('%s: %s  [%s]', figName, mrSESSION.sessionCode, ...
                    mrSESSION.description);
end

VOLUME{s}.ui.figNum = figure('Name', figName, ...
                             'MenuBar', 'none', ...
                             'Units', 'Normalized',...
                             'Color', [.9 .9 .9], ...
                             'Position', [0.25 0.25 0.5 0.5],...
                             'NumberTitle', 'off',  ...
                             'Tag', ['3VolumeWindow: ',VOLUME{s}.name]);

% Handle for volume view window
VOLUME{s}.ui.windowHandle = gcf;

% set up 3 axes, for each view of the volume:
VOLUME{s}.ui.sagAxesHandle = axes('position',[.15 .5 .4 .4]);
VOLUME{s}.ui.corAxesHandle = axes('position',[.5 .5 .4 .4]);
VOLUME{s}.ui.axiAxesHandle = axes('position',[.5 .15 .4 .4]);

% The 'main' axis will arbitarily refer to the axial window
VOLUME{s}.ui.mainAxisHandle = VOLUME{s}.ui.axiAxesHandle;

% ras 05/06: for faster updating, keep track of image/obj handles:
VOLUME{s}.ui.underlayHandle = []; % for ML7+, will make overlays
VOLUME{s}.ui.overlayHandle = [];  % a separate img, and use alpha maps
VOLUME{s}.ui.roiHandles = {};

% Set minColormap property so there's potentially room for 128
% colors 
%set(VOLUME{s}.ui.windowHandle, 'minColormap', 128);

% Set closeRequestFcn so we can clean up when the window is closed
set(gcf, 'CloseRequestFcn', 'closeVolumeWindow');

% Set selectedVOLUME when click in this window
set(gcf, 'WindowButtonDownFcn', ['selectedVOLUME =',num2str(s),';']);

%%%%%%%%%%%%%
% Add Menus %
%%%%%%%%%%%%%
disp('Attaching menus')

VOLUME{s} = filesMenu(VOLUME{s});
VOLUME{s} = editMenu(VOLUME{s});
VOLUME{s} = windowMenu(VOLUME{s});
VOLUME{s} = analysisMenu(VOLUME{s});
VOLUME{s} = viewMenu(VOLUME{s}); 
VOLUME{s} = roiMenu(VOLUME{s});
VOLUME{s} = plotMenu(VOLUME{s}); 
VOLUME{s} = colorMenu(VOLUME{s});
VOLUME{s} = xformVolumeMenu(VOLUME{s});
VOLUME{s} = grayMenu(VOLUME{s});
VOLUME{s} = eventMenu(VOLUME{s});
VOLUME{s} = helpMenu(VOLUME{s}, 'Volume');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add Annotation String; move to nicer location %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
VOLUME{s} = makeAnnotationString(VOLUME{s});

%%%%%%%%%%%%%%%%%
% Add Color Bar %
%%%%%%%%%%%%%%%%%
% % Make color bar and initialize it to 'off'
VOLUME{s}.ui.colorbarHandle = makeColorBar(VOLUME{s});
setColorBar(VOLUME{s},'off');
VOLUME{s}.ui.cbarRange = [];

%%%%%%%%%%%%%%%%%%%
% Add buttons     %
%%%%%%%%%%%%%%%%%%%
disp('Attaching buttons')

% Buttons and editable text fields for choosing slice number and
% slice orientation
VOLUME{s} = make3ViewSliceUI(VOLUME{s});
setCurSliceOri(VOLUME{s},1); % default to axials

% Buttons for choosing gray mode vs volume mode
VOLUME{s} = makeGrayVolButtons(VOLUME{s});

% add some zoom buttons
VOLUME{s} = makeZoomButtons(VOLUME{s});

% now add a checkbox to toggle the crosshairs
xHairColor = [1 .5 .5];
if ispref('VISTA', 'xHairColor')
    xHairColor = getpref('VISTA', 'xHairColor', xHairColor);
end
callback = [VOLUME{s}.name ' = toggle3ViewCrossHairs(' VOLUME{s}.name ', gcbo);'];
htmp = uicontrol('Style', 'checkbox', 'String', 'Crosshairs', ...
                 'Value', 0, 'Callback', callback, ...
                 'BackgroundColor', get(gcf,'Color'), ...
                 'ForegroundColor', xHairColor ,...
                 'Units', 'Normalized', 'Position', [0 0.1 0.1 0.05]);
VOLUME{s}.ui.xHairToggleHandle = htmp;
VOLUME{s}.ui.crosshairs = 0; % crosshairs initialized off

%%%%%%%%%%%%%%%%%%%
% Add popup menus %
%%%%%%%%%%%%%%%%%%%
disp('Attaching popup menus')

VOLUME{s} = makeROIPopup(VOLUME{s});
VOLUME{s} = makeDataTypePopup(VOLUME{s});

%%%%%%%%%%%%%%%
% Add sliders %
%%%%%%%%%%%%%%%
disp('Attaching sliders')

% Scan number slider
w = 0.12; h = 0.03; l = 0; b = 0.95;
VOLUME{s} = makeSlider(VOLUME{s},'scan',[],[l b w h]);
VOLUME{s} = initScanSlider(VOLUME{s},1);
VOLUME{s} = selectDataType(VOLUME{s},VOLUME{s}.curDataType);

% correlation threshold:
VOLUME{s} = makeSlider(VOLUME{s},'cothresh',[0,1],[.85,.85,.15,.03]);
setCothresh(VOLUME{s},0);

% phase window:
VOLUME{s} = makeSlider(VOLUME{s},'phWinMin',[0,2*pi],[.85,.75,.15,.03]);
VOLUME{s} = makeSlider(VOLUME{s},'phWinMax',[0,2*pi],[.85,.65,.15,.03]);
setPhWindow(VOLUME{s},[0 2*pi]);

% parameter map window: 
VOLUME{s} = makeSlider(VOLUME{s},'mapWinMin',[0,1],[.85,.55,.15,.03]);
VOLUME{s} = makeSlider(VOLUME{s},'mapWinMax',[0,1],[.85,.45,.15,.03]);
setMapWindow(VOLUME{s},[0 1]);

% Brightness / Contrast: (Replaces older Anat Clip).
VOLUME{s} = makeBrightnessSlider(VOLUME{s},[.85 .2 .15 .03]);
VOLUME{s} = makeSlider(VOLUME{s},'contrast',[0 1],[.85 .1 .15 .03]);
VOLUME{s} = viewSet(VOLUME{s},'brightness',0.5);
VOLUME{s} = viewSet(VOLUME{s},'contrast',0.05);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize display parameters %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize image field
VOLUME{s}.ui.image = [];

% New ROI display fields (ras 01/07)
VOLUME{s}.ui.showROIs = -2;        % list of ROIs to show (0 = hide, -1 = selected)
VOLUME{s}.ui.roiDrawMethod = 'perimeter'; % can be 'boxes', 'perimeter', 'patches'   
VOLUME{s}.ui.filledPerimeter = 0; % filled perimeter toggle

disp('Done initializing Volume view')

return;