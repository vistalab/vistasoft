%
% NAME: mrAlign (ver 3)
% AUTHOR: DJH
% DATE: 8/2001
% PURPOSE:
%	Main routine for menu driven matlab program to view and analyze
%	volumes of anatomical and functional MRI data.
% HISTORY:
%	Dozens of people contributed to the original mrAlign. It was written
%   using scripts in matlab 4 without any data structures. This is an 
%   attempt to make a fresh start.
% 
disp('mrAlign (version 3)');

% Global Variables

global HOMEDIR
HOMEDIR = pwd;

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
inpts = [];			    % list of alignment points in inplane
volpts = [];			% corresponding points in volume
obX = [0,0];			% Coordinates of sagittal and oblique slices
obY = [0,0];
obXM = [];			    % Coordinates of user set inplane slices
obYM = [];
lp = [];			    % pointers to the inplane lines we draw
ipThickness = -99;		% inplanes thickness (mm)
ipSkip = -99;			% amount of space skipped between inplane (mm)
curSag = -99;			% sagittal slice currently displaying
reflections = [1,1];	% Keeps track up left/right, up/down flips done by user
sagX = [0,0];
sagY = [0,0];
obMin = 0;
obMax = 0;
sagMin = 0;
sagMax = 500;
numSlices = 124;		% Number of planes of volume anatomy
obslice = [];
sagwin = [];			% Figure with sagittal view
obwin = [];			    % Figure with oblique view
sagSlice = [];			% Current sagittal image
sagPts = [];			% Samples for the current sagittal slice.
sagSize = [];			% Current sagittal size
sagCrop = [];			% Sagittal crop region
volume = [];			% Volume of data
obPts = [];			    % Locations in volume of oblique slice
obSlice = [];			% Current oblique image
obSize = [];			% Size of oblique image
obSizeOrig = [];        % real size of oblique, used for point selection

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
% mrLoadRet stuff
% The goal here is to make mrAlign a standalone program so that you don't
% need to be running mrLoadRet. This stuff needs to be set up to allow
% mrAlign to run on its own.

global mrSESSION dataTYPES vANATOMYPATH
load mrSESSION
subject = mrSESSION.subject;
vAnatPath = getVAnatomyPath(subject)
numofanats = mrSESSION.inplanes.nSlices;
curSize = mrSESSION.inplanes.cropSize;
anatsz = [curSize,numofanats];
inplane_pix_size = 1./mrSESSION.inplanes.voxelSize;

% open inplane window
global INPLANE
openInplaneWindowForAlign3;
set(gcf, 'MenuBar', 'figure');
retwin = INPLANE.ui.figNum;		%mrLoadRet window
INPLANE = loadAnat(INPLANE);
INPLANE = refreshView(INPLANE);
set(gcf,'Units','Normalized','Position',[.5 .05 .45 .45]);

% open screen save window
if (~exist('Raw/Anatomy/SS','dir'))
    disp('No SS found');
    sswin=0;
else

openSSWindow;   
sswin = gcf;
set(sswin,'Units','Normalized','Position',[.5 .05 .45 .45]);
end


try 
    openSSWindow;   
    sswin = gcf;
    set(sswin,'Units','Normalized','Position',[.5 .05 .45 .45]);
catch
    disp('Couldn''t find Screen Save, so no SS Window')
    sswin = [];
end
    
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

volcmap = gray(110);		% Set up color map
volcmap = [volcmap;hsv(110)];

% Sagittal window
sagwin = figure('MenuBar','none');
set(sagwin,'Units','Normalized','Position',[.05 .5 .45 .45]);
colormap(volcmap);

% Interpolated Oblique window
obwin = figure('MenuBar','none');
set(obwin,'Units','Normalized','Position',[.5 .5 .45 .45]);
colormap(volcmap);

% Navigation window
joywin = figure('MenuBar','none');
set(joywin,'Position', [0, 100, 650, 170]);
colormap(volcmap);

