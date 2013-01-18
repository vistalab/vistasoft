function [hSlider hZoom] = scrollbar(parent, scale, d);
%
% [hSlider hZoom] = scrollbar([parent=gca], [scale=300], [direction='horiz']);
%
% Attach a scrollbar for stepping through the plotted range of a set of
% axes. Useful for e.g., scrolling through a long time course. Will shrink
% the parent axes a bit to fit in the scrollbar
%
% The scale argument specifies how large the plotted window should be. If
% the plotted data don't already extend this far, will not attach a
% scrollbar. Otherwise, will set it such that the axis extent along the X
% or Y dimension (depending on whether we're using a horizontal or vertical
% scrollbar) equals scale. [Default is 300]
%
% Instead of a single number for the scale, you can input a vector
% of time series data. In this case, the scale will be inferred
% based on the data being plotted. Edward Tufte suggests trends
% in time series data are most apparent when the mean slope of
% changes is around 45 degrees on the plot. The auto-scale detect
% method tries to allow for this aspect ratio on the figure.
%
% The direction can be 1 or 'horiz' to signify a horizontal scrollbar
% (scroll along X axis); 2 or 'vert' to signify a vertical scrollbar
% (scroll along Y). Default is horizontal.
%
% Returns handles to the slider, and a 'zoom out' button which shows the
% extent of plotted data.
%
% EXAMPLE:
%   t = 0:.05:8*pi;
%   figure, plot(t, t.*sin(t));
%   scrollbar(gca, pi, 'horiz');
%
% ras, 08/06.
if notDefined('parent'), parent = gca; end
if notDefined('scale'), scale = 300; end
if notDefined('d'), d = 'horiz'; end

if isnumeric(d)
	directions = {'horiz' 'vert'};
	d = directions{d};
end

if length(scale) > 1
	% time series passed in: auto-detect scale based on this
	tSeries = scale;
	scale = guessScale(tSeries, parent);
end

switch lower(d(1:4))
	case 'hori'   % horizontal
		% if the X axis range < scale, no scrollbar needed
		axis auto
		AX = axis;
		if diff(AX(1:2)) <= scale
			hSlider = []; hZoom = [];
			return
		end

		% make parent axes smaller
		set(parent, 'Units', 'normalized');
		oldPos = get(parent, 'Position');
		h = max(.04, .05 * oldPos(3));         %  height for new controls
		newPos = [oldPos(1) oldPos(2)+h oldPos(3) oldPos(4)-h];
		set(parent, 'Position', newPos);

		%% make slider
		% user data for slider: will contain a handle to the parent axes
		% and the scale value
		ud.axesHandle = parent;
		ud.scale = scale;

		% callback string for the slider:
		cb = 'val = get(gcbo,''Value''); AX = axis; ';
		cb = sprintf('%s \n ud = get(gcbo, ''UserData'');', cb);
		cb = sprintf('%s \n axes(ud.axesHandle);', cb);
		cb = sprintf('%s \n axis([val val+ud.scale AX(3:4)]);', cb);
		cb = sprintf('%s \n clear val ud AX ', cb);

		% make the slider
		sliderPos = [oldPos(1)+.08, oldPos(2)-.1, oldPos(3)-.1, h];
		hSlider = uicontrol('Style','slider', 'UserData', ud, ...
            'Parent', get(parent, 'Parent'), ...
			'Units', 'Normalized', 'Position', sliderPos, ...
			'Min', AX(1), 'Max', AX(2) - scale, ...
			'Callback', cb, 'BackgroundColor', 'w');

		% make zoom
		zoomPos = [oldPos(1) oldPos(2)-.1 .07 h];
		hZoom = uicontrol('Style', 'pushbutton', 'Units','Normalized',...
            'Parent', get(parent, 'Parent'), ...
            'Position', zoomPos, 'UserData', parent, ...
			'BackgroundColor', 'w', 'String', 'UnZoom',...
			'Callback', 'axes(get(gcbo, ''UserData'')); axis auto');

		% let's also create a context menu which will allow us to set the
		% range of the axis bounds
		cmenu = uicontextmenu;

		cb = ['ud = get( get(gcbo,''UserData''), ''UserData'' ); ', ...
			'def = {num2str(ud.scale)}; q = {''X axis range:''}; ', ...
			'tmp = inputdlg(q, ''scrollbar'', 1, def); ', ...
			'ud.scale = str2num(tmp{1}); ', ...
			'AX = axis; newmax = AX(2) - ud.scale; ', ...
			'set( get(gcbo,''UserData''), ''UserData'', ud, ''Max'', newmax); ', ...
			'clear ud def q tmp newmax'];
		uimenu(cmenu, 'Label', 'Set Viewable Range', 'UserData', hSlider, ...
			'Callback', cb);
		
		cb = ['set(gcbo, ''Visible'', ''off''); ' ...
			  'set(get(gcbo,''UserData''), ''Visible'', ''off''); '];
		uimenu(cmenu, 'Label', 'Hide', 'UserData', hSlider, ...
			'Callback', cb);

		set(hSlider, 'UIContextMenu', cmenu);
		set(hZoom, 'UIContextMenu', cmenu);


	case 'vert'   % vertical
		warning('Sorry, vertical direction not yet implemented.')
		return

end


return
% /-------------------------------------------------------------------/ %




% /-------------------------------------------------------------------/ %
function scale = guessScale(tSeries, parent);
% scale = guessScale(tSeries, parent);
% try to guess a reasonable scale range for the current axes
% based on the slopes in the provided time series.
nFrames = length(tSeries);

% first, if we're plotting this at asp.ratio = 1 (1:nFrames, 1:nFrames),
% what's the mean slope?
normY = normalize(tSeries, 1, nFrames);
slope = abs( atan( diff(normY) ) );

% now, set the optimal asp. ratio to be around 45 deg.
r = 20 * mean(slope) / (pi/4);       % optimal (xSize / ySize)

% finally, combine this aspect ratio and knowledge of the
% size of the parent axes in the figure to identify the best
% scrollbar scale:
pos = get(parent, 'Position');
idealXSize = r * pos(4);    % (xSize/ySize) * ySize

if idealXSize <= pos(3)     % don't need a scrollbar
	scale = inf;

	% let's be adventurous, and actually change the size of the
	% parent axes to have the ideal ratio:
	set(parent, 'Position', [pos(1:2) idealXSize pos(4)]);

else
	AX = axis(parent);      % current axis range
	dx = AX(2) - AX(1);
	scale = dx * pos(3) / idealXSize;
end

return