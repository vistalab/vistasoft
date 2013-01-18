function s = openFlatLevelWindow(subdir)
%
% Opens a new flat 'level' window, for viewing
% data separately across gray levels,
% and initializes the corresponding data structure.
%
% FLAT is a cell array of flat structures. 
% s is the index of the new one.
%
% djh and baw, 7/98
% ras, updated from openFlatWindow, 8/04
% Some new things added:
%   * buttons for switching between viewing each level separately,
%     or viewing analyses on the mean tSeries across cortical depth.
%     handles in: view.ui.levelButtons
%   * When viewing separately across levels, a gray level slider,
%     and an edit field for viewing next X levels as a mosaic, F
%     and a label.
%     handles in: view.ui.level, 
%                 view.ui.level.numLevelEdit,
%                 view.ui.level.levelLabel,
%                 view.ui.level.numLevelLabel
mrGlobals;

disp('Initializing Flat view');

% s is the index of the new flat structures.
s = getNewViewIndex(FLAT);

% Set name and viewType
FLAT{s}.name=['FLAT{',num2str(s),'}'];
FLAT{s}.viewType='Flat';

if(isfield(mrSESSION,'sessionCode'))
  FLAT{s}.sessionCode=mrSESSION.sessionCode;
else
  FLAT{s}.sessionCode='';
end

% Prompt user to choose flat subdirectory
if ~exist('subdir','var')    
    subdir = getFlatSubdir;
end

FLAT{s}.subdir = subdir;

% Refresh function, gets called by refreshScreen
FLAT{s}.refreshFn = 'refreshFlatLevelView';

%%%%%%%%%%%%%%%%%%%%%%%%%% Initialize data slots %%%%%%%%%%%%%%%%%%%%%%%%%%
%Initialize slot for anat
FLAT{s}.anat = [];

% Initialize slots for co, amp, and ph
FLAT{s}.co = [];
FLAT{s}.amp = [];
FLAT{s}.ph = [];
FLAT{s}.map = [];
FLAT{s}.mapName = '';
FLAT{s}.mapUnits = '';

