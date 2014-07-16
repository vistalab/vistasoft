function [params OK] = mrInitGUI_main(params)
% Main dialog for mrInitGUI: get input files, select additional param types to
% set.
%
% params = mrInitGUI_main(params);
%
% This dialog allows the user to specify initialization parameters for
% mrInit2. In particular, it assigns the required fields params.inplanes
% and params.functionals, with optional fields to set params.vAnatomy (reference
% volume anatomy) and params.withinSessionVolume (used for automated
% alignment -- to be implemented). This dialog also allows users to select
% additional sets of parameters they would like to set (such as crop, scan
% descriptions, or preprocessing steps).
%
%
% ras, 05/2007.
if notDefined('params'),    params = mrInitDefaultParams;       end

%% GUI update function switch
% the callbacks will call this function with special calls to sub-functions
% in lieu of a params struct. Parse this:
if ischar(params)
	switch lower(params)
		case 'addfile', mrInitGUI_main_addFile;
		case 'addfilepattern', mrInitGUI_main_addFilePattern;
		case 'removefile', mrInitGUI_main_removeFile;
		case 'moveup', mrInitGUI_main_moveUp;
		case 'movedown', mrInitGUI_main_moveDown;
		otherwise, error('Invalid argument for %s', mfilename);
	end
	return
end


% --- the code below makes the GUI --- %
%%%%% params
fsz = 10;  % fontsize for controls

% check for optional analysis params
if ~isfield(params, 'doDescription'),	params.doDescription = 1;	end
if ~isfield(params, 'doCrop'),			params.doCrop = 0;			end
if ~isfield(params, 'doAnalParams'),	params.doAnalParams = 1;	end
if ~isfield(params, 'doPreprocessing'),	params.doPreprocessing = 0;	end


%%%%% Create the main GUI figure
hFig = figure('Units', 'norm', 'Position', [.3 .2 .45 .65], ...
	'Name', 'Initialize a mrVista session', 'NumberTitle', 'off', ...
	'Color', [.9 .9 .9], 'CloseRequestFcn', 'OK = 0; uiresume;');


%% add session panel
hSession = sessionPanel(params, [0 .91 1 .09], fsz);

%% add inplane panel
hInplane = inplanePanel(params, [0 .83 1 .08], fsz);

%% add functionals panel
hFunctionals = functionalsPanel(params, [0 .43 1 .4], fsz);

%% add vAnatomy panel
hVAnatomy = vAnatomyPanel(params, [0 .35 1 .08], fsz);

%% add analysis options panel
hAnalysis = analysisPanel(params, [0 .15 1 .2], fsz);

%%%%% Add Main buttons: GO / Cancel
uicontrol('Style', 'pushbutton', 'Units', 'norm', 'Position', [.1 .02 .2 .08], ...
		  'BackgroundColor', [.9 .8 .8], 'String', 'Cancel', ...
		  'Callback', 'OK = 0; uiresume;');

uicontrol('Style', 'pushbutton', 'Units', 'norm', 'Position', [.5 .02 .2 .08], ...
		  'BackgroundColor', [.4 .8 .5], 'String', 'OK', ...
		  'Callback', 'OK = 1; uiresume;');
	  
%%%%% get the params: do a uiwait/uiresume
% (uiresume is in the callbacks for this GUI)
uiwait;


%% we uiresumed: get the updated values from the figure
OK = evalin('base', 'OK');
evalin('base', 'clear OK'); % clear from base workspace

if OK==1	
	% 'GO' button pressed: modify the parameters
	params.sessionDir = get(hSession, 'String');
	params.inplane = get(hInplane, 'String');
	params.functionals = get(hFunctionals, 'String');
	params.vAnatomy = get(hVAnatomy, 'String');
	params.doDescription = get(hAnalysis(1), 'Value');
	params.doSkipFrames = get(hAnalysis(3), 'Value');
	params.doAnalParams = get(hAnalysis(4), 'Value');
	params.doPreprocessing = get(hAnalysis(5), 'Value');	
end

delete(hFig);

return
% /------------------------------------------------------------------/ %




% /------------------------------------------------------------------/ %
function hSession = sessionPanel(params, pos, fsz)
% add a uipanel with controls for setting the session path.
% fsz = font size.
hPanel = uipanel('Units', 'norm', 'Position', pos, ...
	'BackgroundColor', [.9 .9 .9], 'ShadowColor', [.9 .9 .9], ...
	'Title', 'Session', 'FontSize', fsz+2);

