function [s vw] = openFlatWindow(subdir)
%
% Opens a new flat window and initializes the corresponding data structure.
%
% [s vw] = openFlatWindow(subdir)
%
% FLAT is a cell array of flat structures. 
% s is the index of the new one.
%
% djh and baw, 7/98
%
% Modifications:
%
% djh, 4/99
% - Eliminate overlayClip sliders
% - Added mapWin sliders to show overlay only for pixels with parameter
%   map values that are in the appropriate range.
% wap & rfd, 9/99
% - Allow FLAT.subdir to be changed/set elsewhere
% bw 12/29/00
% - scan slider instead of buttons
% djh 2/13/2001
% - open multiple flat windows simultaneously
% Make sure the global variables exist
% rfd 2003.08.14 - now returns s, the index of the new flat window. This is
% useful for scripting.
% rfd 2005.09.16 fixed missing sessionCode bug.
mrGlobals
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
if(isfield(mrSESSION,'description'))
  description = mrSESSION.description;
else
  description = '';
end


% Prompt user to choose flat subdirectory
if ~exist('subdir','var')
    subdir = getFlatSubdir;
end
FLAT{s}.subdir = subdir;

% Refresh function, gets called by refreshScreen
FLAT{s}.refreshFn = 'refreshView';

%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize data slots %
%%%%%%%%%%%%%%%%%%%%%%%%%
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
FLAT{s}.tSeries = [];
FLAT{s}.tSeriesScan = NaN;
FLAT{s}.tSeriesSlice = NaN;

% Initialize ROIs
FLAT{s}.ROIs = [];
FLAT{s}.selectedROI = 0;

% Initialize curDataType / curScan
FLAT{s}.curDataType = 1;
FLAT{s}.curScan = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute/load FLAT.coords and FLAT.grayCoords %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
FLAT{s} = getFlatCoords(FLAT{s});

%%%%%%%%%%%%%%%%%%%%%%%%
% Compute FLAT.ui.mask %
%%%%%%%%%%%%%%%%%%%%%%%%
FLAT{s} = makeFlatMask(FLAT{s});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make displayModes and color maps %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize displayModes
FLAT{s}=resetDisplayModes(FLAT{s});
FLAT{s}.ui.displayMode='anat';

%%%%%%%%%%%%%%%%%%%
% Open the window %
%%%%%%%%%%%%%%%%%%%
% Figure number for inplane view window
figName = sprintf('Flat %i: %s  [%s]',s,...
                  FLAT{s}.sessionCode,...
                  description);
              
% Figure number for flat view window
FLAT{s}.ui.figNum=figure('MenuBar','none',...
                        'NumberTitle','off',...
                        'Color',[.9 .9 .9],...
                        'Name',figName);

% Handle for flat view window
FLAT{s}.ui.windowHandle = gcf;

% Handle for main axis of flat view
FLAT{s}.ui.mainAxisHandle = gca;

% Adjust position and size of main axes so there's room for
% buttons, colorbar, and sliders
set(FLAT{s}.ui.mainAxisHandle, 'Position', [.15 .08 .7 .7]);

% Set minColormap property so there's potentially room for 128
% colors 
%set(FLAT{s}.ui.windowHandle,'MinColormap',128); % This crashes on ML2016+.


% Set closeRequestFcn so we can clean up when the window is closed
set(gcf,'CloseRequestFcn','closeFlatWindow');

% Set selectedFLAT when click in this window
set(gcf,'WindowButtonDownFcn',['selectedFLAT =',num2str(s),';']);

%%%%%%%%%%%%%
% Add Menus %
%%%%%%%%%%%%%
disp('Attaching flat menus')
FLAT{s} = filesMenu(FLAT{s});
FLAT{s} = editMenu(FLAT{s});
FLAT{s} = windowMenu(FLAT{s});
FLAT{s} = analysisFlatMenu(FLAT{s});
FLAT{s} = viewMenu(FLAT{s}); 
FLAT{s} = roiMenu(FLAT{s});
FLAT{s} = plotMenu(FLAT{s}); 
FLAT{s} = colorMenu(FLAT{s});
FLAT{s} = xformFlatMenu(FLAT{s});
FLAT{s} = segmentationMenu(FLAT{s});
FLAT{s} = helpMenu(FLAT{s}, 'Flat');

