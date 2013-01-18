%
% NAME:   mrAlign (ver. 2.3)
% AUTHOR: SPG, ABP, GMB, SE, RMK, BTB, ON 
% DATE: Started with mrLoadRet done on 10/94
% PURPOSE:
%	Main routine for menu driven matlab program to view and analyze
%	volumes of anatomical and functional MRI data.  May be run either
%	with mrLoadRet to analyze single plane data, or as a standalone 
%	Matlab application.
% HISTORY:
%	7/24/96	GMB-- 
%	Made changes for work with new volume anatomy directory
%	structure.
%	08/04/96 ABP-
%	Added the computer assist for adjusting the inplanes.
%       Specifically, change the name of the menu that 
%       used to be called 'Align' to the name 'Select'.  
%       Wrote  new 'Align' menu routines.
%       11/12/96 SPG--
%	Added slice rotation control panel. Rotates sagittal slice
%	about center of image in both axial and sagittal axes
%       while maintaining the oblique slice orthogonal to new sagittal image. 
%       Replaced all calls which update the sagittal image so that 
%       rotations may be preserved. Also preserves reflection settings
%       for the oblique image.
%       1/25/97 SPG--
%        Removed Thicken button, setting thicken to run always. Shifted
%        sagittal plane rotation (ie inplane grid rotation) to sagittal
%        control panel.
%       07.23.97 SPG, ABP -- Fixed bug in setting up the inplanes.
%         I was using inplane_pix_size rather
%         than volume_pix_size.  So I changed routines
%         mrSetupInplanes() to use the correct scale factors.
%	  Re-worked the logic of obtaining critical parameters.
%         In sagittal init window elimated options of:
%            'Re-enter Inplane Parameters'
%	     'Re-enter Unfolding Parameters'
%	  Since both of these would have done things visually
%	  but would not have been incorporated in the computation
%	  of translation and rotation matrix.  Bad, bad, bad.
%         Eliminated 'unfoldSubDir' since it was never used.
%      07.30.97 GMB Fixed bug so 'Check Rotation' image shows up
%         In the appropriate window.
%      07.30.97 GMB Turned 'Gross' and 'Fine' buttons into radio buttons.
%      11.21.97 SPG Converted rotation 'gross' 'fine' radio
%               buttons into a slide bar
%      12.11.97 ABP Converting to matlab5.0
%      9.17.98  RMK Converted for compatibility with mrLoadRet-2.0
%      11.21.98 GMB Fixed bug in defining curSize      
%      11.23.98 GMB Added translation control buttons
%      01.20.99 BTB Added control window (navigwin) that
%               translates the inplane structure perpendicular to the
%               currently viewed interpolated oblique anatomy slice.
%      04.20.99 ON  Added menu item for automatic computation of 
%                   rotation and translation
%      04.29.99 BTB Integrated Oscar's cool new code into menus
%      08.30.00 ON  Added menu item for automatic computation of
%                   rotation and translation using bestrotvol.mat as
%                   initial alignment.
%

disp('mrAlign (version 2.3)');

% Global Variables

% Matlab controls for menu driven program
global volinc voldec
global volslislice volslimin1 volslimax1 volslimin2 volslimax2 volslicut
global interpflag
global volcmap 	% Color map
global checkAutoRotFlag   % Flag whether auto rotation has been checked

% Windows
global sagwin obwin joywin navigwin

% Number of Sagittal slices
global numSlices

% Local Variables
volselpts = []; 		% Selected region in volume.
rvolselpts = [];
inpts = [];			% list of alignment points in inplane
volpts = [];			% corresponding points in volume
obX = [0,0];			% Coordinates of sagittal and oblique slices
obY = [0,0];
obXM = [];			% Coordinates of user set inplane slices
obYM = [];
lp = [];			% pointers to the inplane lines we draw
ipThickness = -99;		% inplanes thickness (mm)
ipSkip = -99;			% amount of space skipped between inplane (mm)
curSag = -99;			% sagittal slice currently displaying
reflections = [1,1];		% Keeps track up left/right, up/down flips done by user
sagX = [0,0];
sagY = [0,0];
obMin = 0;
obMax = 0;
sagMin = 0;
sagMax = 500;
numSlices = 124;		% Number of planes of volume anatomy
obslice = [];
sagwin = [];			% Figure with sagittal view
obwin = [];			% Figure with oblique view
voldir = [];			% Directory containing volume anatomy data
sagSlice = [];			% Current sagittal image
sagPts = [];			% Samples for the current sagittal slice.
sagSize = [];			% Current sagittal size
sagCrop = [];			% Sagittal crop region
volume = [];			% Volume of data
obPts = [];			% Locations in volume of oblique slice
obSlice = [];			% Current oblique image
obSize = [];			% Size of oblique image
obSizeOrig = [];                % real size of oblique, used for point selection

