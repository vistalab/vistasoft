function s=openInplaneWindow
%Obsolete
%
% Opens a new inplane window and initializes the corresponding data
% structure.
%
% INPLANE is a cell array of inplane structures. 
% s is the index of the new one.
%
% Modifications:
%
% djh, 1/9/98
% djh, 4/99
% - Eliminate overlayClip sliders
% - Added mapWin sliders to show overlay only for pixels with parameter
%   map values that are in the appropriate range.
% bw, 12/29/00
% - scan slider instead of buttons
% - anatomy slider instead of buttons
% djh 2/13/2001
% - open multiple inplane windows simultaneously
% ras 06/25/04
% - temp disabled the turning-off of standard menu bar, to 
% see if this helps with some export issues
% $Author: sayres $
% $Date: 2008/06/24 22:37:30 $
% Make sure the global variables exist

mrGlobals
disp('Initializing Inplane view')

% s is the index of the new inplane structure.
s = getNewViewIndex(INPLANE);
% Set name, viewType, & subdir
INPLANE{s}.name=['INPLANE{',num2str(s),'}'];
INPLANE{s}.viewType='Inplane';
INPLANE{s}.subdir='Inplane';
if(isfield(mrSESSION,'sessionCode'))
  INPLANE{s}.sessionCode=mrSESSION.sessionCode;
else
  INPLANE{s}.sessionCode='';
end

    
% Refresh function, gets called by refreshScreen
INPLANE{s}.refreshFn = 'refreshView';

% Initialize slot for anat
INPLANE{s}.anat = [];

% Initialize slots for co, amp, and ph
INPLANE{s}.co = [];
INPLANE{s}.amp = [];
INPLANE{s}.ph = [];
INPLANE{s}.map = [];
INPLANE{s}.mapName = '';
INPLANE{s}.mapUnits = '';
INPLANE{s}.spatialGrad = [];

% Initialize slots for tSeries
INPLANE{s}.tSeries = [];
INPLANE{s}.tSeriesScan = NaN;
INPLANE{s}.tSeriesSlice = NaN;

% Initialize ROIs
INPLANE{s}.ROIs = [];
INPLANE{s}.selectedROI = 0;

% Initialize curDataType
INPLANE{s}.curDataType = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make displayModes and color maps %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize displayModes
INPLANE{s}=resetDisplayModes(INPLANE{s});
INPLANE{s}.ui.displayMode='anat';

%%%%%%%%%%%%%%%%%%%
% Open the window %
%%%%%%%%%%%%%%%%%%%
% Figure number for inplane view window
if isfield(mrSESSION,'sessionCode') & isfield(mrSESSION,'description'),
  figName = sprintf('Inplane %i: %s  [%s]',s,...
                    mrSESSION.sessionCode,...
                    mrSESSION.description);
else,
  figName = '';
end
INPLANE{s}.ui.figNum=figure('MenuBar','none',...
                            'NumberTitle','off',...
                            'Name',figName,...
                            'Color',[.9 .9 .9], ...
                            'Position',[304   462   760   563]);

% Handle for inplane view window
INPLANE{s}.ui.windowHandle = gcf;

% Handle for main axis of inplane view
INPLANE{s}.ui.mainAxisHandle = gca;
% Adjust position and size of main axes so there's room for
% buttons, colorbar, and sliders
set(INPLANE{s}.ui.mainAxisHandle,'position',[0.1 0.2 0.725 0.7]);

% Set minColormap property so there's potentially room for 128
% colors 
set(INPLANE{s}.ui.windowHandle,'minColormap',128)

% Set closeRequestFcn so we can clean up when the window is closed
set(gcf,'CloseRequestFcn','closeInplaneWindow');

% Set selectedINPLANE when click in this window
set(gcf,'WindowButtonDownFcn',['selectedINPLANE =',num2str(s),';']);
%%%%%%%%%%%%%
% Add Menus %
%%%%%%%%%%%%%
disp('Attaching menus')

INPLANE{s} = filesMenu(INPLANE{s});
INPLANE{s} = editMenu(INPLANE{s});
INPLANE{s} = windowMenu(INPLANE{s});
INPLANE{s} = analysisMenu(INPLANE{s});
INPLANE{s} = viewMenu(INPLANE{s}); 
INPLANE{s} =  roiMenu(INPLANE{s});
INPLANE{s} = plotMenu(INPLANE{s}); 
INPLANE{s} = colorMenu(INPLANE{s});
INPLANE{s} = xformInplaneMenu(INPLANE{s});
INPLANE{s} = segmentationMenu(INPLANE{s});
INPLANE{s} = eventMenu(INPLANE{s});
INPLANE{s} = helpMenu(INPLANE{s});

INPLANE{s} = loadAnat(INPLANE{s});

%%%%%%%%%%%%%%%%%%%%%%%%%
% Add Annotation String %
%%%%%%%%%%%%%%%%%%%%%%%%%
INPLANE{s} = makeAnnotationString(INPLANE{s});