%% path edit field (*main control for this panel*)
hSession = uicontrol('Parent', hPanel, 'Style', 'edit', ...
	'Units', 'norm', 'Position', [.1 .1 .6 .6], ...
	'String', params.sessionDir, ...
	'BackgroundColor', 'w', 'ForegroundColor', 'k', 'FontSize', fsz);

%% browse button
% callback
cb = ['pth = uigetdir(pwd, ''Select Session Directory''); ' ...
	 'set( get(gcbo, ''UserData''), ''String'', pth ); clear pth; '];

% control
uicontrol('Parent', hPanel, 'Units', 'norm', 'Position', [.75 .1 .15 .6], ...
	'Style', 'pushbutton', 'String', 'Browse', ...
	'BackgroundColor', [.7 .7 .7], 'ForegroundColor', 'k', 'FontSize', fsz, ...
	'UserData', hSession, 'Callback', cb);

return
% /------------------------------------------------------------------/ %




% /------------------------------------------------------------------/ %
function hInplane = inplanePanel(params, pos, fsz)
% add a uipanel with controls for setting the inplane path.
% fsz = font size..
hPanel = uipanel('Units', 'norm', 'Position', pos, ...
	'BackgroundColor', [.9 .9 .9], 'ShadowColor', [.9 .9 .9], ...
	'Title', 'Inplane Anatomy', 'FontSize', fsz+2);

%% path edit field (*main control for this panel*)
if isstruct(params.inplane)
	inplaneName = params.inplane.path;
elseif ischar(params.inplane)
	inplaneName = params.inplane;
else
	inplaneName = '';
end
hInplane = uicontrol('Parent', hPanel, 'Style', 'edit', ...
	'Units', 'norm', 'Position', [.1 .1 .6 .6], ...
	'String', inplaneName, ...
	'BackgroundColor', 'w', 'ForegroundColor', 'k', 'FontSize', fsz);

%% browse button
% callback
cb = ['pth = mrvSelectFile(''r'', [], ''Select an Inplanes File...''); ' ...
	'set( get(gcbo, ''UserData''), ''String'', pth ); clear pth; '];

% control
uicontrol('Parent', hPanel, 'Units', 'norm', 'Position', [.75 .1 .15 .6], ...
	'Style', 'pushbutton', 'String', 'Browse', ...
	'BackgroundColor', [.7 .7 .7], 'ForegroundColor', 'k', 'FontSize', fsz, ...
	'UserData', hInplane, 'Callback', cb);

return
% /------------------------------------------------------------------/ %




% /------------------------------------------------------------------/ %
function hFunctionals = functionalsPanel(params, pos, fsz)
% add a uipanel with controls for setting the input functionals.
% fsz = font size, [.7 .7 .7] = button background color.
hPanel = uipanel('Units', 'norm', 'Position', pos, ...
	'BackgroundColor', [.9 .9 .9], 'ShadowColor', [.9 .9 .9], ...
	'Title', 'Functionals', 'FontSize', fsz+2);

%% listbox with functionals list (*main control for this panel*)
hFunctionals = uicontrol('Parent', hPanel, 'Style', 'listbox', ...
	'Min', 0, 'Max', 1, ...
	'Units', 'norm', 'Position', [.1 .1 .6 .8], ...
	'String', params.functionals, ...
	'BackgroundColor', 'w', 'ForegroundColor', 'k', 'FontSize', fsz);

%% 'Add' button to add a functional file from the list
uicontrol('Parent', hPanel, 'Units', 'norm', 'Position', [.75 .8 .15 .1], ...
	'Style', 'pushbutton', 'String', 'Add...', ...
	'BackgroundColor', [.7 .7 .7], 'ForegroundColor', 'k', 'FontSize', fsz, ...
	'UserData', hFunctionals, 'Callback', 'mrInitGUI_main(''addfile'');');

%% 'Add Pattern' button to add a set of functional files specified by a
%% pattern
uicontrol('Parent', hPanel, 'Units', 'norm', 'Position', [.75 .7 .15 .1], ...
	'Style', 'pushbutton', 'String', 'Add File Pattern...', ...
	'BackgroundColor', [.7 .7 .7], 'ForegroundColor', 'k', 'FontSize', fsz, ...
	'UserData', hFunctionals, 'Callback', 'mrInitGUI_main(''addfilepattern'');');

%% 'Remove' button to remove a functional file from the list
uicontrol('Parent', hPanel, 'Units', 'norm', 'Position', [.75 .6 .15 .1], ...
	'Style', 'pushbutton', 'String', 'Remove', ...
	'BackgroundColor', [.7 .7 .7], 'ForegroundColor', 'k', 'FontSize', fsz, ...
	'UserData', hFunctionals, 'Callback', 'mrInitGUI_main(''removefile'');');