if ~strcmp(computer,'PCWIN')
  voldr='/usr/local/mri/anatomy'; % Location of Volume Anatomy and unfolding data
else
  voldr='X:/anatomy';
end

% variables that used to resident when mrLoadRet-1.0 was running
% that mrAlign needs:

numofanats=mrSESSION.nSlices;
anatsz=size(INPLANE.anat);
%curSize=anatsz(1:2);
%11/21/98 gmb changed this line to avoid crashes if inplanes
%aren't loaded before calling mrAlign2.
curSize=mrSESSION.cropInplaneSize;


%%%%%%%%%%%% global constants and variable inits for rotation %%%%%%%%%%%

global axial coronal
axial = 1;
coronal = 2;                    % used to identify axis of rotation
cTheta = 0;                     % default rotation angles
aTheta = 0;
sagDelta = 0.03;               % angle delta in radians
sagDeltaMin = 0.003;
sagDeltaMax = 0.06;
transDelta = 10;               % trans delta in mm
transDeltaMin = 0;
transDeltaMax = 20;
aThetaSave = 0;
cThetaSave = 0;
curInplane = 0;

inpRotDelta = 20;           % inplane grid rotation increment (deg)
inpRotDeltaMin = .5;
inpRotDeltaMax = 35;

inOutDelta = 5;		     % in/out translation in mm
inOutDeltaMin = 0;
inOutDeltaMax = 20;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

volcmap = gray(110);		% Set up color map
volcmap = [volcmap;hsv(110)];

retwin=figure(1);		%mrLoadRet window

% Sagittal window
sagwin = figure('MenuBar','none');
colormap(volcmap);

% Interpolated Oblique window
obwin = figure('MenuBar','none');
colormap(volcmap);

% Rotation joystick window
joywin = figure('MenuBar','none');
set(joywin,'Position', [100, 100, 550, 170]);
colormap(volcmap);

% Oblique-centered navigation window
navigwin = figure('MenuBar','none');
set(navigwin,'Position', [150, 150, 550, 170]);
colormap(volcmap);

set(sagwin, 'Name', 'Interpolated Sagittal Anatomy');
set(obwin, 'Name', 'Interpolated Oblique Anatomy');
set(retwin, 'Name', 'LoadRet Oblique Anatomy');
set(joywin, 'Name', 'Sagittal Rotation Control');
set(navigwin, 'Name', 'Oblique-centered Navigation Control');

% Make sagwin active.
figure(sagwin);

%%%%% Sagittal Buttons %%%%%

%  These are the arrows for moving from one sagittal to another
%  This one is the rightward one step
%
volinc = uicontrol('Style','pushbutton','String','->','Units','normalized','Position',[.9,.95,.1,.05],'Callback','curSag=curSag+1;[sagSlice,sagPts,obSlice,obPts]=mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3),curInplane);lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);');

% This is the leftward one step
%
voldec = uicontrol('Style','pushbutton','String','<-','Units','normalized','Position',[.8,.95,.1,.05],'Callback','curSag=curSag-1;[sagSlice,sagPts,obSlice,obPts]=mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3),curInplane);lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);');

% This is the slider for moving across sagittals faster by dragging
%
volslislice = uicontrol('Style','slider','String','Pos','Units','normalized','Position',[.6,.95,.1,.05],'Callback','curSag=ceil(numSlices*get(volslislice,''value''));[sagSlice,sagPts,obSlice,obPts]=mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3),curInplane);lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);');


%  Control the display contrast
%

