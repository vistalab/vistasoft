function ui = mrViewGrayscalePanel(ui, dockFlag, vis);
%
% ui = mrViewGrayscalePanel(ui, [dockFlag], [vis=0]);
%
% Add a panel for setting the grayscale display
% values of the mr image (underlay). Also initializes
% the panel to be hidden, since it may not be needed
% right away.
%
% dockFlag: if 1, will attach panel to the
% mrViewer figure. Otherwise, will make a
% separate figure for the panel.
%
% vis: if 0, will initialize the panel to be hidden (default when
% starting up mrViewer); otherwise, leave it visible (as when 
% docking/undocking the panel).
%
% ras, 07/05.
% ras, 07/15/05 -- now places the panel in a separate figure
% by default.
% ras, 06/07 -- now a horizontal panel; added vis toggle. 
if ~exist('ui','var') | isempty(ui), ui = mrViewGet; end
if ~exist('dockFlag','var') | isempty(dockFlag), dockFlag = 0; end
if ~exist('vis', 'var') | isempty(vis),  vis = 0; end

% add the panel
if dockFlag==1
    ui.panels.grayscale = mrvPanel('above', .2, ui.fig, 'normalized');
else
    hfig = figure('Name', sprintf('Grayscale [%s]',ui.tag),...
        'Units', 'normalized', 'Position', [.2 .4 .12 .3],...
        'MenuBar', 'none', 'NumberTitle', 'off', ...
        'UserData', ui.tags);
    ui.panels.grayscale = uipanel('Parent',hfig,'Units','normalized',...
        'Position',[0 0 1 1]);
	
	% close request function for this figure: just toggle visibility
    crf = 'tmp = findobj(''Parent'', gcf, ''Type'', ''uipanel''); ';
    crf = [crf 'mrvPanelToggle(tmp); clear tmp;'];
    set(hfig, 'CloseRequestFcn', crf);
end

set(ui.panels.grayscale, 'BackgroundColor', [.9 .9 .9],...
    'ShadowColor', [1 1 1], 'Title', 'Grayscale');

% add a slider for brightness
ui.controls.brightness = mrvSlider([.02 .2 .2 .5], 'Brightness', ...
    'Callback', 'mrViewSetGrayscale;', 'Range', [-1 1], 'Val', 0,...
    'Parent', ui.panels.grayscale);

% add a toggle button for manually setting clip values
cb = 'mrViewSetGrayscale(gcf, ''manualclip'', gcbo); ';
ui.controls.manualClip = mrvButtons('Manual Clip Values',...
    [.25 .55 .15 .4], ui.panels.grayscale, cb, 0);

% add a button to guess clip val
cb = 'mrViewSetGrayscale([],''clip'',''guess'');';
ui.controls.guessClip = uicontrol('Parent', ui.panels.grayscale, ...
    'Style', 'pushbutton', ...
    'String', 'Guess Clip Vals', ...
    'Units', 'normalized', ...
    'Position', [.25 .05 .15 .4], ...
    'Callback', cb);


% add sliders for clip min / max
rng = [min(ui.mr.data(:)) max(ui.mr.data(:))];
ui.controls.clipMin = mrvSlider([.45 .55 .2 .4], 'Clip Min Val',...
    'Callback', 'mrViewSetGrayscale;', ...
    'Range', rng, 'Val', rng(1),...
    'Visible', 'off', ...
    'Parent', ui.panels.grayscale);

ui.controls.clipMax = mrvSlider([.45 .05 .2 .4], 'Clip Max Val',...
    'Callback', 'mrViewSetGrayscale;',...
    'Range', rng, 'Val', rng(2),...
    'Visible', 'off',...
    'Parent', ui.panels.grayscale);



% hide the panel
mrvPanelToggle(ui.panels.grayscale,'off');

%%%%%hide the panel
if vis==0
	mrvPanelToggle(ui.panels.grayscale, 'off');    
end

return