%%%%%%%%%%%%%%%%%%%%%%%%%
% Add Annotation String %
%%%%%%%%%%%%%%%%%%%%%%%%%
FLAT{s} = makeAnnotationString(FLAT{s});

%%%%%%%%%%%%%%%%%
% Add Color Bar %
%%%%%%%%%%%%%%%%%
% Make color bar and initialize it to 'off'
FLAT{s}.ui.colorbarHandle = makeColorBar(FLAT{s});
setColorBar(FLAT{s}, 'off');
FLAT{s}.ui.cbarRange = [];

%%%%%%%%%%%%%%%
% Add Buttons %
%%%%%%%%%%%%%%%
disp('Attaching buttons')
% Make buttons for choosing hemisphere
FLAT{s}=makeHemisphereButtons(FLAT{s});
FLAT{s} = viewSet(FLAT{s}, 'CurSlice', 1);

%%%%%%%%%%%%%%%%%%%
% Add popup menus %
%%%%%%%%%%%%%%%%%%%
disp('Attaching popup menus');
FLAT{s} = makeROIPopup(FLAT{s});
FLAT{s} = makeDataTypePopup(FLAT{s});

%%%%%%%%%%%%%%%
% Add sliders %
%%%%%%%%%%%%%%%
disp('Attaching sliders')

% Scan number slider
w = 0.12; h = 0.03; l = 0; b = 0.95;
FLAT{s} = makeSlider(FLAT{s},'scan',[],[l b w h]);
FLAT{s} = initScanSlider(FLAT{s}, 1);
FLAT{s} = selectDataType(FLAT{s}, FLAT{s}.curDataType);

w = .15; % slider width

% correlation threshold:
FLAT{s} = makeSlider(FLAT{s}, 'cothresh', [0 1], [.85 .85 w h]);

setCothresh(FLAT{s},0);
% phase window:
FLAT{s} = makeSlider(FLAT{s}, 'phWinMin', [0,2*pi], [.85 .75 w h]);
FLAT{s} = makeSlider(FLAT{s}, 'phWinMax', [0,2*pi], [.85 .65 w h]);
setPhWindow(FLAT{s},[0 2*pi]);

% parameter map window: 
FLAT{s} = makeSlider(FLAT{s}, 'mapWinMin', [0 1], [.85 .55 w h]);
FLAT{s} = makeSlider(FLAT{s}, 'mapWinMax', [0 1], [.85 .45 w h]);
setMapWindow(FLAT{s},[0 1]);

% anatClip: determines clipping of the anatomy base-image
%           values to fill the range of available grayscales.
FLAT{s} = makeSlider(FLAT{s}, 'anatMin', [0,1], [.85 .2 w h]);
FLAT{s} = makeSlider(FLAT{s}, 'anatMax', [0,1], [.85 .1 w h]);
setAnatClip(FLAT{s},[0 1]);

% Image rotation
FLAT{s} = makeSlider(FLAT{s}, 'ImageRotate', [0 2*pi], [.6 .04 .2 .035]);

%%%%%%%%%%%%%%%%
% Zoom Buttons %
%%%%%%%%%%%%%%%%
FLAT{s} = makeZoomButtons(FLAT{s});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize display parameters %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize image field
FLAT{s}.ui.image = [];

% New ROI display fields (ras 01/07)
FLAT{s}.ui.showROIs = -2;        % list of ROIs to show (0 = hide, -1 = selected)
FLAT{s}.ui.roiDrawMethod = 'perimeter'; % can be 'boxes', 'perimeter', 'patches'   
FLAT{s}.ui.filledPerimeter = 0; % filled perimeter toggle

%%%%%%%%%%%%%%%%%%%%%%%%%
% Load user preferences %
%%%%%%%%%%%%%%%%%%%%%%%%%
FLAT{s} = loadPrefs(FLAT{s});

%%%%%%%%%%%%%%%%%%
% Refresh screen %
%%%%%%%%%%%%%%%%%%
FLAT{s} = loadAnat(FLAT{s});
FLAT{s} = thresholdAnatMap(FLAT{s});
if ~isempty(strcmp(FLAT{s}.ui.displayMode,{'co','amp','ph'}))
    FLAT{s} = loadCorAnal(FLAT{s});
end
FLAT{s} = refreshScreen(FLAT{s});
selectView(FLAT{s});
disp('Done initializing Flat view')

% If user requested a view output, give it to them:
if nargout > 1,	vw = FLAT{s}; end

return;