% Choose the max value set to highest display intensity
%
volslimax1 = uicontrol('Style','slider','String','Max','Units',...
	'normalized','Position',[.9,.6,.1,.05],'Callback',...
	'myShowImageVol(sagSlice,sagSize,max(sagSlice)*get(volslimin1,''value''),max(sagSlice)*get(volslimax1,''value''),obX,obY)');

% Choose the min value set to lowest display intensity
%
volslimin1 = uicontrol('Style','slider','String','Min','Units',...
	'normalized','Position',[.9,.4,.1,.05],'Callback',...
	'myShowImageVol(sagSlice,sagSize,max(sagSlice)*get(volslimin1,''value''),max(sagSlice)*get(volslimax1,''value''),obX,obY)');


%%%%% Sagittal Init Menu %%%%%

ld = uimenu('Label','Init','separator','on');

% Load information about the volume anatomy data set.
%
uimenu(ld,'Label','Load Volume Anatomy','CallBack', ...
    '[volume, sagSize, numSlices, calc, dataRange] = mrLoadVAnatomy(voldr,subject); curSag = floor(numSlices/2); sagSlice = mrShowSagVol(volume,sagSize,curSag,[]);','Separator','on');

uimenu(ld,'Label','Quit','CallBack', ...
    'delete(obwin); delete(sagwin); delete(joywin); delete(navigwin);','Separator','on');


%%%%% Sagittal File Menu %%%%%
ld = uimenu('Label','File','separator','on');

% 12.15.97 ABP -- Had to hardcode these saves and loads.
%  I couldn't get MATLAB5.0 to clear the keyboard input after
%  a return from a function call.
%uimenu(ld,'Label','Save Rotation','CallBack','estr=mrGetFileVol(''save'',''Rotation file name? '',''inpts volpts trans rot scaleFac'');eval(estr);','Separator','on');
% 4/29/99 BTB -- note that convBestRot is where mrSESSION.alignment gets updated, and volume/flat coords.mat files get deleted.
uimenu(ld,'Label','Save Rotation','CallBack','eval(sprintf(''save bestrotvol inpts volpts trans rot scaleFac''));disp(''Saved: bestrotvol.mat'');convBestRot;','Separator','on');

%uimenu(ld,'Label','Load Rotation','CallBack', ...
% 'estr=mrGetFileVol(''load'',''Rotation file name? '');eval(estr);','Separator','on');
uimenu(ld,'Label','Load Rotation','CallBack','eval(sprintf(''load bestrotvol''));disp(''Loaded: bestrotvol.mat'');','Separator','on');


%%%%% Sagittal Inplanes Menu %%%%%

ld = uimenu('Label','Inplanes','separator','on');

% Create of the set of inplane lines initially
uimenu(ld,'Label','Setup/Refresh Inplanes','CallBack',...
	'[obX,obY,obXM,obYM,lp,ipThickness,ipSkip] =mrSetupInplanes(numofanats,obXM,obYM,lp,ipThickness,ipSkip,volume_pix_size,inplane_pix_size,curInplane);','Separator','on');

uimenu(ld,'Label','Translate Inplanes','CallBack',...
	'[obX,obY,obXM,obYM,lp] = mrTransInplanes(numofanats,obXM,obYM,lp,curInplane);[sagSlice,sagPts,obSlice,obPts]=mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3),curInplane);lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);','Separator','on');

uimenu(ld,'Label','Clip Inplanes','CallBack', ...
 	'[obX,obY,obXM,obYM,lp] = mrClipInplanes(numofanats,obXM,obYM,lp,curInplane); [obSize,obSizeOrig] = mrFindObSize(obX,obY,sagSize,numSlices,curInplane);[sagSlice,sagPts,obSlice,obPts]=mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3),curInplane);lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);','Separator','on');

uimenu(ld,'Label','Select Inplane','CallBack',...
    '[obX,obY,lp,curInplane]=mrSelInplane(numofanats,obXM,obYM,lp,curInplane);[obSize,obSizeOrig] = mrFindObSize(obX,obY,sagSize,numSlices,curInplane);[sagSlice,sagPts,obSlice,obPts]=mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3),curInplane);lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);','Separator','on');

