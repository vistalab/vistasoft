function params = mrInitGUI_description(params, varargin);
% Scan Description dialog for mrInitGUI.
%
% params = mrInitGUI_description(params);
%
% This code allows you to edit the params.description and 
% params.annotations fields of mrInit2 params. (See mrInitDefaultParams
% for more details). The GUI will have one row of uicontrols for
% each functional scan in the session. Separate columns
%
%
% ras, 05/2007
if notDefined('params'),    params = mrInitDefaultParams;       end


%%%%% params
fsz = 10;  % fontsize for controls
nScans = length(params.functionals);
height = 24 + 2*nScans;  % height in characters of GUI figure
width = 140;		 % width in characters of GUI figure


%%%%%%%%%%%%%%%%%%%%%
% create the figure %
%%%%%%%%%%%%%%%%%%%%%
hFig = figure('Units', 'char', 'Position', [10 5 width height], ...
	'Name', 'mrVista Session Description', 'NumberTitle', 'off', ...
	'UserData', params, ...
	'Color', [.9 .9 .9], 'CloseRequestFcn', 'OK = 0; uiresume;');
centerfig(hFig, 0);  % center on screen

%% add a session description edit field
uicontrol('Style', 'text', 'Units', 'char', 'Position', [2 height-3 30 2], ...
		  'String', 'Session Description', 'FontSize', fsz, ...
		  'FontWeight', 'bold', ...
		  'BackgroundColor', [.9 .9 .9]);
	  
hDescription = uicontrol('Style', 'edit', 'String', params.description, ...
		'Units', 'char', 'Position', [30 height-3 width-40 2], ...
		'HorizontalAlignment', 'left', ...
		'FontSize', fsz, 'BackgroundColor', 'w', 'ForegroundColor', 'k');

%% add a subject edit field
uicontrol('Style', 'text', 'Units', 'char', 'Position', [2 height-6 30 2], ...
		  'String', 'Subject', 'FontSize', fsz, ...
		  'FontWeight', 'bold', ...
		  'BackgroundColor', [.9 .9 .9]);
	  
hSubject = uicontrol('Style', 'edit', 'String', params.subject, ...
		'Units', 'char', 'Position', [30 height-6 width-40 2], ...
		'HorizontalAlignment', 'left', ...
		'FontSize', fsz, 'BackgroundColor', 'w', 'ForegroundColor', 'k');
	
%% add a row of text labels for the headings
% scan #
uicontrol('Style', 'text', 'Units', 'char', 'Position', [2 height-10 7 2], ...
		  'FontWeight', 'bold','HorizontalAlignment', 'center', ...
		  'String', 'Scan', 'FontSize', fsz+2, ...
		  'BackgroundColor', [.9 .9 .9]);
	  
% input file name  
uicontrol('Style', 'text', 'Units', 'char', 'Position', [10 height-10 28 2], ...
		  'FontWeight', 'bold', 'HorizontalAlignment', 'center', ...
		  'String', 'File', 'FontSize', fsz+2, ...
		  'BackgroundColor', [.9 .9 .9]);
	  
% description
uicontrol('Style', 'text', 'Units', 'char', 'Position', [40 height-10 100 2], ...
		  'FontWeight', 'bold', 'HorizontalAlignment', 'center', ...
		  'String', 'Description', 'FontSize', fsz+2, ...
		  'BackgroundColor', [.9 .9 .9]);

%% add each row of controls
for scan = 1:nScans
	hFunctionals(scan) = annotationRow(params, scan, fsz, height-10-2*scan);
end

%% add a coments description field
uicontrol('Style', 'text', 'Units', 'char', 'Position', [2 5 30 2], ...
		  'String', 'Comments', 'FontSize', fsz, ...
		  'FontWeight', 'bold', ...
		  'BackgroundColor', [.9 .9 .9]);
	  
hComments = uicontrol('Style', 'edit', 'String', params.comments, ...
		'Min', 1, 'Max', 4, ...
		'Units', 'char', 'Position', [30 5 width-40 5], ...
		'HorizontalAlignment', 'left', ...
		'FontSize', fsz, 'BackgroundColor', 'w', 'ForegroundColor', 'k');

	
%% GO / Cancel buttons
uicontrol('Style', 'pushbutton', 'Units', 'char', 'Position', [2 1 20 2], ...
		  'BackgroundColor', [.9 .8 .8], 'String', 'Cancel', ...
		  'Callback', 'OK = 0; uiresume;');

uicontrol('Style', 'pushbutton', 'Units', 'char', 'Position', [width-30 1 20 2], ...
		  'BackgroundColor', [.4 .8 .5], 'String', 'OK', ...
		  'Callback', 'OK = 1; uiresume;');

% allow resizing of the figure
set( findobj('Parent', hFig, 'Type', 'uicontrol'), 'Units', 'norm');  


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% uiwait / uiresume loop; parse response %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
uiwait
OK = evalin('base', 'OK');
evalin('base', 'clear OK'); % clear from base workspace
if OK==1	
	% 'Cancel' button pressed or figure closed: don't modify params
	params.description = get(hDescription, 'String');
	params.annotations = get(hFunctionals, 'String');
	params.subject = get(hSubject, 'String');
	params.comments = get(hComments, 'String');
	
	if ~iscell(params.annotations)
		params.annotations = {params.annotations};
	end
end

%% close the figure
delete(hFig);

return
% /---------------------------------------------------------------------/ %



% /---------------------------------------------------------------------/ %
function h = annotationRow(params, scan, fsz, y);
% Create a row of uicontrols for editing functional annotations,
% returning a handle to the relevant edit field.

%% scan #
uicontrol('Style', 'text', 'Units', 'char', 'Position', [2 y 7 2], ...
		  'String', num2str(scan), 'FontSize', fsz, ...
		  'BackgroundColor', [.9 .9 .9]);
	  
%% input file name  
[p f ext] = fileparts(params.functionals{scan});
uicontrol('Style', 'text', 'Units', 'char', 'Position', [10 y 15 2], ...
		  'String', [f ext], 'FontSize', fsz, ...
		  'BackgroundColor', [.9 .9 .9]);
	  
%% description
if length(params.annotations) >= scan
	str = params.annotations{scan};
else		% not defined, initialize to empty
	str = '';
end

% tag for finding this edit field (in the '_copy' callback):
tag = sprintf('mrInitGUI_description_scan%i', i);

% make the edit field
h = uicontrol('Style', 'edit', 'Units', 'char', 'Position', [30 y 100 2], ...
		  'String', str, 'FontSize', fsz, 'Tag', tag, ...
		  'BackgroundColor', 'w');
	  
return
