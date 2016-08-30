function s=openRawVolumeWindow
%
% Opens a new volume window and initializes the corresponding data
% structure.
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

% Make sure the global variables exist

mrGlobals
disp('Initializing Volume view')

% s is the index of the new volume structure.
s = getNewViewIndex(VOLUME);

% Set name, viewType, & subdir
VOLUME{s}.name    = ['VOLUME{',num2str(s),'}'];
VOLUME{s}.viewType= 'Volume';
VOLUME{s}.subdir  = 'Volume';

VOLUME{s}.sessionCode=mrSESSION.sessionCode;

% Refresh function, gets called by refreshScreen
VOLUME{s}.refreshFn = 'refreshView';

%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize data slots %
%%%%%%%%%%%%%%%%%%%%%%%%%

% Should be VOLUME{s} = viewInit('VOLUME');

%Initialize slot for anat
VOLUME{s}.anat = [];

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make displayModes and color maps %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize displayModes
VOLUME{s}=resetDisplayModes(VOLUME{s});
VOLUME{s}.ui.displayMode='anat';

%%%%%%%%%%%%%%%%%%%
% Open the window %
%%%%%%%%%%%%%%%%%%%
% Figure number for volume view window
figName = sprintf('Volume %i: %s  [%s]',s,...
                  mrSESSION.sessionCode,...
                  mrSESSION.description);
              
% open the figure
VOLUME{s}.ui.figNum=figure('MenuBar','none','Units','Normalized',...
                    'Color',[.9 .9 .9],'Position',[0.25 0.25 0.5 0.5],...
                    'NumberTitle','off','Name',figName);
                
                    
% Handle for volume view window
VOLUME{s}.ui.windowHandle = gcf;

% Handle for main axis of volume view
VOLUME{s}.ui.mainAxisHandle = gca;

% Adjust position and size of main axes so there's room for
% buttons, colorbar, and sliders
set(VOLUME{s}.ui.mainAxisHandle,'position',[0.1 0.1 0.725 0.7]);

% Set minColormap property so there's potentially room for 128
% colors 
set(VOLUME{s}.ui.windowHandle, 'minColormap', 128);

% Set closeRequestFcn so we can clean up when the window is closed
set(gcf,'CloseRequestFcn','closeVolumeWindow');

% Set selectedVOLUME when click in this window
set(gcf,'WindowButtonDownFcn',['selectedVOLUME =',num2str(s),';']);

%%%%%%%%%%%%%
% Add Menus %
%%%%%%%%%%%%%
disp('Attaching menus')
VOLUME{s}=filesMenu(VOLUME{s});
VOLUME{s}=editMenu(VOLUME{s});
VOLUME{s}=windowMenu(VOLUME{s});
VOLUME{s}=analysisMenu(VOLUME{s});
VOLUME{s}=viewMenu(VOLUME{s}); 
VOLUME{s}=roiMenu(VOLUME{s});
VOLUME{s}=plotMenu(VOLUME{s}); 
VOLUME{s}=colorMenu(VOLUME{s});
VOLUME{s}=xformVolumeMenu(VOLUME{s});
VOLUME{s}=eventMenu(VOLUME{s});
VOLUME{s}=segmentationMenu(VOLUME{s});
VOLUME{s}=helpMenu(VOLUME{s});

%%%%%%%%%%%%%%%%%%%%%%%%%
% Add Annotation String %
%%%%%%%%%%%%%%%%%%%%%%%%%
VOLUME{s} = makeAnnotationString(VOLUME{s});

%%%%%%%%%%%%%%%%%
% Add Color Bar %
%%%%%%%%%%%%%%%%%
% Make color bar and initialize it to 'off'
VOLUME{s}.ui.colorbarHandle=makeColorBar(VOLUME{s});
setColorBar(VOLUME{s},'off');
VOLUME{s}.ui.cbarRange = [];
% move to nicer location
set(VOLUME{s}.ui.colorbarHandle,'Position',[0.2 0.85 0.6 0.03]);

%%%%%%%%%%%%%%%
% Add Buttons %
%%%%%%%%%%%%%%%
disp('Attaching buttons')

% Buttons and editable text fields for choosing slice number and
% slice orientation
VOLUME{s} = makeVolSliceUI(VOLUME{s});
setCurSliceOri(VOLUME{s},1);

% Buttons for choosing gray mode vs volume mode
VOLUME{s} = makeGrayVolButtons(VOLUME{s});

% zoom buttons 
VOLUME{s} = makeZoomButtons(VOLUME{s});

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
w = 0.12; h = 0.04; l = 0; b = 0.95;
VOLUME{s} = makeSlider(VOLUME{s},'scan',[],[l b w h]);
VOLUME{s} = initScanSlider(VOLUME{s},1);
VOLUME{s} = selectDataType(VOLUME{s},VOLUME{s}.curDataType);

% correlation threshold:
VOLUME{s} = makeSlider(VOLUME{s},'cothresh',[0,1],[.85,.85,.15,.05]);
setCothresh(VOLUME{s},0);

% phase window:
VOLUME{s} = makeSlider(VOLUME{s},'phWinMin',[0,2*pi],[.85,.75,.15,.05]);
VOLUME{s} = makeSlider(VOLUME{s},'phWinMax',[0,2*pi],[.85,.65,.15,.05]);
setPhWindow(VOLUME{s},[0 2*pi]);

% parameter map window: 
VOLUME{s} = makeSlider(VOLUME{s},'mapWinMin',[0,1],[.85,.55,.15,.05]);
VOLUME{s} = makeSlider(VOLUME{s},'mapWinMax',[0,1],[.85,.45,.15,.05]);
setMapWindow(VOLUME{s},[0 1]);

% anatClip: determines clipping of the anatomy base-image
%           values to fill the range of available grayscales.
VOLUME{s} = makeSlider(VOLUME{s},'anatMin',[0,1],[.85,.2,.15,.05]);
VOLUME{s} = makeSlider(VOLUME{s},'anatMax',[0,1],[.85,.1,.15,.05]);
setAnatClip(VOLUME{s},[0 .5]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize display parameters %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize image field
VOLUME{s}.ui.image = [];

% New ROI display fields (ras 01/07)
VOLUME{s}.ui.showROIs = 1;        % list of ROIs to show (0 = hide, -1 = selected)
VOLUME{s}.ui.roiDrawMethod = 'boxes'; % can be 'boxes', 'perimeter', 'patches'   
VOLUME{s}.ui.filledPerimeter = 0; % filled perimeter toggle

%%%%%%%%%%%%%%%%%%
% Load Anatomies %
%%%%%%%%%%%%%%%%%%
VOLUME{s} = loadAnat(VOLUME{s});


%% load prefs
VOLUME{s} = loadPrefs(VOLUME{s});

% if the prefs specify a coherence analysis-related mode (co, amp, ph),
% then load a corAnal
if ismember( VOLUME{s}.ui.displayMode, {'co' 'amp' 'ph'} )
    VOLUME{s} = loadCorAnal(VOLUME{s});
end


%%%%%%%%%%%%%%%%%%
% Refresh screen %
%%%%%%%%%%%%%%%%%%
VOLUME{s}=refreshScreen(VOLUME{s});
disp('Done initializing Volume view')

return;