%%%%% Sagittal Rotation Menu %%%%%

ld = uimenu('Label','Rotation','separator','on');

uimenu(ld,'Label','Compute Rotation from Many Points','CallBack', ...
 '[trans,rot]=mrDoAlignVol(inpts,volpts,scaleFac,curSize,sagSize,volume,numSlices,retwin,sagwin,obwin);','Separator','on');

uimenu(ld,'Label','Compute Rotation Automatically','CallBack', ...
   'NCoarseIter = 4; Usebestrotvol = 0; regEstRot;', 'separator', 'on');

uimenu(ld,'Label','Compute Rotation Automatically (use bestrotvol.mat as starting point)','CallBack', ...
   'NCoarseIter = 4; Usebestrotvol = 1; regEstRot;', 'separator', 'on');
% ON - in this case, if the alignment in bestrotvol is good, I guess that the
% coarse iterations can be eliminated. For now, and for safety, I leave 
% it to be 4 (if bestrotvol is a previous manual alignment, then it will be
% good. But if it is a copy of an alignment computed for data acquired using
% the same slice prescription, it might be not good enough to eliminate
% the coarse iterations).

uimenu(ld,'Label','Check Rotation (current slice)','CallBack', ...
'chkImg = mrCheckAlignVol(rot,trans,scaleFac,curSize,viewGet(INPLANE, ''Current Slice''),volume,sagSize,numSlices,obwin);','Separator','on');

uimenu(ld,'Label','Check Rotation (all slices)',...
   'CallBack','regCheckRotAll', 'separator', 'on');

%%%%% Oblique Buttons %%%%%

figure(obwin);

%Select Points button
uicontrol('style','pushbutton','string','Select Points','units','normalized',...
	'Position',[0.0,.95,.2,.05],'CallBack',...
	'[inpts,volpts]=mrSelectPoints(inpts,volpts,retwin,obwin,viewGet(INPLANE, ''Current Slice''),obPts,obSizeOrig,reflections);');

%Undo Last Point button
uicontrol('style','pushbutton','string','Undo Last Point','units','normalized',...
	'Position',[.26,.95,.2,.05],'CallBack', ...
	'[inpts,volpts]=mrUndoAPoint(inpts,volpts);');

%Clear all points button
uicontrol('style','pushbutton','string','Clear All Points','units','normalized',...
	'Position',[.53,.95,.2,.05],'CallBack', ...
	'[inpts,volpts]=mrClearPoints(inpts,volpts);');

%figure(retwin); grid on; figure(obwin); grid on;

%Flip image left/right
uicontrol('style','pushbutton','string','Flip Right/Left','units','normalized',...
	'Position',[.26,.0,.2,.05],'CallBack', '[obSlice,reflections] = mrReflectObl(obSlice,obSize,reflections,1,1);');

%Flip image up/down
uicontrol('style','pushbutton','string','Flip Up/Down','units','normalized',...
	'Position',[.53,.0,.2,.05],'CallBack', '[obSlice,reflections] = mrReflectObl(obSlice,obSize,reflections,2,1);');


volslimax2 = uicontrol('Style','slider','String','Max','Units',...
		'normalized','Position',[.9,.6,.1,.05],'Callback',...
	'myShowImageVol(obSlice,obSize,max(obSlice)*get(volslimin2,''value''),max(obSlice)*get(volslimax2,''value''),sagX,sagY)');

volslimin2 = uicontrol('Style','slider','String','Min','Units',...
		'normalized','Position',[.9,.4,.1,.05],'Callback',...
	'myShowImageVol(obSlice,obSize,max(obSlice)*get(volslimin2,''value''),max(obSlice)*get(volslimax2,''value''),sagX,sagY)');


%%%%%%%%%%% Joystick Control Buttons %%%%%%%%%%%%

figure(joywin);

%%% Sagittal rotation %%%

uicontrol('Style','Text','Position',[42,140,90,14],'String','Sagittal rotation');

uicontrol('Style','pushbutton','String','<--','Position',[25,65,45,20],'CallBack', '[sagSlice,sagPts,cTheta,aTheta,obSlice,obPts]=mrRotSagVol2(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,axial,sagDelta,curSag,reflections,1/scaleFac(1,3),curInplane);lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);');

