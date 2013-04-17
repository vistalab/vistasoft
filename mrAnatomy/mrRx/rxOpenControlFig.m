function rx = rxOpenControlFig(rx)
%
% rx = rxOpenControlFig(rx);
%
% Open the main controls figure for mrRx.
%
% ras 02/05.
% ras 08/05: added 'In' and 'Out' Nudge buttons.

% javaFigs = feature('javafigures');
% if ispref('VISTA', 'javaOn') 
%     feature('javafigures', getpref('VISTA', 'javaOn'));
% else
%     feature('javafigures', 0);
% end

% open the control figure
rx.ui.controlFig = figure('Name','mrRx',...
                          'Tag','rxControlFig',...
                          'Color',[.9 .9 .9],...
                          'Units','Normalized',...
                          'Position',[0.02 .75 .96 .2],...
                          'MenuBar','none',...
                          'NumberTitle','off',...
                          'KeyPressFcn','',...
                          'CloseRequestFcn','rxClose;'); % 'rxKbShortcuts';
                      

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% add frames for different control regions:   %
% slice navigation, rotations, translations,  %
% scales/flips.                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rx.ui.oriFrame = uicontrol('Style','frame',...
                           'String','Orientation',...
                          'BackgroundColor',get(gcf,'Color'),...
                          'ForegroundColor','k',...
                          'Units','Normalized',...
                          'Position',[0 0 .15 1]);
rx.ui.navFrame = uicontrol('Style','frame',...
                           'String','Slice',...
                          'BackgroundColor',get(gcf,'Color'),...
                          'ForegroundColor','k',...
                          'Units','Normalized',...
                          'Position',[0.15 0 .25 1]);
rx.ui.rotFrame = uicontrol('Style','frame',...
                           'String','Rotate',...
                          'BackgroundColor',get(gcf,'Color'),...
                          'ForegroundColor','k',...
                          'Units','Normalized',...
                          'Position',[0.4 0 .25 1]);
rx.ui.transFrame = uicontrol('Style','frame',...
                           'String','Translate',...
                          'BackgroundColor',get(gcf,'Color'),...
                          'ForegroundColor','k',...
                          'Units','Normalized',...
                          'Position',[0.65 0 .25 1]);
rx.ui.scaleFrame = uicontrol('Style','frame',...
                           'String','Flip',...
                          'BackgroundColor',get(gcf,'Color'),...
                          'ForegroundColor','k',...
                          'Units','Normalized',...
                          'Position',[0.9 0 .1 1]);

%%%%%%%%%%%%%%%%%%%
% add buttons     %
%%%%%%%%%%%%%%%%%%%
% flip buttons
rx.ui.axiFlip = rxMakeButton('Axial Flip',[.91 .8 .07 .1]);
rx.ui.corFlip = rxMakeButton('Coronal Flip',[.91 .5 .07 .1]);
rx.ui.sagFlip = rxMakeButton('Sagittal Flip',[.91 .2 .07 .1]);

% in/out nudge buttons
rx.ui.in = uicontrol('Style','pushbutton','Units','normalized',...
                     'Position',[.68 .05 .08 .1],'String','Nudge In',...
                     'BackgroundColor',[.8 .8 .8],'ForegroundColor','k',...
                     'Callback','rxIn;');
rx.ui.out = uicontrol('Style','pushbutton','Units','normalized',...
                     'Position',[.78 .05 .08 .1],'String','Nudge Out',...
                     'BackgroundColor',[.8 .8 .8],'ForegroundColor','k',...
                     'Callback','rxOut;');


%%%%%%%%%%%%%%%%%%%
% add sliders     %
%%%%%%%%%%%%%%%%%%%
% get max range for translations (size of volume)
atMax = size(rx.vol,1);
ctMax = size(rx.vol,2);
stMax = size(rx.vol,3);