set(retwin, 'Name', 'Inplane');
if (sswin)
set(sswin, 'Name', 'Screen Save'); 
end

set(sagwin, 'Name', 'Interpolated Screen Save');
set(obwin, 'Name', 'Interpolated Inplane');
set(joywin, 'Name', 'Navigation Control');

% Make sagwin active.
figure(sagwin);

%%%%% Sagittal Buttons %%%%%

%  These are the arrows for moving from one sagittal to another
%  Rightward one step
volinc = uicontrol('Style','pushbutton','String','->','Units','normalized','Position',[.9,.95,.1,.05],'Callback','curSag=curSag+1;[sagSlice,sagPts,obSlice,obPts]=mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3),curInplane);lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);');
% Leftward one step
voldec = uicontrol('Style','pushbutton','String','<-','Units','normalized','Position',[.8,.95,.1,.05],'Callback','curSag=curSag-1;[sagSlice,sagPts,obSlice,obPts]=mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3),curInplane);lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);');
% Slider for moving across sagittals faster by dragging
volslislice = uicontrol('Style','slider','String','Pos','Units','normalized','Position',[.6,.95,.1,.05],'Callback','curSag=ceil(numSlices*get(volslislice,''value''));[sagSlice,sagPts,obSlice,obPts]=mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3),curInplane);lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);');

% Contrast controls
% Choose the max value set to highest display intensity
volslimax1 = uicontrol('Style','slider','String','Max','Units',...
	'normalized','Position',[.9,.6,.1,.05],'Callback',...
	'myShowImageVol(sagSlice,sagSize,max(sagSlice)*get(volslimin1,''value''),max(sagSlice)*get(volslimax1,''value''),obX,obY)');
% Choose the min value set to lowest display intensity
volslimin1 = uicontrol('Style','slider','String','Min','Units',...
	'normalized','Position',[.9,.4,.1,.05],'Callback',...
	'myShowImageVol(sagSlice,sagSize,max(sagSlice)*get(volslimin1,''value''),max(sagSlice)*get(volslimax1,''value''),obX,obY)');
set(volslimin1,'value',0);
set(volslimax1,'value',.50);

%%%%% Sagittal File Menu %%%%%
ld = uimenu('Label','File','separator','on');

% Reload volume anatomy data set.
uimenu(ld,'Label','Load Volume Anatomy','CallBack', ...
    '[volume,mmPerPix,volSize] = readVolAnat(vAnatPath); sagSize = volSize(1:2); numSlices = volSize(3); curSag = floor(numSlices/2); sagSlice = mrShowSagVol(volume,sagSize,curSag,[]);',...
    'Separator','off');
% Load AlignParams
uimenu(ld,'Label','(Re-)Load AlignParams','CallBack',...
    'load AlignParams;[obX,obY,obSize,obSizeOrig,sagPts,sagSlice,lp,obPts,obSlice]=mrReloadParams(lp,curInplane,obXM,obYM,sagSize,numSlices,volume,cTheta,aTheta,curSag,reflections,scaleFac);',...
    'Separator','on');
% Save AlignParams
uimenu(ld,'Label','Save AlignParams','CallBack',...
    'aThetaSave= aTheta; cThetaSave=cTheta;mrSaveAlignParams(obXM,obYM,subject,inplane_pix_size,ipThickness,ipSkip,curSag,curInplane,aTheta,cTheta)',...
    'Separator','on');
% Load alignment
uimenu(ld,'Label','Load Alignment (bestrotvol)','CallBack',...
    'eval(sprintf(''load bestrotvol''));disp(''Loaded: bestrotvol.mat'');',...
    'Separator','on');
% Save alignment
uimenu(ld,'Label','Save Alignment (bestrotvol)','CallBack',...
    'eval(sprintf(''save bestrotvol inpts volpts trans rot scaleFac''));disp(''Saved: bestrotvol.mat'');',...
    'Separator','on');
