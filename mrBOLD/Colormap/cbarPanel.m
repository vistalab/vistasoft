function h = cbarPanel(clim, label, cmap, direction);
% Attach a panel to a figure, with a colorbar.
%
%  h = cbarPanel([clim], [label], [cmap], [direction='vert']);
%
% INPUTS:
%	clim: color limit ([min max]) for the colorbar. [Default [0 1]]
%
% 	label: text label for the colorbar [default none].
%
%	cmap: color map for the colorbar [default: get from figure].
%
%	direction: 'vert' or 'horiz', specifies the direction the panel and
%	colorbar will run. If 'vert', the panel will be attached to the figure
%	right, and the cbar will run vertically. For 'horiz', the panel will be
%	attached below the figure, and the cbar will run horizontally.
%
% OUTPUTS:
%	h: [1 x 2] vector of handles. h(1) is the panel, h(2) is the cbar axes.
%
% ras, 01/2009.
if notDefined('clim'),			clim = [0 1];					end
if notDefined('label'),			label = '';						end
if notDefined('cmap'),			cmap = get(gcf, 'Colormap');	end
if notDefined('direction'),		direction = 'vert';				end

% parse the direction
if strncmp( lower(direction), 'vert', 4)
	direction = 'vert';
else
	direction = 'horiz';
end

%% attach the panel
if isequal(direction, 'vert')
	h = mrvPanel('right', .12, gcf);
else
	h = mrvPanel('below', .12, gcf);
end

%% make the cbar
cbar = cbarCreate(cmap, label, 'Direction', direction, 'Clim', clim);

%% make axes for the cbar 
if isequal(direction, 'vert')
	pos = [.5 .3 .2 .4];
else
	pos = [.3 .5 .4 2];
end

h(2) = axes('Parent', h, 'Units', 'norm', 'Position', pos);

%% draw the cbar
cbarDraw(cbar, h(2));

return