uicontrol('Style','pushbutton','String','-->','Position',[100,65,45,20],'CallBack', '[sagSlice,sagPts,cTheta,aTheta,obSlice,obPts]=mrRotSagVol2(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,axial,-sagDelta,curSag,reflections,1/scaleFac(1,3),curInplane);lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);');

uicontrol('Style','pushbutton','String','^','Position',[75,90,20,45],'CallBack', '[sagSlice,sagPts,cTheta,aTheta,obSlice,obPts]=mrRotSagVol2(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,coronal,sagDelta,curSag,reflections,1/scaleFac(1,3),curInplane);lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);');

uicontrol('Style','pushbutton','String','v','Position',[75,15,20,45],'CallBack', '[sagSlice,sagPts,cTheta,aTheta,obSlice,obPts]=mrRotSagVol2(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,coronal,-sagDelta,curSag,reflections,1/scaleFac(1,3),curInplane);lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);');

uicontrol('Style','pushbutton','String','0,0','Position',[75,65,20,20],'CallBack','aTheta=0;cTheta=0;[sagSlice,sagPts,obSlice,obPts]=mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3),curInplane);lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);');

 
sagDeltaslider = uicontrol('Style','slider','Position',[120,100,80,20],...
			'Min',sagDeltaMin,'Max',sagDeltaMax,'Value',sagDelta,...
			'Callback','sagDelta=get(sagDeltaslider,''value'');');

%%% Translation %%%

uicontrol('Style','Text','Position',[230,140,60,14],'String','Translation');

uicontrol('Style','pushbutton','String','<--','Position',[200,65,45,20],'CallBack', '[obX,obY,obXM,obYM,lp] = mrTransByButton(numofanats,obXM,obYM,lp,curInplane,transDelta,1);[sagSlice,sagPts,obSlice,obPts]=mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3),curInplane);lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);');

uicontrol('Style','pushbutton','String','-->','Position',[275,65,45,20],'CallBack', '[obX,obY,obXM,obYM,lp] = mrTransByButton(numofanats,obXM,obYM,lp,curInplane,transDelta,2);[sagSlice,sagPts,obSlice,obPts]=mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3),curInplane);lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);');

uicontrol('Style','pushbutton','String','^','Position',[250,90,20,45],'CallBack','[obX,obY,obXM,obYM,lp] = mrTransByButton(numofanats,obXM,obYM,lp,curInplane,transDelta,3);[sagSlice,sagPts,obSlice,obPts]=mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3),curInplane);lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);' );

uicontrol('Style','pushbutton','String','v','Position',[250,15,20,45],'CallBack','[obX,obY,obXM,obYM,lp] = mrTransByButton(numofanats,obXM,obYM,lp,curInplane,transDelta,4);[sagSlice,sagPts,obSlice,obPts]=mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3),curInplane);lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);');

transDeltaslider = uicontrol('Style','slider','Position',[295,100,80,20],...
			'Min',transDeltaMin,'Max',transDeltaMax,'Value',transDelta,...
			'Callback','transDelta=get(transDeltaslider,''value'');');
		    
%%% Rotation %%%

uicontrol('Style','Text','Position',[405,140,60,14],'String','Rotation');

uicontrol('Style','pushbutton','String','<--','Position',[375,65,45,20],'CallBack','[obXM,obYM]=mrRotInplanes(numofanats,obXM,obYM,(-1*inpRotDelta),curInplane);[sagSlice,sagPts,obSlice,obPts]=mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3),curInplane);lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);');
	   
uicontrol('Style','pushbutton','String','-->','Position',[450,65,45,20],'CallBack','[obXM,obYM] = mrRotInplanes(numofanats,obXM,obYM,inpRotDelta,curInplane);[sagSlice,sagPts,obSlice,obPts]=mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3),curInplane);lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);');

% Changed slider size from 40 to 80.  01.26.99 - BW
%
inpRotDeltaslider = uicontrol('Style','slider','Position',[415,100,80,20],...
			'Min',inpRotDeltaMin,'Max',inpRotDeltaMax,'Value', inpRotDelta,...
			'Callback','inpRotDelta=get(inpRotDeltaslider,''Value'');');