% Quit
uimenu(ld,'Label','Quit','CallBack', ...
    'close all; clear all;',...
    'Separator','on');


%%%%% Sagittal Inplanes Menu %%%%%
ld = uimenu('Label','Inplanes','separator','on');

% Create of the set of inplane lines initially
uimenu(ld,'Label','Setup/Refresh Inplanes','CallBack',...
	'[obX,obY,obXM,obYM,lp,ipThickness,ipSkip] =mrSetupInplanes(numofanats,obXM,obYM,lp,ipThickness,ipSkip,volume_pix_size,inplane_pix_size,curInplane);','Separator','on');
% Translate inplanes
uimenu(ld,'Label','Translate Inplanes','CallBack',...
	'[obX,obY,obXM,obYM,lp] = mrTransInplanes(numofanats,obXM,obYM,lp,curInplane);[sagSlice,sagPts,obSlice,obPts]=mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3),curInplane);lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);','Separator','on');
% Rotate inplanes
uimenu(ld,'Label','Clip Inplanes','CallBack', ...
 	'[obX,obY,obXM,obYM,lp] = mrClipInplanes(numofanats,obXM,obYM,lp,curInplane); [obSize,obSizeOrig] = mrFindObSize(obX,obY,sagSize,numSlices,curInplane);[sagSlice,sagPts,obSlice,obPts]=mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3),curInplane);lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);','Separator','on');
% Select inplane
uimenu(ld,'Label','Select Inplane','CallBack',...
    ['[obX,obY,lp,curInplane]=mrSelInplane(numofanats,obXM,obYM,lp,curInplane);[obSize,obSizeOrig] = mrFindObSize(obX,obY,sagSize,numSlices,curInplane);[sagSlice,sagPts,obSlice,obPts]=mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3),curInplane);lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);'...
    'INPLANE = viewSet(INPLANE, ''Current Slice'',curInplane);refreshView(INPLANE);'],'Accelerator','S','Separator','on');

%%%%% Sagittal Alignment Menu %%%%%

ld = uimenu('Label','Alignment','separator','on');

uimenu(ld,'Label','Compute Alignment from Many Points','CallBack', ...
 '[trans,rot]=mrDoAlignVol(inpts,volpts,scaleFac,curSize,sagSize,volume,numSlices,retwin,sagwin,obwin);','Separator','on');

uimenu(ld,'Label','Compute Alignment Automatically','CallBack', ...
   'NCoarseIter = 4; Usebestrotvol = 0; regEstRot;', 'separator', 'on');

uimenu(ld,'Label','Compute Alignment Automatically (use bestrotvol.mat as starting point)','CallBack', ...
   'NCoarseIter = 4; Usebestrotvol = 1; regEstRot;', 'separator', 'on');
% ON - in this case, if the alignment in bestrotvol is good, I guess that the
% coarse iterations can be eliminated. For now, and for safety, I leave 
% it to be 4 (if bestrotvol is a previous manual alignment, then it will be
% good. But if it is a copy of an alignment computed for data acquired using
% the same slice prescription, it might be not good enough to eliminate
% the coarse iterations).

uimenu(ld,'Label','Check Alignment (current slice)','CallBack', ...
'chkImg = mrCheckAlignVol(rot,trans,scaleFac,curSize,viewGet(INPLANE, ''Current Slice''),volume,sagSize,numSlices,obwin);','Separator','on');

uimenu(ld,'Label','Check Alignment (all slices)',...
   'CallBack','regCheckRotAll', 'separator', 'on');

uimenu(ld,'Label','Check Alignment (overlay)',...
   'CallBack','OverlayRegCheck;', 'separator', 'on');


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

%Flip image left/right
uicontrol('style','pushbutton','string','Flip Right/Left','units','normalized',...
	'Position',[.26,.0,.2,.05],'CallBack', '[obSlice,reflections] = mrReflectObl(obSlice,obSize,reflections,1,1);');

