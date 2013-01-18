function map = mrvColorMaps(name, nC, varargin)
%
% map = mrvColorMaps(name, [nColors=256]);
%
% Color maps used in mrVista.
%
% list = mrvColorMaps without input arguments
% returns a list of the currently-defined
% color maps.
%
% map = mrvColorMaps([name or num]) returns a 3x256
% color map corresponding to the name, or its index
% number in the list of all colormaps (useful for
% popup menus etc).
%
% map = mrvColorMaps('user') prompts for a user-defined
% colormap. This can be specified in one of two ways:
%   (1) Enter the # of colors to use. A prompt pops up
%       with a GUI to edit manually each of the colors.
%       You can also invoke the matlab CMAPEDITOR on this
%       for further options.
%
%   (2) Save a matlab file which contains the variable
%       'cmap'. At the dialog, leave the # of colors empty.
%       A second dialog will appear prompting for this file.
%
% map = mrvColorMaps([name or num], nC) returns a
% 3xnColors preset color map.
%
% For the case 'redgreenblue', you can specify an optional 3rd argument,
% gamma, which specifies the sharpness of the color transitions. (gamma > 1
% is sharper, gamma==1 is linear, gamma < 1 is more gradual).
%
% mrvColorMaps('demo') shows a set of all current colormaps in a figure.
%
% ras 07/05.
% ras 10/05: added support for external color maps.
% ras 05/08: added 'short HSV' color map, support for MATLAB expression
if nargin==0
	% output a list of names
	map = {'hot' 'cool' 'jet' 'hsv' 'hsvshort' 'gray' 'autumn' 'winter'...
		'red' 'green' 'blue' 'yellow' 'cyan' 'magenta' ...
		'red binary' 'green binary' 'blue binary' ...
		'redgreenblue' 'redyellowblue' 'greenbluered' ...
		'redgreenblueyellow' 'redmagentablue' ...
		'blueredyellow' 'greenred' ...
		'revjet' 'bluered' 'coolhot' 'user'}; 
	return
end

if ~exist('nC','var') || isempty(nC), nC = 256; end

if isnumeric(name)
	% convert from index # into name
	list =  mrvColorMaps;
	name = list{name};
end

map = zeros(nC,3);
switch lower(name)
	case 'hot', map = hot(nC);
	case 'cool', map = cool(nC);
	case 'jet', map = jet(nC);
	case 'hsv', map = hsv(nC);
	case 'hsvshort', map = circshift( hsv(round(nC*1.4)), 10 ); map = map(1:nC,:);
	case 'gray', map = gray(nC);
	case 'autumn', map = autumn(nC);
	case 'winter', map = winter(nC);
	case 'red binary', map(:,1) = 1;
	case 'green binary', map(:,2) = 1;
	case 'blue binary', map(:,3) = 1;
	case 'red', map(:,1) = linspace(0, 1, nC);
	case 'green', map(:,2) = linspace(0, 1, nC);
	case 'blue',  map(:,3) = linspace(0, 1, nC);
	case 'yellow', map = mrvColorMaps('red',nC) + mrvColorMaps('green',nC);
	case 'cyan', map = mrvColorMaps('blue',nC) + mrvColorMaps('green',nC);
	case 'magenta', map = mrvColorMaps('red',nC) + mrvColorMaps('blue',nC);

	case {'redgreen', 'greenred'},
		map(:,1) = linspace(0.2,1,nC);
		map(:,2) = linspace(1,0.2,nC);

	case {'redgreenblue', 'rgb'},
		% do some gamma adjust so the color trabsitions are more prominent
		% gamma coefficient (<1 = sharp, 1=linear, >1 = gradual)
		if ~isempty(varargin)
			gamma = varargin{1};
		else
			gamma = 2.8;
		end

		% make ramps for each color
		r = mrvColorMaps('red', nC) .^ gamma;
		g = [mrvColorMaps('green', ceil(nC/2)) .^ gamma] .* 0.7;
		g = [g; flipud(g)]; g = g(1:nC,:);
		b = flipud( mrvColorMaps('blue', nC) ) .^ gamma;
		map = r + g + b;
		map = map(1:nC,:);

	case {'redyellowblue', 'ryb'}
		% complement to rgb color map, for representing the ipsilateral
		% visual field.
		
		% do some gamma adjust so the color trabsitions are more prominent
		% gamma coefficient (<1 = sharp, 1=linear, >1 = gradual)
		if ~isempty(varargin)
			gamma = varargin{1};
		else
			gamma = 2.8;
		end

		% make ramps for each color
		r = mrvColorMaps('red', nC) .^ gamma;
		y = [mrvColorMaps('yellow', ceil(nC/2)) .^ gamma] .* 0.7;
		y = [y; flipud(y)]; y = y(1:nC,:);
		b = flipud( mrvColorMaps('blue', nC) ) .^ gamma;
		map = r + y + b;
		map = map(1:nC,:);

		
	case {'pinwheel' 'rgb_alt' 'redgreenblueyellow' 'rgby'}
		% an alternate version of the RGB color map above: still trying to
		% keep (red, green, blue) mapping to (down, horizontal, up) in
		% representing polar angle, but with an accommodation for
		% representing activations at ipsilateral polar angles as well.
		n = ceil(nC/4); m = nC - 2*n;
		map = [ mrvColorMaps('blue', n); ...
			flipud(mrvColorMaps('hsvshort', m)); ...
			flipud(mrvColorMaps('red', n)) ];
