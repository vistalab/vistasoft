function ui = mrViewInfoPanel(ui,dockFlag, vis);
%
% ui = mrViewInfoPanel(ui,[dockFlag], [vis]);
%
% Adds a panel to the mrViewer UI with
% a display of information on the mr objects
% currently loaded.
%
% dockFlag: if 1, will attach panel to the
% mrViewer figure. Otherwise, will make a
% separate figure for the panel.
%
% vis: if 0, will initialize the panel to be hidden (default when
% starting up mrViewer); otherwise, leave it visible (as when 
% docking/undocking the panel).
%
% ras, 07/05/05.
% ras, 07/15/05 -- now places the panel in a separate figure
% by default.
if ~exist('ui', 'var') | isempty(ui), ui = mrViewGet; end
if ~exist('dockFlag', 'var') | isempty(dockFlag), dockFlag = 1; end
if ~exist('vis', 'var') | isempty(vis),  vis = 0; end

bgColor = [.9 .9 .9];

if dockFlag==1
	ui.panels.info = mrvPanel('right', 0.3, ui.fig, 'normalized');
else
	hfig = figure('Name', sprintf('Info [%s]',ui.tag), ...
		'Units', 'normalized', ...
		'Position',[.88 .5 .12 .5], ...
		'MenuBar', 'none', ...
		'NumberTitle', 'off', ...
		'UserData',ui.tag);
	ui.panels.info = uipanel('Parent',hfig,'Units', 'normalized', ...
		'Position',[0 0 1 1]);

	% close request function for this figure: just toggle visibility
    crf = 'tmp = findobj(''Parent'', gcf, ''Type'', ''uipanel''); ';
    crf = [crf 'mrvPanelToggle(tmp); clear tmp;'];
    set(hfig, 'CloseRequestFcn', crf);
end

set(ui.panels.info,'BackgroundColor',bgColor, ...
	'ShadowColor',bgColor,'Title', 'Info');

% popup for selecting mr object about which to view info
ui.controls.infoPopup = uicontrol('Parent',ui.panels.info, ...
	'Style', 'popup', 'String',{sprintf('Base: %s',ui.mr.name)}, ...
	'Units', 'normalized', 'Position', [.05 .84 .8 .06], ...
	'Callback', 'mrViewSet([],''infoPanel'');');
uicontrol('Parent', ui.panels.info, 'Style', 'text', 'String', 'MR Object:', ...
	'HorizontalAlignment', 'center', 'FontWeight', 'bold', ...
	'BackgroundColor', bgColor, 'ForegroundColor', 'k', ...
	'Units', 'normalized', 'Position', [.05 .9 .8 .06]);

% listbox for showing info
ui.controls.infoListbox = uicontrol('Parent',ui.panels.info, ...
	'Style', 'listbox', 'String', infoText(ui.mr), 'FontSize', 9, ...
	'FontName', 'Helvetica', ...
	'Units', 'normalized', 'Position',[.05 .1 .8 .7]);


%%%%%hide the panel if requested
if vis==0
	mrvPanelToggle(ui.panels.info, 'off');    
end

return
