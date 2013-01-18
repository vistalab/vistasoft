function openInplaneWindowforAlign3
%
% Opens a new inplane window and initializes the corresponding data structure.
%
% djh 8/29/01, modified from openInplaneWindow

% Make sure the global variables exist
global mrSESSION INPLANE

disp('Initializing Inplane view')

% Set name, viewType, & subdir
INPLANE.name='INPLANE';
INPLANE.viewType='Inplane';
INPLANE.subdir='Inplane';

% Refresh function, gets called by refreshScreen
INPLANE.refreshFn = 'refreshView';

% Initialize slot for anat
INPLANE.anat = [];

% Initialize slots for co, amp, and ph
INPLANE.co = [];
INPLANE.amp = [];
INPLANE.ph = [];
INPLANE.map = [];
INPLANE.mapName = '';
INPLANE.spatialGrad = [];

% Initialize slots for tSeries
INPLANE.tSeries = [];
INPLANE.tSeriesScan = NaN;
INPLANE.tSeriesSlice = NaN;

% Initialize ROIs
INPLANE.ROIs = [];
INPLANE.selectedROI = 0;

% Initialize curDataType
INPLANE.curDataType = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make displayModes and color maps %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize displayModes
INPLANE=resetDisplayModes(INPLANE);
INPLANE.ui.displayMode='anat';

%%%%%%%%%%%%%%%%%%%
% Open the window %
%%%%%%%%%%%%%%%%%%%

% Figure number for inplane view window
INPLANE.ui.figNum=figure('MenuBar','none');

% Handle for inplane view window
INPLANE.ui.windowHandle = gcf;

% Handle for main axis of inplane view
INPLANE.ui.mainAxisHandle = gca;

% Adjust position and size of main axes so there's room for
% buttons, colorbar, and sliders
set(INPLANE.ui.mainAxisHandle,'position',[0.1 0.1 0.725 0.7]);

% Set minColormap property so there's potentially room for 128
% colors 
set(INPLANE.ui.windowHandle,'minColormap',128)

% Sharing of colors seems like it might be OK, but I'm turning it
% off just to be sure (djh, 1/26/98).
set(gcf,'sharecolors','off');

%%%%%%%%%%%%%%%%%%%%%%%%%
% Add Annotation String %
%%%%%%%%%%%%%%%%%%%%%%%%%

INPLANE = makeAnnotationString(INPLANE);

%%%%%%%%%%%%%%%%%
% Add Color Bar %
%%%%%%%%%%%%%%%%%

% Make color bar and initialize it to 'off'
INPLANE.ui.colorbarHandle=makeColorBar(INPLANE);
setColorBar(INPLANE,'off');
INPLANE.ui.cbarRange = [];

%%%%%%%%%%%%%%%%%%%
% Add popup menus %
%%%%%%%%%%%%%%%%%%%

disp('Attaching popup menus')

INPLANE = makeROIPopup(INPLANE);
INPLANE = makeDataTypePopup(INPLANE);

%%%%%%%%%%%%%%%
% Add sliders %
%%%%%%%%%%%%%%%

disp('Attaching sliders')

% scan slider
w = 0.12; h = 0.04; l = 0; b = 0.95;
INPLANE = makeSlider(INPLANE,'scan',[],[l b w h]);
INPLANE = initScanSlider(INPLANE,1);
INPLANE = selectDataType(INPLANE,INPLANE.curDataType);

% slice slider
w = 0.12; h = 0.04; l = 0; b = 0.85; 
INPLANE = makeSlider(INPLANE,'slice',[],[l b w h]);
INPLANE = initSliceSlider(INPLANE);

% correlation threshold:
INPLANE = makeSlider(INPLANE,'cothresh',[0,1],[.85,.85,.15,.05]);
setCothresh(INPLANE,0);

% phase window:
INPLANE = makeSlider(INPLANE,'phWinMin',[0,2*pi],[.85,.75,.15,.05]);
INPLANE = makeSlider(INPLANE,'phWinMax',[0,2*pi],[.85,.65,.15,.05]);
setPhWindow(INPLANE,[0 2*pi]);

% parameter map window: 
INPLANE = makeSlider(INPLANE,'mapWinMin',[0,1],[.85,.55,.15,.05]);
INPLANE = makeSlider(INPLANE,'mapWinMax',[0,1],[.85,.45,.15,.05]);
setMapWindow(INPLANE,[0 1]);

% anatClip: determines clipping of the anatomy base-image
%           values to fill the range of available grayscales.
INPLANE = makeSlider(INPLANE,'anatMin',[0,1],[.85,.2,.15,.05]);
INPLANE = makeSlider(INPLANE,'anatMax',[0,1],[.85,.1,.15,.05]);
setAnatClip(INPLANE,[0 .5]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize display parameters %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize image field
INPLANE.ui.image = [];

% Show all ROIs
INPLANE.ui.showROIs = 2;

%%%%%%%%%%%%%%%%%%%%%%%%%
% Load user preferences %
%%%%%%%%%%%%%%%%%%%%%%%%%

INPLANE = loadPrefs(INPLANE);

%%%%%%%%%%%%%%%%%%
% Refresh screen %
%%%%%%%%%%%%%%%%%%

INPLANE=refreshScreen(INPLANE);

disp('Done initializing Inplane view')