%Flip image up/down
uicontrol('style','pushbutton','string','Flip Up/Down','units','normalized',...
	'Position',[.53,.0,.2,.05],'CallBack', '[obSlice,reflections] = mrReflectObl(obSlice,obSize,reflections,2,1);');

% Contrast controls
volslimax2 = uicontrol('Style','slider','String','Max','Units',...
		'normalized','Position',[.9,.6,.1,.05],'Callback',...
	'myShowImageVol(obSlice,obSize,max(obSlice)*get(volslimin2,''value''),max(obSlice)*get(volslimax2,''value''),sagX,sagY)');
volslimin2 = uicontrol('Style','slider','String','Min','Units',...
		'normalized','Position',[.9,.4,.1,.05],'Callback',...
	'myShowImageVol(obSlice,obSize,max(obSlice)*get(volslimin2,''value''),max(obSlice)*get(volslimax2,''value''),sagX,sagY)');
set(volslimin2,'value',.15);
set(volslimax2,'value',.90);

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
inpRotDeltaslider = uicontrol('Style','slider','Position',[415,100,80,20],...
			'Min',inpRotDeltaMin,'Max',inpRotDeltaMax,'Value', inpRotDelta,...
			'Callback','inpRotDelta=get(inpRotDeltaslider,''Value'');');

%%% In/out translation %%%
uicontrol('Style','Text','Position',[550,140,90,14],'String','In/Out');
uicontrol('Style','pushbutton','String','Out','Position',[525,65,45,20],'CallBack', '[obX,obY,obXM,obYM,lp] = mrPerpTransByButton(numofanats,obXM,obYM,lp,curInplane,inOutDelta,1);[sagSlice,sagPts,obSlice,obPts]=mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3),curInplane);lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);');
uicontrol('Style','pushbutton','String','In','Position',[600,65,45,20],'CallBack', '[obX,obY,obXM,obYM,lp] = mrPerpTransByButton(numofanats,obXM,obYM,lp,curInplane,inOutDelta,-1);[sagSlice,sagPts,obSlice,obPts]=mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3),curInplane);lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);');
inOutDeltaslider = uicontrol('Style','slider','Position',[525,100,122,20],...
			'Min',inOutDeltaMin,'Max',inOutDeltaMax,'Value', inOutDelta,...
			'Callback','inOutDelta=get(inOutDeltaslider,''Value'');disp([''inOutDelta: '' num2str(inOutDelta)]);');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% Matlab executes code from here to end, exits, then stays resident %%%%%%%

% Re-worked the logic of obtaining critical parameters -- 07.23.97 SPG,ABP
% AlignParams.mat doesn't exist

%Check if 'AlignParams' exist. 
%If not, then create 'AlignParams'.
if ~check4File('AlignParams')
  mrSaveAlignParams(obXM,obYM,subject,...
    inplane_pix_size,...
    ipThickness,ipSkip,curSag,curInplane,aTheta,cTheta);
end
% Load AlignParams
mrLoadAlignParams;

%Load in the volume anatomy and display it sagwin
[volume,mmPerPix,volSize] = readVolAnat(vAnatPath);
sagSize = volSize(1:2);
numSlices = volSize(3);
%[volume, sagSize, numSlices, calc, dataRange] = mrLoadVAnatomy(voldr,subject);

% Get the volume pixel size here.
volume_pix_size = 1./mmPerPix;
%[volume_pix_size] = mrGetVolPixSize(voldr,subject);

%compile the scale factors for inplane and volume anatomies
scaleFac = [inplane_pix_size;volume_pix_size];

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
	[obX,obY,obXM,obYM,lp,ipThickness,ipSkip] = mrSetupInplanes(numofanats,obXM,obYM,lp,ipThickness,ipSkip,volume_pix_size,inplane_pix_size,curInplane);
	% interpolated image size
	[obSize,obSizeOrig] = mrFindObSize(obX,obY,sagSize,numSlices,curInplane);
	% draw it
	[sagSlice,sagPts,obSlice,obPts] = mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3),curInplane);
end