%% 'Move Up' button to change to order of scans
uicontrol('Parent', hPanel, 'Units', 'norm', 'Position', [.75 .5 .15 .1], ...
	'Style', 'pushbutton', 'String', 'Move up', ...
	'BackgroundColor', [.7 .7 .7], 'ForegroundColor', 'k', 'FontSize', fsz, ...
	'UserData', hFunctionals, 'Callback', 'mrInitGUI_main(''moveup'');');

%% 'Move Down' button to change to order of scans
uicontrol('Parent', hPanel, 'Units', 'norm', 'Position', [.75 .3 .15 .1], ...
	'Style', 'pushbutton', 'String', 'Move down', ...
	'BackgroundColor', [.7 .7 .7], 'ForegroundColor', 'k', 'FontSize', fsz, ...
	'UserData', hFunctionals, 'Callback', 'mrInitGUI_main(''movedown'');');

return
% /------------------------------------------------------------------/ %




% /------------------------------------------------------------------/ %
function hVAnatomy = vAnatomyPanel(params, pos, fsz)
% add a uipanel with controls for setting the volume anatomy path.
% fsz = font size.
hPanel = uipanel('Units', 'norm', 'Position', pos, ...
	'BackgroundColor', [.9 .9 .9], 'ShadowColor', [.9 .9 .9], ...
	'Title', 'Subject Volume Anatomy', 'FontSize', fsz+2);

%%%%% path edit field (*main control for this panel*)
hVAnatomy = uicontrol('Parent', hPanel, 'Style', 'edit', ...
	'Units', 'norm', 'Position', [.1 .1 .6 .6], ...
	'String', params.vAnatomy, ...
	'BackgroundColor', 'w', 'ForegroundColor', 'k', 'FontSize', fsz);

%%%%% browse button
% callback
cb = ['pth = mrvSelectFile(''r'', [], ''Select a Volume Anatomy...''); ' ...
	'set( get(gcbo, ''UserData''), ''String'', pth ); clear pth; '];

% control
uicontrol('Parent', hPanel, 'Units', 'norm', 'Position', [.75 .1 .15 .6], ...
	'Style', 'pushbutton', 'String', 'Browse', ...
	'BackgroundColor', [.7 .7 .7], 'ForegroundColor', 'k', 'FontSize', fsz, ...
	'UserData', hVAnatomy, 'Callback', cb);

return
% /------------------------------------------------------------------/ %




% /------------------------------------------------------------------/ %
function hAnalysis = analysisPanel(params, pos, fsz)
% add a uipanel with controls for specifying which analyses to perform.
pcolor = [.9 .9 .9];  % panel color
hPanel = uipanel('Units', 'norm', 'Position', pos, ...
	'BackgroundColor', pcolor, 'ShadowColor', pcolor, ...
	'Title', 'Initialization Options', 'FontSize', fsz+2);

% scan descriptions checkbox
hAnalysis(1) = uicontrol('Parent', hPanel, 'Style', 'checkbox', ...
	'String', 'Set Scan Descriptions', 'Value', params.doDescription,...
	'Units', 'norm', 'Position', [.05 .7 .4 .3], ...
	'BackgroundColor', pcolor, 'ForegroundColor', 'k', 'FontSize', fsz);

% skip temporal frames checkbox
hAnalysis(3) = uicontrol('Parent', hPanel, 'Style', 'checkbox', ...
	'String', 'Clip Frames from time series', 'Value', params.doCrop,...
	'Units', 'norm', 'Position', [.5 .4 .4 .3], ...
	'BackgroundColor', pcolor, 'ForegroundColor', 'k', 'FontSize', fsz);

% set analysis params checkbox
hAnalysis(4) = uicontrol('Parent', hPanel, 'Style', 'checkbox', ...
	'String', 'Set Analysis Parameters', 'Value', params.doAnalParams,...
	'Units', 'norm', 'Position', [.05 .4 .4 .3], ...
	'BackgroundColor', pcolor, 'ForegroundColor', 'k', 'FontSize', fsz);

% preprocsesing checkbox
hAnalysis(5) = uicontrol('Parent', hPanel, 'Style', 'checkbox', ...
	'String', 'Image Preprocessing', 'Value', params.doPreprocessing,...
	'Units', 'norm', 'Position', [.5 .7 .4 .3], ...
	'BackgroundColor', pcolor, 'ForegroundColor', 'k', 'FontSize', fsz);