% 		n = ceil(nC/2); m = nC - n;
% 		map = [ mrvColorMaps('rgb', n); ...
% 				flipud(mrvColorMaps('ryb', m)) ];
		

	case {'greenbluered', 'gbr'},
		% do some gamma adjust so the color trabsitions are more prominent
		if ~isempty(varargin)
			gamma = varargin{1};
		else
			gamma = 2.8;  % gamma coefficient (<1 = sharp, 1=linear, >1 = gradual)
		end

		g = flipud( mrvColorMaps('green', nC) ) .^ gamma;
		b = mrvColorMaps('blue', ceil(nC/2)) .^ gamma;
		b = [b; flipud(b)]; b = b(1:nC,:);
		r = mrvColorMaps('red', nC) .^ gamma;    % make ramps for each color

		I = floor(nC/3):ceil(2*nC/3);

		map = r + g + b;

		map = map(1:nC,:);

	case {'redmagentablue', 'rmb', 'redblue', 'rb'},
		map(:,1) = linspace(1, 0, nC);
		map(:,2) = zeros(nC, 1);
		map(:,3) = linspace(0, 1, nC);

	case {'blueredyellow' 'bry' 'rby' 'redblueyellow'}
		r = linspace(0,1,nC/2)';
		z = zeros(nC/2,1);
		o = ones(nC/2,1);
		map = [[r;o] [z;r] flipud([z;r])];

	case {'revjet' 'reversejet'}
		map = 1 - jet(nC);

	case {'bluered' 'corr'}
		% blue-red colormap which works well for correlation coefficients
		blue = flipud( mrvColorMaps('blue', ceil(nC/2)) );
		red = mrvColorMaps('red', nC - ceil(nC/2));
		map = [blue; red];

	case {'coolhot' 'blueredmagenta' 'corr2'}
		% modified version of the above correlation colormap:
		% saturates to magenta at both ends
		nQ = ceil(nC / 4);  % one quarter of the cmap

		mag1 = [ zeros(1, nQ)' linspace(1, 0, nQ)' ones(1, nQ)'];
		blue = flipud( mrvColorMaps('blue', nQ) );
		red = mrvColorMaps('red', nC - 3*nQ);
		mag2 = [ones(1, nQ)' linspace(0, 1, nQ)' zeros(1, nQ)'];

		map = [mag1; blue; red; mag2];

	case 'user', map = mrvUserColormap;

	case 'demo', % show a demo of the available color maps
		map = mrvColorMaps;
		figure('Name', 'Color Maps in mrvColorMaps');
		for i = 1:27
			subplot(7, 4, i);
			image(ind2rgb(1:256, mrvColorMaps(i)));
			title(map{i});
			axis off;
		end
		return

	case 'expression' % let user input a MATLAB expression
		msg = ['Enter a MATLAB expression for the color map. ' ...
			'The color map should be a matrix of 3 x ncolors, ' ...
			'with values from 0 - 255. ' ...
			'You can directly enter the expression, or assign ' ...
			'it to a variable named "map". ' ...
			'E.g.:    [gray(128); hot(128)]; ' ...
			'or:      tmp = hsv(256);  map = tmp(1:100,:); '];
		def = sprintf('gray(%i); ', nC);
		resp = inputdlg({msg}, mfilename, 4, {def});
		if ~isempty(strfind(resp{1}, '=')) && ...
			~isempty(strfind(resp{1}, 'map'))
			% presume that the expression is assigning a value to the
			% 'map' variable:
			eval(resp{1})
		else
			% the map assignment is implied
			map = eval(resp{1});
		end
	

	otherwise
		warning('Invalid name specified. Returning empty color map');
end

% bounds check
map(map>1) = 1; map(map<0) = 0;

return
% /-------------------------------------------------------------------/ %




% /-------------------------------------------------------------------/ %
function map = mrvUserColormap;
% Use the colormap editor to get a colormap
%
% map = mrvUserColormap;
%
% ras 10/2005.
q='Enter # of colors in new colormap (leave empty to load from file)';
resp = inputdlg(q, 'mrvColormaps', 1, {'256'});
if isempty(resp{1})
	% load from file
	p = 'Select a .mat file with the colormap as a ''cmap'' variable.';
	[f pth] = uigetfile('*.mat',p);
	try
		load(fullfile(pth,f),'cmap');
		map = cmap;
	catch
		msg='Can''t find file w/ cmap variable, returning empty cmap.';
		warning(msg); map=[]; return
	end

else
	nC = str2num(resp{1});
	cbar = cbarEdit( cbarDefault(hot(nC)) );
	map = cbar.cmap;

end

return




% old cmaps
%     case 'selectivity'   % for AdaptNSelect experiment (4 colors), gum
%         colors = {[1 0 0] [1 1 0] [0 1 1] [0 0 1]};
%         colPerCond = nC / length(colors);
%         map = [];
%         for i = 1:length(colors)
%             for j = 1:colPerCond
%                 col = colors{i};
%                 w = 0.3 + 0.5*(j-1) / colPerCond; % weight of color
%                 map(end+1,:) = (w*col+ ((colPerCond-j+1) / (colPerCond))*[.7 .7 .7]);
%             end
%         end
%
%         % shift so that, when this is mapped to an integer range,
%         % integer values (like 1.0) will map to the max of the previous
%         % range, not the first of the next range -- also add black:
%         map = [0 0 0; map(1:nC-1,:)];

