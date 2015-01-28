function [vw, s] = openMontageWindow
%
% Opens a new inplane montage window and initializes the corresponding data
% structure.
% 
%    [vw s] = openMontageWindow
%
% The inplane montage view is just like the inplane view, but with
% the option of working on many slices at once. It should probably
% replace the standard inplane view, but will initially be kept
% separate for debugging purposes.
%
% INPLANE is a cell array of inplane structures. 
% s is the index of the new one.
%
% Modifications:
%
% ras, off of openInplaneWindow

% Make sure the global variables exist
mrGlobals

% Test to make sure that the session has been updated:
if ~strcmp(sessionGet(mrSESSION,'Version'),'2.1')
    %The session has not been updated to include the new functional data
    %Let's warn the user
    error('This session has not been upgraded to the most recent version. Please run mrInit_sessionMigration to update your session.');
end %if

disp('Initializing Inplane view')

% s is the index of the new inplane structure.
s = getNewViewIndex(INPLANE);

%TODO: Replace all of the rest with viewSet?
INPLANE{s} = struct;
% Set name, viewType, & subdir
%INPLANE{s}.name=['INPLANE{',num2str(s),'}'];
INPLANE{s} = viewSet(INPLANE{s}, 'name', ['INPLANE{',num2str(s),'}']);
%INPLANE{s}.viewType='Inplane';
INPLANE{s} = viewSet(INPLANE{s}, 'view type', 'Inplane');


%INPLANE{s}.subdir='Inplane';
INPLANE{s} = viewSet(INPLANE{s}, 'subdir', 'Inplane');

%INPLANE{s}.sessionCode=mrSESSION.sessionCode;
INPLANE{s} = viewSet(INPLANE{s}, 'Session Code', sessionGet(mrSESSION,'Session Code'));
INPLANE{s} = viewSet(INPLANE{s}, 'Subject', sessionGet(mrSESSION,'Subject'));

% Refresh function, gets called by refreshScreen
%INPLANE{s}.refreshFn = 'refreshMontageView';
INPLANE{s} = viewSet(INPLANE{s}, 'refresh function', 'refreshMontageView');

% Initialize slot for anat from a nifti
%INPLANE{s}.anat = niftiCreate;
INPLANE{s} = viewSet(INPLANE{s}, 'Anatomy Nifti', niftiCreate);

% Initialize slots for co, amp, and ph
%INPLANE{s}.co = [];
INPLANE{s} = viewSet(INPLANE{s}, 'Coherence', []);

%INPLANE{s}.amp = [];
INPLANE{s} = viewSet(INPLANE{s}, 'Amplitude', []);
%INPLANE{s}.ph = [];
INPLANE{s} = viewSet(INPLANE{s}, 'Phase', []);
%INPLANE{s}.map = [];
INPLANE{s} = viewSet(INPLANE{s}, 'Map', []);
%INPLANE{s}.mapName = '';
INPLANE{s} = viewSet(INPLANE{s}, 'Map Name', '');
%INPLANE{s}.mapUnits = '';
INPLANE{s} = viewSet(INPLANE{s}, 'Map Units', []);
%INPLANE{s}.spatialGrad = [];
INPLANE{s} = viewSet(INPLANE{s}, 'Spatial Grad', []);

% Initialize slots for tSeries
%INPLANE{s}.tSeries = [];
INPLANE{s} = viewSet(INPLANE{s}, 'T Series', []);
%INPLANE{s}.tSeriesScan = NaN;
INPLANE{s} = viewSet(INPLANE{s}, 'T Series Scan', NaN);
%INPLANE{s}.tSeriesSlice = NaN;
INPLANE{s} = viewSet(INPLANE{s}, 'T Series Slice', NaN);

% Initialize ROIs
%INPLANE{s}.ROIs = [];
INPLANE{s} = viewSet(INPLANE{s}, 'ROIs',[]);
%INPLANE{s}.selectedROI = 0;
INPLANE{s} = viewSet(INPLANE{s}, 'Selected ROI',[]);

% Initialize curDataType, curScan
%INPLANE{s}.curDataType = 1;
INPLANE{s} = viewSet(INPLANE{s}, 'Current Data Type', 1);