%%%%%%%%%%%%%%%%%
% Add Color Bar %
%%%%%%%%%%%%%%%%%
% Make color bar and initialize it to 'off'
INPLANE{s}.ui.colorbarHandle=makeColorBar(INPLANE{s});
setColorBar(INPLANE{s},'off');
INPLANE{s}.ui.cbarRange = [];

%%%%%%%%%%%%%%%%%%%%%%%%%
% Label L/R on Inplanes %
%%%%%%%%%%%%%%%%%%%%%%%%%
INPLANE{s} = labelInplaneLR(INPLANE{s});

%%%%%%%%%%%%%%%%%%%
% Add popup menus %
%%%%%%%%%%%%%%%%%%%

disp('Attaching popup menus')
INPLANE{s} = makeROIPopup(INPLANE{s});
INPLANE{s} = makeDataTypePopup(INPLANE{s});

%%%%%%%%%%%%%%%
% Add sliders %
%%%%%%%%%%%%%%%
disp('Attaching sliders')

% scan slider

w = 0.12; h = 0.04; l = 0; b = 0.95;
INPLANE{s} = makeSlider(INPLANE{s},'scan',[],[l b w h]);
INPLANE{s} = initScanSlider(INPLANE{s},1);
INPLANE{s} = selectDataType(INPLANE{s},INPLANE{s}.curDataType);
% slice slider
w = 0.12; h = 0.04; l = 0; b = 0.85; 
INPLANE{s} = makeSlider(INPLANE{s},'slice',[],[l b w h]);
INPLANE{s} = initSliceSlider(INPLANE{s});

% correlation threshold:
INPLANE{s} = makeSlider(INPLANE{s},'cothresh',[0,1],[.85,.85,.15,.04]);
setCothresh(INPLANE{s},0);
% phase window:
INPLANE{s} = makeSlider(INPLANE{s},'phWinMin',[0,2*pi],[.85,.75,.15,.04]);
INPLANE{s} = makeSlider(INPLANE{s},'phWinMax',[0,2*pi],[.85,.65,.15,.04]);
setPhWindow(INPLANE{s},[0 2*pi]);

% parameter map window: 
INPLANE{s} = makeSlider(INPLANE{s},'mapWinMin',[0,1],[.85,.55,.15,.04]);
INPLANE{s} = makeSlider(INPLANE{s},'mapWinMax',[0,1],[.85,.45,.15,.04]);
setMapWindow(INPLANE{s},[0 1]);
% anatClip: determines clipping of the anatomy base-image
%           values to fill the range of available grayscales.
INPLANE{s} = makeSlider(INPLANE{s},'anatMin',[0,1],[.85,.2,.15,.04]);
INPLANE{s} = makeSlider(INPLANE{s},'anatMax',[0,1],[.85,.1,.15,.04]);
setAnatClip(INPLANE{s},[0 .5]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% add some zoom buttons         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
callBackStr = [INPLANE{s}.name ' = zoomInplane(' INPLANE{s}.name ');'];
htmp = uicontrol('Style','pushbutton','String','Zoom',...
                 'Value',0,'Callback',callBackStr,...
                 'BackgroundColor',[.6 .6 .6],'ForegroundColor',[0 0 0],...
                 'Units','Normalized','Position',[0 0.2 0.1 0.05]); % [0.5 0.5 1]
vs = viewGet(INPLANE{s},'Size');
cbstr = sprintf('%s.ui.zoom = [0 %i 0 %i];',INPLANE{s}.name,vs(2),vs(1));      
cbstr = sprintf('%s\n %s = refreshView(%s);',cbstr,INPLANE{s}.name,INPLANE{s}.name);
htmp = uicontrol('Style','pushbutton','String','Reset Zoom',...
                 'Value',0,'Callback',cbstr,...
                 'BackgroundColor',[.8 .8 .8],'ForegroundColor',[0 0 0],...
                 'Units','Normalized','Position',[0 0.15 0.1 0.05]); % [0.66 1 0.33]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize display parameters %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize image field
INPLANE{s}.ui.image = [];

% New ROI display fields (ras 01/07)
INPLANE{s}.ui.showROIs = -2;        % list of ROIs to show (0 = hide, -1 = selected)
INPLANE{s}.ui.roiDrawMethod = 'boxes'; % can be 'boxes', 'perimeter', 'patches'   
INPLANE{s}.ui.filledPerimeter = 0; % filled perimeter toggle

%%%%%%%%%%%%%%%%%%%%%%%%%
% Load user preferences %
%%%%%%%%%%%%%%%%%%%%%%%%%
INPLANE{s} = loadPrefs(INPLANE{s});

%%%%%%%%%%%%%%%%%%
% Refresh screen %
%%%%%%%%%%%%%%%%%%
% Note: we always want to load the anatomy 
INPLANE{s}=loadAnat(INPLANE{s});
if sum(strcmp(INPLANE{s}.ui.displayMode,{'co','amp','ph'})) ~= 0
    INPLANE{s}=loadCorAnal(INPLANE{s});
end

INPLANE{s}=refreshScreen(INPLANE{s});
disp('Done initializing Inplane view')
return