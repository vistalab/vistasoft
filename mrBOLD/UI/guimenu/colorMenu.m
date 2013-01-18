function vw=colorMenu(vw)
% 
% vw=colorMenu(vw)
% 
% ras 05/30/04: added option to set clip modes for each vw mode
% Importing and Exporting / AAB,  BW

cmmenu = uimenu('Label', 'Color Map', 'Separator', 'on', ...
    'ForegroundColor', [0.0 0.0 1.0]);

% Reset Defaults callback:
%  vw=resetDisplayModes(vw);
%  vw=refreshScreen(vw);
cb=[vw.name ' = resetDisplayModes(', vw.name, '); ', ...
	vw.name ' = setPhWindow(' vw.name ', [0 2*pi]); ', ...
	vw.name ' = refreshScreen(', vw.name, ');'];
uimenu(cmmenu, 'Label', 'Reset Defaults', 'Separator', 'off', ...
    'CallBack', cb);
 
rotateSubmenu(vw,  cmmenu);
coModeSubmenu(vw,  cmmenu);
ampModeSubmenu(vw,  cmmenu);
phModeSubmenu(vw,  cmmenu);
mapModeSubmenu(vw,  cmmenu);

phprojMenu = uimenu(cmmenu, 'Label', 'Phase Projected...', 'Separator', 'on');
     coModeSubmenu(vw,  phprojMenu,  'cor');
    ampModeSubmenu(vw,  phprojMenu,  'projamp');
utilitySubmenu(vw,  cmmenu);
visualFieldSubmenu(vw,  cmmenu);


if isequal(vw.viewType, 'Flat')
    uimenu(cmmenu, 'Label',  'Threshold Curvature', 'Separator', 'off', ...
	'CallBack', sprintf('%s = thresholdAnatMap(%s); ', vw.name, vw.name));
end


return;
% /--------------------------------------------------------------------/ %




% /--------------------------------------------------------------------/ %
function vw = rotateSubmenu(vw,  cmmenu)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Rotate cmap submenu
rotateMenu = uimenu(cmmenu, 'Label', 'Rotate/Flip', 'Separator', 'off');
 
cb=[vw.name, '=flipCmap(', vw.name, '); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(rotateMenu, 'Label', 'Flip', 'Separator', 'off', ...
    'CallBack', cb);



cb=[vw.name, '=rotateCmap(', vw.name, '); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(rotateMenu, 'Label', 'Rotate/Flip Using GUI', 'Separator', 'off', ...
    'CallBack', cb);

% Rotate callback:
%  vw=rotateCmap(vw, [amount]);
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '=rotateCmap(', vw.name, ',  -45); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(rotateMenu, 'Label', 'Left 45 degrees', 'Separator', 'off', ...
    'CallBack', cb);

cb=[vw.name, '=rotateCmap(', vw.name, ',  -90); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(rotateMenu, 'Label', 'Left 90 degrees', 'Separator', 'off', ...
    'CallBack', cb);

cb=[vw.name, '=rotateCmap(', vw.name, ',  90); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(rotateMenu, 'Label', 'Right 90 degrees', 'Separator', 'off', ...
    'CallBack', cb);

cb=[vw.name, '=rotateCmap(', vw.name, ',  180); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(rotateMenu, 'Label', '180 degrees', 'Separator', 'off', ...
    'CallBack', cb);

return
% /--------------------------------------------------------------------/ %




% /--------------------------------------------------------------------/ %
function vw = coModeSubmenu(vw,  cmmenu,  tag)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Coherence/Correlation Mode submenu: exactly same menu

% tag: coherence 'co' or correlation 'cor'
if ~exist('tag', 'var'); tag = 'co'; end;
    
if strcmpi(tag, 'co');
    comenu = uimenu(cmmenu, 'Label', 'Coherence Mode', 'Separator', 'off');
else
    comenu = uimenu(cmmenu, 'Label', 'Correlation Mode', 'Separator', 'off');
end

% redGreen callback:
%  vw.ui.coMode=setColormap(vw.ui.coMode, 'redGreenCmap');
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '.ui.', tag, 'Mode=setColormap(', ...
	vw.name, '.ui.', tag, 'Mode, ''redGreenCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(comenu, 'Label', 'Red-Green Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% hot callback:
%  vw.ui.coMode=setColormap(vw.ui.coMode, 'hotCmap');
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '.ui.', tag, 'Mode=setColormap(', ...
	vw.name, '.ui.', tag, 'Mode, ''hotCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(comenu, 'Label', 'Hot Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% cool callback:
%  vw.ui.coMode=setColormap(vw.ui.coMode, 'coolCmap');
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '.ui.', tag, 'Mode=setColormap(', ...
	vw.name, '.ui.', tag, 'Mode, ''coolCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(comenu, 'Label', 'Cool Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% cool_hot callback:
%  vw.ui.coMode=setColormap(vw.ui.coMode, 'cool_hotCmap');
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '.ui.', tag, 'Mode=setColormap(', ...
	vw.name, '.ui.', tag, 'Mode, ''cool_hotCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(comenu, 'Label', 'Cool <-> Hot Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% cool_spring callback:
%  vw.ui.coMode=setColormap(vw.ui.coMode, 'cool_springCmap');
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '.ui.', tag, 'Mode=setColormap(', ...
	vw.name, '.ui.', tag, 'Mode, ''cool_springCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(comenu, 'Label', 'Cool <-> Hot Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% jet callback:
%  vw.ui.coMode=setColormap(vw.ui.coMode, 'jetCmap');
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '.ui.', tag, 'Mode=setColormap(', vw.name, '.ui.', tag, 'Mode, ''jetCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(comenu, 'Label', 'Jet Colormap', 'Separator', 'off', ...
    'CallBack', cb);
cb=[vw.name, '.ui.', tag, 'Mode=setColormap(', vw.name, '.ui.', tag, 'Mode, ''revjetCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(comenu, 'Label', 'Reversed Jet Colormap', 'Separator', 'off', ...
    'CallBack', cb);

cb=[vw.name, '.ui.', tag, 'Mode=setColormap(', vw.name, '.ui.', tag, 'Mode, ''redBlueCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(comenu, 'Label', 'Blue <-> Red Colormap', 'Separator', 'off', ...
    'CallBack', cb);

%edit colormap callback:
% vw.ui.coMode.cmap = editCmap(vw.ui.coMode);
% vw.ui.coMode.name=inputdlg('Please Name Color Map','Color map',1,{'custom'});
% vw=refreshScreen(vw,1);
cb = [vw.name,'.ui.',tag,'Mode.cmap=editCmap('...
    vw.name,'.ui.',tag,'Mode);',...
    vw.name,'.ui.',tag,'Mode.name=inputdlg(''Please Name Color'...
    'Map'',''Color Map'',1,{''custom''});'...
    vw.name,'=refreshScreen(',vw.name,',1);'];
uimenu(comenu,'Label','Edit Colormap','Separator','on',...
    'CallBack',cb);