% Initialize slots for tSeries
FLAT{s}.tSeriesLevels = {};  % separate tSeries for each level
FLAT{s}.tSeriesMean = {};    % mean for each level
FLAT{s}.tSeries = [];
FLAT{s}.tSeriesScan = NaN;  % these should be obselete
FLAT{s}.tSeriesSlice = NaN; % (I don't intend to use them)

% Initialize ROIs
FLAT{s}.ROIs = [];
FLAT{s}.selectedROI = 0;

% Initialize curDataType / curScan
FLAT{s}.curDataType = 1;
FLAT{s}.curScan = 1;

% initialize ui field
FLAT{s}.ui = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute/load FLAT.coords and FLAT.grayCoords %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
FLAT{s} = getFlatLevelCoords(FLAT{s});

%%%%%%%%%%%%%%%%%%%%%%%%
% Compute FLAT.ui.mask %
%%%%%%%%%%%%%%%%%%%%%%%%
FLAT{s} = makeFlatMaskLevels(FLAT{s});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make displayModes and color maps %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize displayModes
FLAT{s} = resetDisplayModes(FLAT{s});
FLAT{s} = setDisplayMode(FLAT{s},'anat');

%%%%%%%%%%%%%%%%%%%
% Open the window %
%%%%%%%%%%%%%%%%%%%
% Figure number for flat view window
figName = sprintf('Flat %i: %s  [%s]',s,...
                  mrSESSION.sessionCode,...
                  mrSESSION.description);
FLAT{s}.ui.figNum=figure('MenuBar','none',...
                         'Color',[.9 .9 .9],...
                         'Name',figName,...
                         'MenuBar','none',...
                         'NumberTitle','off');

% Handle for flat view window
FLAT{s}.ui.windowHandle = gcf;

% Handle for main axis of flat view
FLAT{s}.ui.mainAxisHandle = gca;

% Adjust position and size of main axes so there's room for
% buttons, colorbar, and sliders
set(FLAT{s}.ui.mainAxisHandle, 'position', [0.15 0.1 0.7 0.7]);


% Set minColormap property so there's potentially room for 128
% colors 
set(FLAT{s}.ui.windowHandle,'minColormap',128);

% Set closeRequestFcn so we can clean up when the window is closed
set(gcf,'CloseRequestFcn','closeFlatWindow');

% Set selectedFLAT when click in this window
set(gcf,'WindowButtonDownFcn',['selectedFLAT =',num2str(s),';']);

%%%%%%%%%%%%%
% Add Menus %
%%%%%%%%%%%%%
disp('Attaching flat menus')
FLAT{s}=filesMenu(FLAT{s});
FLAT{s}=editMenu(FLAT{s});
FLAT{s}=windowMenu(FLAT{s});
FLAT{s}=analysisFlatMenu(FLAT{s});
FLAT{s}=viewMenu(FLAT{s}); 
FLAT{s}=roiMontageMenu(FLAT{s});
FLAT{s}=plotMenu(FLAT{s}); 
FLAT{s}=colorMenu(FLAT{s});
FLAT{s}=xformFlatLevelMenu(FLAT{s});
FLAT{s}=segmentationMenu(FLAT{s});
FLAT{s}=eventMenu(FLAT{s});

% an extra, flat-specific, modification to the color menu:
% (makes curvature thresholding nice)
FLAT{s} = appendColorMenuCallbacks(FLAT{s});

% add back standard matlab menus
set(FLAT{s}.ui.windowHandle,'MenuBar','figure');

%%%%%%%%%%%%%%%%%%%%%%%%%
% Add Annotation String %
%%%%%%%%%%%%%%%%%%%%%%%%%
FLAT{s} = makeAnnotationString(FLAT{s});

%%%%%%%%%%%%%%%%%
% Add Color Bar %
%%%%%%%%%%%%%%%%%
set(gcf,'NextPlot','add');

% Make color bar and initialize it to 'off'
FLAT{s}.ui.colorbarHandle=makeColorBar(FLAT{s});
setColorBar(FLAT{s},'off');
FLAT{s}.ui.cbarRange = [];
set(FLAT{s}.ui.colorbarHandle,'Position',[.2 .13 .6 .04]);

%%%%%%%%%%%%%%%%%%%
% Add popup menus %
%%%%%%%%%%%%%%%%%%%
disp('Attaching popup menus');
FLAT{s} = makeROIPopup(FLAT{s});
FLAT{s} = makeDataTypePopup(FLAT{s});

%%%%%%%%%%%%%%%
% Add Buttons %
%%%%%%%%%%%%%%%
disp('Attaching buttons')
% Make buttons for choosing hemisphere

FLAT{s}=makeHemisphereButtons(FLAT{s});
FLAT{s} = viewSet(FLAT{s}, 'Current Slice',2);  % easier for kgs stuff on RH

FLAT{s}=makeMultiLevelButtons(FLAT{s});

FLAT{s}=makeZoomButtons(FLAT{s});

%%%%%%%%%%%%%%%
% Add sliders %
%%%%%%%%%%%%%%%
disp('Attaching sliders')

% Scan number slider
w = 0.12; h = 0.03; l = 0; b = 0.95;
FLAT{s} = makeSlider(FLAT{s},'scan',[],[l b w h]);
FLAT{s} = initScanSlider(FLAT{s},1);
FLAT{s} = selectDataType(FLAT{s},FLAT{s}.curDataType);

% Gray level slider
w = 0.12; h = 0.03; l = 0; b = 0.85;
FLAT{s} = makeSlider(FLAT{s},'level',[],[l b w h]);
FLAT{s} = initLevelSlider(FLAT{s},1);

% correlation threshold:
FLAT{s} = makeSlider(FLAT{s},'cothresh',[0,1],[.85,.85,.15,0.03]);
setCothresh(FLAT{s},0);

% phase window:
FLAT{s} = makeSlider(FLAT{s},'phWinMin',[0,2*pi],[.85,.75,.15,0.03]);
FLAT{s} = makeSlider(FLAT{s},'phWinMax',[0,2*pi],[.85,.65,.15,0.03]);
setPhWindow(FLAT{s},[0 2*pi]);

% parameter map window: 
FLAT{s} = makeSlider(FLAT{s},'mapWinMin',[0,1],[.85,.55,.15,0.03]);
FLAT{s} = makeSlider(FLAT{s},'mapWinMax',[0,1],[.85,.45,.15,0.03]);
setMapWindow(FLAT{s},[0 1]);

% anatClip: determines clipping of the anatomy base-image
%           values to fill the range of available grayscales.
FLAT{s} = makeSlider(FLAT{s},'anatMin',[0,1],[.85,.2,.15,0.03]);
FLAT{s} = makeSlider(FLAT{s},'anatMax',[0,1],[.85,.1,.15,0.03]);
setAnatClip(FLAT{s},[0 1]);

% Image rotation
FLAT{s} = makeSlider(FLAT{s},'ImageRotate',[0,2*pi],[.5,.04,.2,.035]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Initialize display parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Initialize image field
FLAT{s}.ui.image = [];

% New ROI display fields (ras 01/07)
FLAT{s}.ui.showROIs = 1;        % list of ROIs to show (0 = hide, -1 = selected)
FLAT{s}.ui.roiDrawMethod = 'boxes'; % can be 'boxes', 'perimeter', 'patches'   
FLAT{s}.ui.filledPerimeter = 0; % filled perimeter toggle


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%               Load anat                    %
% (also take the opportunity to reset        %
% display modes, it's empirically necessary) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
FLAT{s} = loadAnat(FLAT{s});
FLAT{s} = expandAnatFlatLevels(FLAT{s});
FLAT{s} = resetDisplayModes(FLAT{s},128,128);
FLAT{s} = thresholdAnatMap(FLAT{s});
FLAT{s} = setDisplayMode(FLAT{s},'anat');
FLAT{s} = switch2SeparateLevels(FLAT{s});

%%%%%%%%%%%%%%%%%%%%%%%%%
% Load user preferences %
%%%%%%%%%%%%%%%%%%%%%%%%%
FLAT{s} = loadPrefs(FLAT{s});

%%%%%%%%%%%%%%%%%%
% Refresh screen %
%%%%%%%%%%%%%%%%%%
FLAT{s}=refreshScreen(FLAT{s});

disp('Done initializing Flat view')

return