at0 = rx.rxDims(1)/2;
ct0 = rx.rxDims(2)/2;
st0 = rx.rxDims(3)/2;


% make the sliders
rx.ui.rxSlice = rxMakeSlider('Rx Slice',[1 rx.rxDims(3)],[.18 .8 .18 .18],1);
rx.ui.axiRot = rxMakeSlider('Rotate Axials CW [deg]',[-180 180],[.43 .8 .18 .18],0,0);
rx.ui.corRot = rxMakeSlider('Rotate Coronals CW [deg]',[-180 180],[.43 .5 .18 .18],0,0);
rx.ui.sagRot = rxMakeSlider('Rotate Sagittals CW [deg]',[-180 180],[.43 .2 .18 .18],0,0);
rx.ui.axiTrans = rxMakeSlider('Translate Up-Down [mm]',[-atMax atMax],[.68 .8 .18 .18],0,0,1);
rx.ui.corTrans = rxMakeSlider('Translate Ant-Pos [mm]',[-ctMax ctMax],[.68 .5 .18 .18],0,0,1);
rx.ui.sagTrans = rxMakeSlider('Translate R-L [mm]',[-stMax stMax],[.68 .2 .18 .18],0,0,1);
rx.ui.nudge = rxMakeSlider('Rot/Trans Slider Step',[0 1],[.18 .2 .18 .18],0,0.5);

set(rx.ui.nudge.sliderHandle,'Callback','rxSetNudge(gcbo);');
set(rx.ui.nudge.editHandle,'Callback','rxSetNudge(gcbo);');

% update the callback for the rx slice slider,
% so that it updates the reference fig:
% (a bit of a hack):
cb = get(rx.ui.rxSlice.sliderHandle,'Callback'); 
cb = [cb(1:end-1) '([],1);'];
set(rx.ui.rxSlice.sliderHandle,'Callback',cb);
cb = get(rx.ui.rxSlice.editHandle,'Callback'); 
cb = [cb(1:end-1) '([],1);'];
set(rx.ui.rxSlice.editHandle,'Callback',cb);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% add controls to save/restore xforms     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rx.ui.storedList = uicontrol('Style','listbox',...
                             'Units','Normalized',...
                             'Position',[.01 .3 .13 .6],...
                             'String',{'(Default)'},...
                             'Min',0,'Max',1);
uicontrol('Style','text','Units','Normalized',...
          'Position',[.03 .91 .08 .06],'String','Settings:',...
          'BackgroundColor',get(gcf,'Color'));
rx.ui.store = rxMakeButton('Store',[.01 .15 .06 .12]);
set(rx.ui.store,'Style','pushbutton','Callback','rxStore;');
rx.ui.reset = rxMakeButton('Retrieve',[.01 .03 .06 .12]);
set(rx.ui.reset,'Style','pushbutton','Callback','rxReset;');
rx.ui.edit = rxMakeButton('Rename',[.07 .15 .06 .12]);
set(rx.ui.edit,'Style','pushbutton','Callback','rxEditSettings;');
rx.ui.delete = rxMakeButton('Delete',[.07 .03 .06 .12]);
set(rx.ui.delete,'Style','pushbutton','Callback','rxDeleteSettings;');
                      
%%%%%%%%%%%%%%%%%%%
% add menus       %
%%%%%%%%%%%%%%%%%%%
rx.ui.fileMenu = rxFileMenu(rx.ui.controlFig);
rx.ui.editMenu = rxEditMenu(rx.ui.controlFig);
rx.ui.viewMenu = rxViewMenu(rx.ui.controlFig);
rx.ui.analysisMenu = rxAlignmentMenu(rx.ui.controlFig);
rx.ui.windowMenu = rxWindowMenu(rx.ui.controlFig);
rx.ui.helpMenu = helpMenu;

% add rx as user data in control fig
set(rx.ui.controlFig,'UserData',rx);

rxSetNudge(rx.ui.nudge.sliderHandle);

return