%%% Misc buttons (Save/Reload Align Params) %%%
		    
uicontrol('Style','pushbutton','String','Save AlignParams','Position',[375,35,120,20],'CallBack','aThetaSave= aTheta; cThetaSave=cTheta;mrSaveAlignParams(obXM,obYM,subject,inplane_pix_size,ipThickness,ipSkip,curSag,curInplane,aTheta,cTheta)');

uicontrol('Style','pushbutton','String','Reload AlignParams','Position',[375,12,120,20],'CallBack', 'load AlignParams;[obX,obY,obSize,obSizeOrig,sagPts,sagSlice,lp,obPts,obSlice]=mrReloadParams(lp,curInplane,obXM,obYM,sagSize,numSlices,volume,cTheta,aTheta,curSag,reflections,scaleFac);');




%%%%%%%%%%% Navigation Control Buttons %%%%%%%%%%%%

figure(navigwin);

%%% In/out translation %%%

uicontrol('Style','Text','Position',[42,140,90,14],'String','In/Out');

uicontrol('Style','pushbutton','String','Out','Position',[25,65,45,20],'CallBack', '[obX,obY,obXM,obYM,lp] = mrPerpTransByButton(numofanats,obXM,obYM,lp,curInplane,inOutDelta,1);[sagSlice,sagPts,obSlice,obPts]=mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3),curInplane);lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);');

uicontrol('Style','pushbutton','String','In','Position',[100,65,45,20],'CallBack', '[obX,obY,obXM,obYM,lp] = mrPerpTransByButton(numofanats,obXM,obYM,lp,curInplane,inOutDelta,-1);[sagSlice,sagPts,obSlice,obPts]=mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3),curInplane);lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);');

inOutDeltaslider = uicontrol('Style','slider','Position',[25,100,122,20],...
			'Min',inOutDeltaMin,'Max',inOutDeltaMax,'Value', inOutDelta,...
			'Callback','inOutDelta=get(inOutDeltaslider,''Value'');disp([''inOutDelta: '' num2str(inOutDelta)]);');


%%%% Matlab executes code from here to end, exits, then stays resident %%%%%%%

set(volslimax1,'value',.50);
set(volslimax2,'value',.90);
set(volslimin1,'value',0);
set(volslimin2,'value',.15);

% Re-worked the logic of obtaining critical parameters -- 07.23.97 SPG,ABP
% AlignParams.mat doesn't exist

%Check if 'AlignParams' or 'VolParams' exist. 
%If not, then create 'AlignParams'.
if ~check4File('AlignParams') & ~check4File('VolParams')
  mrGetAlignParams(voldr); 
end
%This will create 'AlignParams' from 'VolParams' 
%if necessary (or possible).
mrLoadAlignParams;

% Get the volume pixel size here.
[volume_pix_size] = mrGetVolPixSize(voldr,subject);

%compile the scale factors for inplane and volume anatomies
scaleFac = [inplane_pix_size;volume_pix_size]

%Load in the volume anatomy and display it sagwin
[volume, sagSize, numSlices, calc, dataRange] = mrLoadVAnatomy(voldr,subject);

% First time through this will not be a parameter in VolParams.mat
if curSag < 0
	curSag = floor(numSlices/2); 
end

figure(sagwin);
sagSlice = mrShowSagVol(volume,sagSize,curSag,[]);
%[sagSlice,sagPts,obSlice,obPts]=mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3),curInplane);

interpflag = 1; % global required to do 3dlinearinterp

% If the user has an inplane that is selected, display it.
if (curInplane ~=0)
	% draw the inplanes
	[obX,obY,obXM,obYM,lp,ipThickness,ipSkip] =mrSetupInplanes(numofanats,obXM,obYM,lp,ipThickness,ipSkip,volume_pix_size,inplane_pix_size,curInplane);
	% interpolated image size
	[obSize,obSizeOrig] = mrFindObSize(obX,obY,sagSize,numSlices,curInplane);
	% draw it
	[sagSlice,sagPts,obSlice,obPts]=mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3),curInplane);

end



