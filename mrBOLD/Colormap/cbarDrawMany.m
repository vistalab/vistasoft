function [hImgs, hAxes] = cbarDrawMany(cbars, parent, colorScheme);
% Render an array of colorbars in a parent figure or uipanel.
%
% [hImgs, hAxes] = cbarDrawMany(cbars, [parent=gcf], [colorScheme='w']);
%
% This will place several colorbars horizontally along the parent
% object. The optional colorScheme value can be 'w' or 'k': 'w'
% signifies the background of the parent will be white, and the colorbar
% will have black text, while 'k' means black background, white text.
% [default is 'w'].
%
% Returns a vector of handles to each cbar image, and a vector of axes
% handles as an optional second argument.
%
% ras, 02/2007.
if notDefined('parent'),		parent = gcf;			end
if notDefined('colorScheme'),	colorScheme = 'w';		end

h = [];

if isequal(get(parent, 'Type'), 'uipanel')
	set(parent, 'BackgroundColor', colorScheme);
elseif isequal(get(parent, 'Type'), 'figure')
	set(parent, 'Color', colorScheme);
else
	error('Invalid parent type.')
end

N = length(cbars);

% to allow cell arrays, we make everything a cell:
if isstruct(cbars)
	for n = 1:N
		tmp{n} = cbars(n);
	end
	cbars = tmp; clear tmp;
end

w = max( .1, 1/(N+1) );	% cbar width

for n = 1:N
	% compute position of colorbar axes
	if cbars{n}.colorWheel==1
		h = .35;					% cbar height
		y1 = .2;					% cbar start Y position
	else
		h = .15;					% cbar height
		y1 = .4;					% cbar start Y position 
	end
	pos = [(n-1)*1.2*w + w/2, y1, w, h];
	
	hAxes(n) = axes('Parent', parent, 'Units', 'norm', 'Position', pos);
	hImgs(n) = cbarDraw(cbars{n}, hAxes(n));
	title(cbars{n}.label, 'FontSize', 10, 'Parent', hAxes(n), ...
		  'Interpreter', 'none');		
	if ~isempty(cbars{n}.units)
	   xlabel(cbars{n}.units, 'FontSize', 9, 'Parent', hAxes(n));
	end        
	
	if isequal(lower(colorScheme), 'k')		% white-on-black
		set(hAxes(n), 'XColor', 'w', 'YColor', 'w');
		set(get(hAxes(n), 'Title'), 'Color', 'w');
		set(get(hAxes(n), 'Xlabel'), 'Color', 'w');
	end
end



return