% auto clip mode callback:
%  vw = setClipMode(vw, 'co', 'auto');
%  vw=refreshScreen(vw, 1);
cbstr = sprintf(['%s = setClipMode(%s, ''', tag, ''', ''auto'');'], vw.name, vw.name);
cbstr = sprintf('%s\n%s = refreshScreen(%s, 1);', cbstr, vw.name, vw.name);
uimenu(comenu, 'Label', 'Auto Clip Mode', 'Separator', 'on', ...
    'CallBack', cbstr);

% manual clip mode callback:
%  vw = setClipMode(vw, 'co');
%  vw=refreshScreen(vw, 1);
cbstr = sprintf(['%s = setClipMode(%s, ''', tag, ''');'], vw.name, vw.name);
cbstr = sprintf('%s\n%s = refreshScreen(%s, 1);', cbstr, vw.name, vw.name);
uimenu(comenu, 'Label', 'Manual Clip Mode', 'Separator', 'off', ...
    'CallBack', cbstr);


return
% /--------------------------------------------------------------------/ %




% /--------------------------------------------------------------------/ %
function vw = ampModeSubmenu(vw,  cmmenu,  tag)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Amplitude / Projected Amplitude Mode submenu: exactly same menu

% tag: amplitude 'amp' or projected amplitude 'projamp'
if ~exist('tag', 'var'); tag = 'amp'; end;

if strcmpi(tag, 'amp');
    ampmenu = uimenu(cmmenu, 'Label', 'Amplitude Mode', 'Separator', 'off');
else
    ampmenu = uimenu(cmmenu, 'Label', 'Projected Amp Mode', 'Separator', 'off');
end

% redGreen callback:
%  vw.ui.ampMode=setColormap(vw.ui.ampMode, 'redGreenCmap');
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '.ui.', tag, 'Mode=setColormap(', ...
	vw.name, '.ui.', tag, 'Mode, ''redGreenCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(ampmenu, 'Label', 'Red-Green Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% hot callback:
%  vw.ui.ampMode=setColormap(vw.ui.ampMode, 'hotCmap');
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '.ui.', tag, 'Mode=setColormap(', ...
	vw.name, '.ui.', tag, 'Mode, ''hotCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(ampmenu, 'Label', 'Hot Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% cool callback:
%  vw.ui.ampMode=setColormap(vw.ui.ampMode, 'coolCmap');
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '.ui.', tag, 'Mode=setColormap(', ...
	vw.name, '.ui.', tag, 'Mode, ''coolCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(ampmenu, 'Label', 'Cool Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% cool_hot callback:
%  vw.ui.ampMode=setColormap(vw.ui.ampMode, 'cool_hotCmap');
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '.ui.', tag, 'Mode=setColormap(', ...
	vw.name, '.ui.', tag, 'Mode, ''cool_hotCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(ampmenu, 'Label', 'Cool <-> Hot Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% HSV callback:
%  vw.ui.mapMode = setColormap(vw.ui.mapMode,  'hsvCmap');
%  vw = refreshScreen(vw, 1);
cb=[vw.name, '.ui.', tag, 'Mode=setColormap(', ...
	vw.name, '.ui.', tag, 'Mode, ''hsvTbCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(ampmenu,  'Label',  'HSV (Rainbow - untill blue only) Colormap',  'Separator',  'off',  ...
       'Callback',  cb);

% jet callback:
%  vw.ui.ampMode=setColormap(vw.ui.ampMode, 'jetCmap');
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '.ui.', tag, 'Mode=setColormap(', ...
	vw.name, '.ui.', tag, 'Mode, ''jetCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(ampmenu, 'Label', 'Jet Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% HSV callback:
%  vw.ui.ampMode=setColormap(vw.ui.ampMode,'hsvCmap');
%  vw=refreshScreen(vw,1);
cb=[vw.name,'.ui.',tag,'Mode=setColormap(',...
	vw.name,'.ui.',tag,'Mode,''hsvCmap''); ',...
	vw.name,'=refreshScreen(',vw.name,',1);'];
uimenu(ampmenu,'Label','HSV Colormap','Separator','off',...
    'CallBack',cb);

%edit colormap callback:
% vw.ui.ampMode.cmap = editCmap(vw.ui.ampMode);
% vw.ui.ampMode.name=inputdlg('Please Name Color Map','Color map',1,{'custom'});
% vw=refreshScreen(vw,1);
cb = [vw.name,'.ui.',tag,'Mode.cmap=editCmap('...
    vw.name,'.ui.',tag,'Mode);',...
    vw.name,'.ui.',tag,'Mode.name=inputdlg(''Please Name Color'...
    'Map'',''Color Map'',1,{''custom''});'...
    vw.name,'=refreshScreen(',vw.name,',1);'];
uimenu(ampmenu,'Label','Edit Colormap','Separator','on',...
    'CallBack',cb);

% auto clip mode callback:
%  vw = setClipMode(vw, 'co', 'auto');
%  vw=refreshScreen(vw, 1);
cbstr = sprintf(['%s = setClipMode(%s, ''', tag, ''', ''auto'');'], vw.name, vw.name);
cbstr = sprintf('%s\n%s = refreshScreen(%s, 1);', cbstr, vw.name, vw.name);
uimenu(ampmenu, 'Label', 'Auto Clip Mode', 'Separator', 'on', ...
    'CallBack', cbstr);

% manual clip mode callback:
%  vw = setClipMode(vw, 'co');
%  vw=refreshScreen(vw, 1);
cbstr = sprintf(['%s = setClipMode(%s, ''', tag, ''');'], vw.name, vw.name);
cbstr = sprintf('%s\n%s = refreshScreen(%s, 1);', cbstr, vw.name, vw.name);
uimenu(ampmenu, 'Label', 'Manual Clip Mode', 'Separator', 'off', ...
    'CallBack', cbstr);


return
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function vw = phModeSubmenu(vw,  cmmenu)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Phase Mode submenu

phmenu = uimenu(cmmenu, 'Label', 'Phase Mode', 'Separator', 'off');

cb = [vw.name, ...
        '=cmapImportModeInformation(', vw.name, ', ''phMode''', ', ''WedgeMapLeft.mat'');'...
        vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(phmenu, 'Label', 'Wedge map (left)', 'Separator', 'off', ...
    'CallBack', cb);

cb = [vw.name, '=cmapImportModeInformation(', vw.name, ', ''phMode''', ', ''WedgeMapRight.mat'');'...
        vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(phmenu, 'Label', 'Wedge map (right)', 'Separator', 'off', ...
    'CallBack', cb);

cb = [vw.name, ...
        '=cmapImportModeInformation(', vw.name, ', ''phMode''', ', ''WedgeMapLeft_pRF.mat'');'...
        vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(phmenu, 'Label', 'Wedge map for pRF (left)', 'Separator', 'off', ...
    'CallBack', cb);

cb = [vw.name, '=cmapImportModeInformation(', vw.name, ', ''phMode''', ', ''WedgeMapRight_pRF.mat'');'...
        vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(phmenu, 'Label', 'Wedge map for pRF (right)', 'Separator', 'off', ...
    'CallBack', cb);

% ***********************************************************************
cb = [vw.name, ...
        '=cmapSetLumColorPhaseMap(', vw.name, ', ''left'');'...
        vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(phmenu, 'Label', 'Luminance Modulated angle map for pRF (left)', 'Separator', 'off', ...
    'CallBack', cb);

cb = [vw.name,...
        '=cmapSetLumColorPhaseMap(', vw.name, ', ''right'');'...
        vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(phmenu, 'Label', 'Luminance Modulated angle map for pRF (right)', 'Separator', 'off', ...
    'CallBack', cb);
% **********************************************************************

cb = [vw.name, '=cmapImportModeInformation(', vw.name, ', ''phMode''', ', ''RingMapE.mat'');'...
        vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(phmenu, 'Label', 'Ring map (expanding)', 'Separator', 'off', ...
    'CallBack', cb);

cb = [vw.name, '=cmapImportModeInformation(', vw.name, ', ''phMode''', ', ''RingMapC.mat'');'...
        vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(phmenu, 'Label', 'Ring map (contracting)', 'Separator', 'off', ...
    'CallBack', cb);

% HSV callback:
%  vw.ui.phMode=setColormap(vw.ui.phMode, 'hsvCmap');
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '.ui.phMode=setColormap(', ...
	vw.name, '.ui.phMode, ''hsvCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(phmenu, 'Label', 'HSV Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% Extended color map callback:
% VOLUME{2}=cmapExtended(VOLUME{2});%
% VOLUME{2}=refreshScreen(VOLUME{2}, 1);
%
cb= ...
    [vw.name, '=cmapExtended(', vw.name, '); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(phmenu, 'Label', 'Extended Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% RYGB callback:
%  vw.ui.phMode=setColormap(vw.ui.phMode, 'rygbCmap');
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '.ui.phMode=setColormap(', ...
	vw.name, '.ui.phMode, ''rygbCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(phmenu, 'Label', 'RYGB Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% RedGreenBlue cmap (ras, 10/06)
cb = [sprintf('%s = cmapRedgreenblue(%s, ''ph'', 2); ', vw.name, vw.name) ...
	  sprintf('%s = refreshScreen(%s); ', vw.name, vw.name)];
uimenu(phmenu, 'Label', 'Redgreenblue Colormap (full range)', ...
               'Separator', 'off', 'CallBack', cb);

cb = [sprintf('%s = cmapRedgreenblue(%s, ''ph'', 0); ', vw.name, vw.name) ...
	  sprintf('%s = refreshScreen(%s); ', vw.name, vw.name)];
uimenu(phmenu, 'Label', 'Redgreenblue Colormap (half range)', ...
               'Separator', 'off', 'CallBack', cb);

cb = [sprintf('%s = cmapRedgreenblue(%s, ''ph'', 1); ', vw.name, vw.name) ...
	  sprintf('%s = refreshScreen(%s); ', vw.name, vw.name)];
uimenu(phmenu, 'Label', 'Redgreenblue Colormap (4 color bands)', ...
               'Separator', 'off', 'CallBack', cb);
           
% blueyellow cmap		   
cb = [vw.name, '.ui.phMode=setColormap(', ...
	  vw.name, '.ui.phMode, ''blueyellowCmap''); ', ...
	  vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(phmenu, 'Label', 'Blue->Yellow Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% blueredyellow cmap		   
cb = [vw.name, '.ui.phMode=setColormap(', ...
	  vw.name, '.ui.phMode, ''blueredyellowCmap''); ', ...
	  vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(phmenu, 'Label', 'Blue->Red->Yellow Colormap', 'Separator', 'off', ...
    'CallBack', cb);


% Jet callback:
%  vw.ui.phMode=setColormap(vw.ui.phMode, 'jetCmap');
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '.ui.phMode=setColormap(', ...
	vw.name, '.ui.phMode, ''jetCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(phmenu, 'Label', 'Jet Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% Jet callback:
%  vw.ui.phMode=setColormap(vw.ui.phMode, 'hotCmap');
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '.ui.phMode=setColormap(', ...
	vw.name, '.ui.phMode, ''hotCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(phmenu, 'Label', 'Hot Colormap', 'Separator', 'off', ...
    'CallBack', cb);


% Linearize callback:
%  vw=linearizeCmap(vw);
%  vw=refreshScreen(vw, 1);
cb= [vw.name, '=linearizeCmap(', vw.name, '); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(phmenu, 'Label', 'Linearize HSV', 'Separator', 'off', ...
    'CallBack', cb);

%edit colormap callback:
% vw.ui.phMode.cmap = editCmap(vw.ui.phMode);
% vw.ui.phMode.name=inputdlg('Please Name Color Map','Color map',1,{'custom'});
% vw=refreshScreen(vw,1);
cb = [vw.name,'.ui.phMode.cmap=editCmap('...
    vw.name,'.ui.phMode);',...
    vw.name,'.ui.phMode.name=inputdlg(''Please Name Color'...
    'Map'',''Color Map'',1,{''custom''});'...
    vw.name,'=refreshScreen(',vw.name,',1);'];
uimenu(phmenu,'Label','Edit Colormap','Separator','on',...
    'CallBack',cb);

% auto clip mode callback:
%  vw = setClipMode(vw, 'co', 'auto');
%  vw=refreshScreen(vw, 1);
cbstr = sprintf('%s = setClipMode(%s, ''ph'', ''auto'');', vw.name, vw.name);
cbstr = sprintf('%s\n%s = refreshScreen(%s, 1);', cbstr, vw.name, vw.name);
uimenu(phmenu, 'Label', 'Auto Clip Mode', 'Separator', 'on', ...
    'CallBack', cbstr);

% manual clip mode callback:
%  vw = setClipMode(vw, 'co');
%  vw=refreshScreen(vw, 1);
cbstr = sprintf('%s = setClipMode(%s, ''ph'');', vw.name, vw.name);
cbstr = sprintf('%s\n%s = refreshScreen(%s, 1);', cbstr, vw.name, vw.name);
uimenu(phmenu, 'Label', 'Manual Clip Mode', 'Separator', 'off', ...
    'CallBack', cbstr);


return
% /--------------------------------------------------------------------/ %




% /--------------------------------------------------------------------/ %
function vw = mapModeSubmenu(vw,  cmmenu)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parameter map Mode submenu
mapmenu = uimenu(cmmenu, 'Label', 'Parameter Map Mode', 'Separator', 'off');

%% ras 06/07: putting two options at the top of this submenu:
% (1) New dialog to edit map name / units / clip mode
% (2) Remus' Cmap edit submenu

% edit map name/units menu:
cb = sprintf('%s = viewSet(%s, ''MapName'', ''Dialog''); ', ...
			 vw.name, vw.name);
uimenu(mapmenu, 'Label', 'Edit Map Name / Units', 'Separator','off',...
		'CallBack', cb);

% edit colormap callback:
%  vw.ui.mapMode.cmap = editCmap(vw.ui.mapMode);
%  vw.ui.mapMode.name=inputdlg('Please Name Color Map','Color map',1,{'custom'});
%  vw=refreshScreen(vw,1);
cb = [vw.name,'.ui.mapMode.cmap=editCmap('...
    vw.name,'.ui.mapMode);',...
    vw.name,'.ui.mapMode.name=inputdlg(''Please Name Color'...
    'Map'',''Color Map'',1,{''custom''});'...
    vw.name,'=refreshScreen(',vw.name,',1);'];
uimenu(mapmenu, 'Label', 'Edit Colormap', 'Separator', 'off',...
		'CallBack', cb);


% gray callback:
%  vw.ui.mapMode=setColormap(vw.ui.mapMode, 'redGreenCmap');
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '.ui.mapMode=setColormap(', ...
	vw.name, '.ui.mapMode, ''grayColorCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(mapmenu, 'Label', 'Gray (anat-like) Colormap', 'Separator', 'on', ...
    'CallBack', cb);

% redGreen callback:
%  vw.ui.mapMode=setColormap(vw.ui.mapMode, 'redGreenCmap');
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '.ui.mapMode=setColormap(', ...
	vw.name, '.ui.mapMode, ''redGreenCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(mapmenu, 'Label', 'Red-Green Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% hot callback:
%  vw.ui.mapMode=setColormap(vw.ui.mapMode, 'hotCmap');
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '.ui.mapMode=setColormap(', ...
	vw.name, '.ui.mapMode, ''hotCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(mapmenu, 'Label', 'Hot Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% cool callback:
%  vw.ui.mapMode=setColormap(vw.ui.mapMode, 'coolCmap');
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '.ui.mapMode=setColormap(', ...
	vw.name, '.ui.mapMode, ''coolCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(mapmenu, 'Label', 'Cool Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% cool_spring callback:
%  vw.ui.mapMode=setColormap(vw.ui.mapMode, 'cool_springCmap');
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '.ui.mapMode=setColormap(', ...
	vw.name, '.ui.mapMode, ''cool_springCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(mapmenu, 'Label', 'Cool_spring Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% HSV callback:
%  vw.ui.mapMode = setColormap(vw.ui.mapMode,  'hsvCmap');
%  vw = refreshScreen(vw, 1);
cb=[vw.name, '.ui.mapMode=setColormap(', ...
	vw.name, '.ui.mapMode, ''hsvCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(mapmenu,  'Label',  'HSV (Rainbow) Colormap',  'Separator',  'off',  ...
       'Callback',  cb);

% Linearize callback:
%  vw=linearizeCmap(vw);
%  vw=refreshScreen(vw, 1);
cb= [vw.name, '=linearizeCmap(', vw.name, '); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(mapmenu, 'Label', 'Linearize HSV', 'Separator', 'off', ...
    'CallBack', cb);


% HSV callback:
%  vw.ui.mapMode = setColormap(vw.ui.mapMode,  'hsvCmap');
%  vw = refreshScreen(vw, 1);
cb=[vw.name, '.ui.mapMode=setColormap(', ...
	vw.name, '.ui.mapMode, ''hsvTbCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(mapmenu,  'Label',  'HSV (Rainbow - untill blue only) Colormap',  'Separator',  'off',  ...
       'Callback',  cb);


% jet callback:
%  vw.ui.mapMode=setColormap(vw.ui.mapMode, 'jetCmap');
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '.ui.mapMode=setColormap(', ...
	vw.name, '.ui.mapMode, ''jetCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(mapmenu,  'Label',  'Jet Colormap',  'Separator',  'off', ...
        'CallBack',  cb);

% reversed jet:
cb=[vw.name, '.ui.mapMode=setColormap(', vw.name, '.ui.mapMode, ''revjetCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(mapmenu, 'Label', 'Reversed Jet Colormap', 'Separator', 'off', ...
    'CallBack', cb);    
    
% blueyellow callback:
%  vw.ui.mapMode=setColormap(vw.ui.mapMode, 'jetCmap');
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '.ui.mapMode=setColormap(', ...
	vw.name, '.ui.mapMode, ''blueyellowCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(mapmenu,  'Label',  'Blueyellow Colormap',  'Separator',  'off', ...
        'CallBack',  cb);

% blueredyellow callback:
%  vw.ui.mapMode=setColormap(vw.ui.mapMode, 'jetCmap');
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '.ui.mapMode=setColormap(', ...
	vw.name, '.ui.mapMode, ''blueredyellowCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(mapmenu,  'Label',  'Blueredyellow Colormap',  'Separator',  'off', ...
        'CallBack',  cb);

% bluegreenyellow callback:
%  vw.ui.mapMode=setColormap(vw.ui.mapMode, 'jetCmap');
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '.ui.mapMode=setColormap(', ...
	vw.name, '.ui.mapMode, ''bluegreenyellowCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(mapmenu,  'Label',  'Bluegreenyellow Colormap',  'Separator',  'off', ...
        'CallBack',  cb);

% Autumn callback:
%  vw = bicolorCmap(vw);
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '.ui.mapMode=setColormap(', ...
	vw.name, '.ui.mapMode, ''autumnCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(mapmenu, 'Label', 'Autumn Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% Winter callback:
%  vw = bicolorCmap(vw);
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '.ui.mapMode=setColormap(', ...
	vw.name, '.ui.mapMode, ''winterCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(mapmenu, 'Label', 'Winter Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% Bicolor callback:
%  vw = bicolorCmap(vw);
%  vw=refreshScreen(vw, 1);
cb=[vw.name, '.ui.mapMode=setColormap(', ...
	vw.name, '.ui.mapMode, ''coolhotCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(mapmenu, 'Label', 'Bicolor (cool + hot, black centered) Colormap', ...
    'Separator', 'off', 'CallBack', cb);

cb=[vw.name, '.ui.mapMode=setColormap(', ...
	vw.name, '.ui.mapMode, ''coolhotGrayCmap''); ', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(mapmenu, 'Label', 'Bicolor (cool + hot, gray centered) Colormap', ...
    'Separator', 'off', 'CallBack', cb);

cb = sprintf('%s = bicolorCmap(%s); ', vw.name, vw.name);
cb = [cb sprintf('%s = refreshScreen(%s, 1);', vw.name, vw.name)];
uimenu(mapmenu, 'Label', 'Bicolor (Winter+Autumn) Colormap', ...
    'Separator', 'off', 'CallBack', cb);

% Overlap Cmap menu options:
cb = sprintf('cmapOverlap(%s,  {''r'' ''g'' ''y''}); ',  vw.name);
uimenu(mapmenu, 'Label', 'Overlap (Red/Green/Yellow) Colormap', ...
    'Separator', 'off', 'CallBack', cb);

cb = sprintf('cmapOverlap(%s,  {''r'' ''b'' ''m''}); ',  vw.name);
uimenu(mapmenu, 'Label', 'Overlap (Red/Blue/Purple) Colormap', ...
    'Separator', 'off', 'CallBack', cb);

% auto clip mode callback:
%  vw = setClipMode(vw, 'co', 'auto');
%  vw=refreshScreen(vw, 1);
cbstr = sprintf('%s = setClipMode(%s, ''map'', ''auto'');', vw.name, vw.name);
cbstr = sprintf('%s\n%s = refreshScreen(%s, 1);', cbstr, vw.name, vw.name);
uimenu(mapmenu, 'Label', 'Auto Clip Mode', 'Separator', 'on', ...
    'CallBack', cbstr);

% manual clip mode callback:
%  vw = setClipMode(vw, 'co');
%  vw=refreshScreen(vw, 1);
cbstr = sprintf('%s = setClipMode(%s, ''map'');', vw.name, vw.name);
cbstr = sprintf('%s\n%s = refreshScreen(%s, 1);', cbstr, vw.name, vw.name);
uimenu(mapmenu, 'Label', 'Manual Clip Mode', 'Separator', 'off', ...
    'CallBack', cbstr);


return
% /--------------------------------------------------------------------/ %




% /--------------------------------------------------------------------/ %
function vw = visualFieldSubmenu(vw,  cmmenu)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Assign Visual Field Map Parameters submenu:
retinoMapMenu = uimenu(cmmenu,  'Label',  'Set Retinotopy Parameters...',  ...
                        'Separator',  'off');

% submenus for assigning visual field map params
% retinoSetParams(vw);
cb = sprintf('retinoSetParams(%s); ',  vw.name);
uimenu(retinoMapMenu,  'Label',  'Current Scan',  'Callback',  cb);

% scans = er_selectScans(vw); retinoSetParams(vw,  [],  scans); 
cb = [sprintf('scans = er_selectScans(%s); ',  vw.name) ...
      sprintf('retinoSetParams(%s,  [],  scans); ',  vw.name)];
uimenu(retinoMapMenu,  'Label',  'Select Scans',  'Callback',  cb);

% retinoSetParams(vw,  [],  1:numScans(vw));
cb = sprintf('retinoSetParams(%s,  [],  1:numScans(%s)); ',  ...
               vw.name,  vw.name);
uimenu(retinoMapMenu,  'Label',  'All Scans',  'Callback',  cb);

% submenus for removing visual field map params
% retinoSetParams(vw,  [],  [],  'none');
cb = sprintf('retinoSetParams(%s,  [],  [],  ''none''); ',  vw.name);
uimenu(retinoMapMenu,  'Label',  'Un-set Params (Current Scan)',  ...
       'Separator',  'on',  'Callback',  cb);

% scans = er_selectScans(vw); retinoSetParams(vw,  [],  scans,  'none'); 
cb = [sprintf('scans = er_selectScans(%s); ',  vw.name) ...
      sprintf('retinoSetParams(%s,  [],  scans,  ''none''); ',  vw.name)];
uimenu(retinoMapMenu,  'Label',  'Un-set Params (Select Scans)',  ...
    'Callback',  cb);

% retinoSetParams(vw,  [],  1:numScans(vw),  'none');
cb = sprintf('retinoSetParams(%s,  [],  1:numScans(%s),  ''none''); ',  ...
               vw.name,  vw.name);
uimenu(retinoMapMenu,  'Label',  'Un-set Params (All Scans)',  ...
    'Callback',  cb);

%% some pre-set cmaps which may be useful (but which explicitly 
%% depend on having set retinoParams):

% polar angle, RGB, left visual field
cb = [sprintf('%s = cmapPolarAngleRGB(%s, ''left''); \n', vw.name, vw.name) ...
      sprintf('%s = refreshScreen(%s); ', vw.name, vw.name)];
uimenu(retinoMapMenu,  'Label',  'Left Visual Field Colorwheel',  ...
    'Separator', 'on', 'Callback', cb);

% polar angle, RGB, left visual field
cb = [sprintf('%s = cmapPolarAngleRGB(%s, ''right''); \n', vw.name, vw.name) ...
      sprintf('%s = refreshScreen(%s); ', vw.name, vw.name)];
uimenu(retinoMapMenu,  'Label',  'Right Visual Field Colorwheel',  ...
    'Callback', cb);


return
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function vw = utilitySubmenu(vw,  cmmenu)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% utility mode

utilitymenu = uimenu(cmmenu, 'Label', 'Utilities', 'Separator', 'on');

% copy colorbar to clipboard
cb = sprintf('cbarCopy(%s, ''clipboard'');',  vw.name);
uimenu(utilitymenu,  'Label',  'Copy Color bar to Clipboard',  ...
        'Separator',  'off',  'Callback',  cb);

% copy colorbar to figure
cb = sprintf('cbarCopy(%s, ''figure'');',  vw.name);
uimenu(utilitymenu,  'Label',  'Copy Color bar to Figure',  ...
        'Separator',  'off',  'Callback',  cb);

cb = sprintf('loadColormap(%s);',  vw.name);
uimenu(utilitymenu,  'Label',  'Load Colormap From File',  ...
        'Separator',  'on',  'Callback',  cb);

cb = [vw.name, '=cmapImportModeInformation(', vw.name, ');'];
uimenu(utilitymenu, 'Label', 'Import Map', 'Separator', 'off', ...
        'CallBack',  cb);

cb = ['cmapExportModeInformation(', vw.name, ');'];
uimenu(utilitymenu,  'Label',  'Export Map',  'Separator',  'off', ...
        'CallBack',  cb);

% Rotate the color map so that a particular data phase has the chosen color:
%  vw = =cmapSetDataPhase(vw);
%  vw = refreshScreen(vw, 1);
cb=[vw.name, '=cmapSetDataPhase(', vw.name, ');', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(utilitymenu, 'Label', 'Set Phase Manually...', 'Separator', 'off', ...
    'CallBack', cb);

% Rotate the color map so that a particular data phase has the chosen color:
%  vw = cmapSetConstantSubmap(vw);
%  vw = refreshScreen(vw, 1);
cb=[vw.name, '=cmapSetConstantSubmap(', vw.name, ');', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(utilitymenu, 'Label', 'Set Map Region Gray...', 'Separator', 'off', ...
    'CallBack', cb);
cb=[vw.name, '=cmapSetConstantSubmap(', vw.name, ', [], ''a'');', ...
	vw.name, '=refreshScreen(', vw.name, ', 1);'];
uimenu(utilitymenu, 'Label', 'Set Map Region Gray by Input', 'Separator', 'off', ...
    'CallBack', cb);

% cmapRing(FLAT{1}, fovealPhase, 'b', 256, 1);
cb= ['cmapRing(', vw.name, ', [], ''b'', 256, 1);'];
uimenu(utilitymenu, 'Label', 'Ring map legend', 'Separator', 'off', ...
    'CallBack', cb);

cb= ['cmapWedge(', vw.name, ');'];
uimenu(utilitymenu, 'Label', 'Wedge map legend', 'Separator', 'off', ...
    'CallBack', cb);



return
% /--------------------------------------------------------------------/ %
