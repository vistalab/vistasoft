function ui = mrViewRefresh(ui);
%
% ui = mrViewRefresh(ui);
%
% Refresh a mrViewer UI. Parse the view settings
% from the ui controls, and set the view correspondingly.
% The main function for mrViewer.
%
%
%
% ras, 07/05/05.
% tic
if ~exist('ui','var') | isempty(ui), ui = mrViewGet; end
if ishandle(ui), ui = get(ui, 'UserData'); end

% get display format and orientation
format = ui.settings.displayFormat;
ori = ui.settings.ori;

% delete existing axes in axes panel
oldAxes = findobj('Parent',ui.panels.display);
delete(oldAxes);

% compute underlay images
ui = mrViewUnderlay(ui);

% apply any overlays
if isfield(ui,'overlays') & ~isempty(ui.overlays)
    ui = mrViewOverlay(ui);
	ui = mrViewColorbar(ui);
end

% display each image 
ui = mrViewDisplay(ui,ui.panels.display);

% draw any ROIs
if ~isempty(ui.rois), ui = mrViewROI('draw',ui); end

% store the current ui
set(ui.fig,'UserData',ui);

% set figure name
set(ui.fig,'Name',sprintf('%s   (%s)   [%s]',ui.mr.name,...
    ui.spaces(ui.settings.space).name,ui.tag));

% fprintf('Refresh Time: %3.2f sec.\n',toc);

return