%INPLANE{s}.curScan = 1;
INPLANE{s} = viewSet(INPLANE{s}, 'Cur Scan', 1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make displayModes and color maps %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize displayModes
INPLANE{s}=resetDisplayModes(INPLANE{s});
%INPLANE{s}.ui.displayMode='anat';
INPLANE{s} = viewSet(INPLANE{s}, 'Display Mode', 'anat');


%%%%%%%%%%%%%%%%%%%
% Open the window %
%%%%%%%%%%%%%%%%%%%
% Figure number for inplane view window
figName = sprintf('Inplane %i: %s  [%s]',s,...
    mrSESSION.sessionCode,...
    mrSESSION.description);

%INPLANE{s}.ui.figNum=figure('MenuBar','none',...
%    'NumberTitle','off',...
%    'Name',figName,...
%    'Color',[.9 .9 .9]);   % 'Position', [304   462   760   563]
INPLANE{s} = viewSet(INPLANE{s}, 'Figure Number', figure('MenuBar','none',...
    'NumberTitle','off',...
    'Name',figName,...
    'Color',[.9 .9 .9]));


% Handle for inplane view window
%INPLANE{s}.ui.windowHandle = gcf;
INPLANE{s} = viewSet(INPLANE{s}, 'Window Handle', gcf);

% Handle for main axis of inplane view
%INPLANE{s}.ui.mainAxisHandle = gca;
INPLANE{s} = viewSet(INPLANE{s}, 'Main Axis Handle', gca);


% Adjust position and size of main axes so there's room for
% buttons, colorbar, and sliders
set(INPLANE{s}.ui.mainAxisHandle, 'position', [0.12 0.2 0.7 0.72]);

% Set closeRequestFcn so we can clean up when the window is closed
set(gcf,'CloseRequestFcn','closeInplaneWindow');

% Set selectedINPLANE when click in this window
set(gcf, 'WindowButtonDownFcn', ['selectedINPLANE = ',num2str(s),';']);


%%%%%%%%%%%%%
% Add Menus %
%%%%%%%%%%%%%
disp('Attaching menus')

INPLANE{s} = filesMenu(INPLANE{s});
INPLANE{s} = editMenu(INPLANE{s});
INPLANE{s} = windowMenu(INPLANE{s});
INPLANE{s} = analysisMenu(INPLANE{s});
INPLANE{s} = viewMenu(INPLANE{s}); 
INPLANE{s} = roiMontageMenu(INPLANE{s});
INPLANE{s} = plotMenu(INPLANE{s}); 
INPLANE{s} = colorMenu(INPLANE{s});
INPLANE{s} = xformInplaneMenu(INPLANE{s});
INPLANE{s} = grayMenu(INPLANE{s});
INPLANE{s} = eventMenu(INPLANE{s});
INPLANE{s} = helpMenu(INPLANE{s}, 'Inplane');

% go ahead and load the anatomicals
INPLANE{s} = viewSet(INPLANE{s}, 'Inplane orientation', sessionGet(mrSESSION,'functional orientation'));
INPLANE{s} = loadAnat(INPLANE{s}, sessionGet(mrSESSION,'Inplane Path'));


%%%%%%%%%%%%%%%%%%%%%%%%%
% Add Annotation String %
%%%%%%%%%%%%%%%%%%%%%%%%%
INPLANE{s} = makeAnnotationString(INPLANE{s});

%%%%%%%%%%%%%%%%%
% Add Color Bar %
%%%%%%%%%%%%%%%%%
% Make color bar and initialize it to 'off'
%INPLANE{s}.ui.colorbarHandle=makeColorBar(INPLANE{s});
INPLANE{s} = viewSet(INPLANE{s}, 'Color Bar Handle', makeColorBar(INPLANE{s}));
setColorBar(INPLANE{s},'off');
%INPLANE{s}.ui.cbarRange = [];
INPLANE{s} = viewSet(INPLANE{s}, 'Color Bar Range', []);

%%%%%%%%%%%%%%%%%%%%%%%%%
% Label L/R on Inplanes %
%%%%%%%%%%%%%%%%%%%%%%%%%
INPLANE{s} = labelInplaneLR(INPLANE{s}); %This assumes that the LR data is saved in mrSESSION
%TODO: Change this so it can pull it directly from the orientation of the
%matrix


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
w = 0.12; h = 0.03; l = 0; b = 0.95;
INPLANE{s} = makeSlider(INPLANE{s},'scan',[],[l b w h]);
INPLANE{s} = initScanSlider(INPLANE{s},1);
INPLANE{s} = selectDataType(INPLANE{s},viewGet(INPLANE{s},'Current Data Type'));


% slice slider
w = 0.12; h = 0.03; l = 0; b = 0.85; 
INPLANE{s} = makeSlider(INPLANE{s},'slice',[],[l b w h]);
INPLANE{s} = initSliceSlider(INPLANE{s});


% montage slider (control # of slices shown at once)
w = 0.12; h = 0.03; l = 0; b = 0.7;
INPLANE{s} = makeSlider(INPLANE{s},'montageSize',[],[l b w h]);
INPLANE{s} = initMontageSlider(INPLANE{s});

% correlation threshold:
INPLANE{s} = makeSlider(INPLANE{s},'cothresh',[0,1],[.85 .85 .15 .03]);
setCothresh(INPLANE{s},0);


% phase window:
INPLANE{s} = makeSlider(INPLANE{s},'phWinMin',[0,2*pi],[.85 .75 .15 .03]);
INPLANE{s} = makeSlider(INPLANE{s},'phWinMax',[0,2*pi],[.85 .65 .15 .03]);
setPhWindow(INPLANE{s},[0 2*pi]);

% parameter map window: 
INPLANE{s} = makeSlider(INPLANE{s},'mapWinMin',[0,1],[.85 .55 .15 .03]);
INPLANE{s} = makeSlider(INPLANE{s},'mapWinMax',[0,1],[.85 .45 .15 .03]);
setMapWindow(INPLANE{s},[0 1]);

% Brightness / Contrast: (Replaces older Anat Clip).
INPLANE{s} = makeBrightnessSlider(INPLANE{s},[.85 .2 .15 .03]);
INPLANE{s} = makeSlider(INPLANE{s},'contrast',[0 1],[.85 .1 .15 .03]);
INPLANE{s} = viewSet(INPLANE{s},'brightness',0.5);
INPLANE{s} = viewSet(INPLANE{s},'contrast',0.5);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% update some text labels:      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
htmp = findobj('Style','text','String','scan:','Parent',gcf);
set(htmp,'String','Scan:','HorizontalAlignment','left');

htmp = findobj('Style','text','String','slice:','Parent',gcf);
set(htmp,'String','1st_Slice:','HorizontalAlignment','left');

htmp = findobj('Style','text','String','montageSize:','Parent',gcf);
set(htmp,'String','#_Slices:','HorizontalAlignment','left');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% add  buttons                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
INPLANE{s} = makeZoomButtons(INPLANE{s});


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize display parameters %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize image field
%INPLANE{s}.ui.image = [];
INPLANE{s} = viewSet(INPLANE{s}, 'UI Image', []);

% New ROI display fields (ras 01/07)
%INPLANE{s}.ui.showROIs = -2;  % list of ROIs to show (0 = hide, -1 = selected, -2 = all)
INPLANE{s} = viewSet(INPLANE{s}, 'Show ROIs', -2);
%INPLANE{s}.ui.roiDrawMethod = 'perimeter'; % can be 'boxes', 'perimeter', 'patches'   
INPLANE{s} = viewSet(INPLANE{s}, 'ROI Draw Method', 'perimeter');
%INPLANE{s}.ui.filledPerimeter = 0; % filled perimeter toggle
INPLANE{s} = viewSet(INPLANE{s}, 'Filled Perimeter', 0);

%%%%%%%%%%%%%%%%%%%%%%%%%
% Load user preferences %
%%%%%%%%%%%%%%%%%%%%%%%%%
try
    INPLANE{s} = loadPrefs(INPLANE{s});
catch
    m = 'Couldn''t load your GUI prefs successfully. Try re-saving them.';
    myWarnDlg(m);
end

%%%%%%%%%%%%%%%%%%
% Refresh screen %
%%%%%%%%%%%%%%%%%%
selectView(INPLANE{s});

INPLANE{s} = refreshScreen(INPLANE{s});
disp('Done initializing Inplane view')

% If user requested a view output, give it to them:
% There are issues here with having overlap b/w the global
% INPLANE variable and the local 'view' variable, but I agree
% with the sentiment that an 'open*Window' call should return
% the window structure:   -ras, 07/07
if nargout > 0,	vw = INPLANE{s}; end

return