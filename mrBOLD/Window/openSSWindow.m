% script openSSWindow
%
% Sets up the SS data structure, opens and initializes the
% inplane window.
%
% rmk 09/16/98 based on openInplaneWindow
% ras 01/06 we actually still use this, though I try to replace
% it with rxOpenScreenSave -- have added a flip L/R button, removed
% the obsolete shareColors property reference (long ignored by MATLAB)
% and decided to keep the figure menus on by default. Also added a call
% to helpMenu.
global HOMEDIR

% Close SS Window if it already exists:
if exist('SS','var') & ~isempty(SS)
    close(SS.ui.windowHandle);
end

global SS

SS.name='SS';
SS.viewType='SS';
SS.subdir='SS';

% Refresh function, gets called by refreshScreen
SS.refreshFn = 'refreshSSView';

% Initialize slot for anat
SS.anat = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make displayModes and color maps %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize displayModes
SS=resetDisplayModes(SS);
SS.ui.displayMode='anat';

%%%%%%%%%%%%%%%%%%%
% Open the window %
%%%%%%%%%%%%%%%%%%%

% Figure number for inplane view window
SS.ui.figNum = figure('MenuBar', 'figure', 'Color', [.9 .9 .9], ...
                    'Name', sprintf('Screen Save: %s',HOMEDIR), ...
                    'CloseRequestFcn', 'closeSSWindow');

% Handle for inplane view window
SS.ui.windowHandle = gcf;

% Handle for main axis of inplane view
SS.ui.mainAxisHandle = gca;

% Adjust position and size of main axes so there's room for
% buttons, colorbar, and sliders
set(SS.ui.mainAxisHandle, 'position', [0.1 0.1 0.725 0.7]);

% Set minColormap property so there's potentially room for 128
% colors
set(SS.ui.windowHandle, 'minColormap', 128)

%%%%%%%%%%%%%%%
% Add sliders %
%%%%%%%%%%%%%%%
% anatClip: determines clipping of the anatomy base-image
%           values to fill the range of available grayscales.
SS = makeSlider(SS,'anatMin',[0,1],[.85,.4,.15,.05]);
SS = makeSlider(SS,'anatMax',[0,1],[.85,.3,.15,.05]);
setAnatClip(SS,[.5 .52]); % good for DICOM files

%%%%%%%%%%%%%%%%%%%%%%%%%
% Add a flip L/R button %
%%%%%%%%%%%%%%%%%%%%%%%%%
cb = 'SS.anat=fliplr(SS.anat); SS=refreshScreen(SS);';
uicontrol('style','pushbutton','string','Flip L/R','units','normalized',...
          'position',[.85 .5 .15 .05],'Callback',cb);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize display parameters %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize image field
SS.ui.image = [];

%%%%%%%%%%%%%%%%%%
% Refresh screen %
%%%%%%%%%%%%%%%%%%
% Check to see if the SS actually exists. Sometimes it won't
if (~exist('Raw/Anatomy/SS','dir'))
    disp('No SS found');
else
    SS=loadAnat(SS);
    SS.ui.image=SS.anat;
end

helpMenu(SS);

SS = refreshScreen(SS);

disp('Done initializing SS view')

return