return
% /------------------------------------------------------------------/ %




% /------------------------------------------------------------------/ %
function mrInitGUI_main_addFile
% callback to add a file to the functionals list
pth = mrvSelectFile('r', [], 'Add a functional file...'); 
hFunctionals = get(gcbo, 'UserData'); 
str = get(hFunctionals , 'String'); 
n = get(hFunctionals, 'Value'); % selected functional: add after this one
if isempty(n), n = 0; end
n = min(n, length(str));  % out-of-bounds check
str = [str(1:n); pth; str(n+1:end)]; 
set(hFunctionals, 'String', str, 'Value', n+1); 
return
% /------------------------------------------------------------------/ %




% /------------------------------------------------------------------/ %
function mrInitGUI_main_addFilePattern
% callback to add a set of files to the functionals list, using
% a file pattern (e.g, 'V*.img' for SPM-style V-files)
pth = mrvSelectFile('r', [], 'Select one of the files in the set...'); 

% try to infer the file pattern, by searching for a numeric string in the
% file name:
[p f ext] = fileparts(pth);
iNumeric = find( ismember(int16(f), 48:57) ); % ASCII vals for numbers
if ~isempty(iNumeric)
	j = iNumeric(1) - 1; % char right before 1st number
	k = iNumeric(end) + 1; % char right after last number
	j = max(j, 1);			% out-of-bounds checks
	k = min(k, length(f));
	pattern = [f(1:j) '*' f(k+1:end) ext];
else
	pattern = f;
end

% ask user to specify / confirm the file pattern
q = 'Specify the file pattern for this functional series:';
resp = inputdlg({q}, 'Add Functional Scan', 1, {pattern});
pth = fullfile(p, resp{1});

% add to functionals list
hFunctionals = get(gcbo, 'UserData'); 

% This code appears not to work. The variable str always returns as empty.
% str = get(hFunctionals , 'String'); 
% n = get(hFunctionals, 'Value'); % selected functional: add after this one
% n = min(n, length(str));  % out-of-bounds check
% str = [str(1:n); pth; str(n+1:end)]; 

% This code replaces the above lines
d = dir(pth);
% n = get(hFunctionals, 'Value'); % selected functional: add after this one
% for ii = 1:numel(d)
%     str{ii} = fullfile(fileparts(pth), d(ii).name);
% end
% set(hFunctionals, 'String', str, 'Value', n+1);

n   = get(hFunctionals, 'Value'); % selected functional: add after this one
str = get(hFunctionals , 'String'); 
len = length(str);
for ii = 1:numel(d)
    str{len+ii} = fullfile(fileparts(pth), d(ii).name);
end
set(hFunctionals, 'String', str, 'Value', n+1);


% ------------------------------------------

return
% /------------------------------------------------------------------/ %




% /------------------------------------------------------------------/ %
function mrInitGUI_main_removeFile
% callback to remove the selected file from the functionals list
hFunctionals = get(gcbo, 'UserData'); 
str = get(hFunctionals , 'String'); 
n = min(get(hFunctionals, 'Value'), length(str));  % out-of-bounds check

% new string, selection value for functionals list
str = [str(1:n-1); str(n+1:end)]; 
n = max(n-1, 1);
n = min(n, length(str));

% set it in the uicontrol
set(hFunctionals, 'String', str, 'Value', n);
return
% /------------------------------------------------------------------/ %




% /------------------------------------------------------------------/ %
function mrInitGUI_main_moveUp
% callback to move the selected file one up in the functionals list
hFunctionals = get(gcbo, 'UserData'); 
str = get(hFunctionals , 'String'); 
n = min(get(hFunctionals, 'Value'), length(str));  % out-of-bounds check

% only move the selection up if you CAN move it up (if n=1, you can't):
if n > 1
	str = [str(1:n-2); str(n); str(n-1); str(n+1:end)]; 
end

set( hFunctionals, 'String', str, 'Value', max(n-1, 1) );

return
% /------------------------------------------------------------------/ %



% /------------------------------------------------------------------/ %
function mrInitGUI_main_moveDown
% callback to move the selected file one down in the functionals list
hFunctionals = get(gcbo, 'UserData'); 
str = get(hFunctionals , 'String'); 
n = min(get(hFunctionals, 'Value'), length(str));  % out-of-bounds check

% only move the selection up if you CAN move it down (if n=max, you can't):
if n<length(str)
	str = [str(1:n-1); str(n+1); str(n); str(n+2:end)]; 
end

set( hFunctionals, 'String', str, 'Value', min(n+1, length(str)) );

return

