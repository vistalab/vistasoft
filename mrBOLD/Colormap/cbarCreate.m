function cbar = cbarCreate(cmap, label, varargin);
%
% cbar = cbarCreate([cmap=hot(256)], [label=''], [other properties]);
%
% Create a cbar structure, which can be displayed in any axes. 
% Default is a 256-color hot cmap, without any colorwheel options set. 
%
%
% cbar is a struct with the following fields:
%
%   cmap: color map (nColors x 3) for the color bar. (Columns ar [R G B],
%   from 0-255).
%
%   nColors: # of colors to use in the cmap. 
%
%   clim: color limits (aka 'clip mode'), which determines primarily
%   the labeling of the color bar. Can be set to 'auto', in which case
%   the labeling will be from 1:nColors. Otherwise, will label according to
%   the clim values (format is [min max]).
%
%   colorWheel: use a color wheel instead of a bar (e.g., to show polar
%   angle for a polar angle map). [default 0: not a color wheel]
%
%   colorWheelStart: degrees clockwise from 12-o-clock which map to beginning of
%   color map.
%
%   colorWheelDirection: direction of the color wheel. Can be: 
%   1 or 'clockwise' (equivalent); or, 2 or 'counterclockwise' (equiv.)
%
%   colorWheelExtent: degrees (1 - 360) subtended by the color map, for polar
%   angle maps.
%
%	direction: 'horiz' or 'vert', describing whether the cbar is drawn
%	horizontally or vertically. Default is horizontal.
%
%	label: text describing the colorbar. This label will be attached to the
%	colorbar anytime you invoke CBARDRAW.
%	
%	labelSide: which side of the cbar to attach the label. If 0 [default], 
%	the label will be on the 'regular' position: for horizontal colorbars,
%	this is on top of the cbar; for vertical, this is to the left. If 1,
%	will put on {below, to the right}, respectively.
%
%	font: name of font to use for labels.
%
%	fontsz: size of the font in points.
%
%	units: an additional string specifying the units of the colorbar. 
%	E.g., if you're plotting temperatures, you might have label = 'Temp', 
%	and units = 'K'.
%
% Property values can be specified in pairs of ..., '[Name]', [value], ...
%
% EXAMPLE:
%	cbar = cbarCreate('cool', 'My Cbar', 'direction', 'vert', 'fontsz', 14);
%	subplot('Position', [.4 .2 .05 .6]);
%	cbarDraw(cbar);
%
% See also: cbarEdit, cbarDraw.
%
% ras, 08/2006.
% ras, 02/2007: added 'units' field.
if notDefined('cmap')
    cmap = hot(256);
elseif ischar(cmap) | (isnumeric(cmap) & length(cmap)==1)
    cmap = mrvColorMaps(cmap);
end

if notDefined('label'), label = ''; end

cbar = cbarDefault;
cbar.cmap = cmap;
cbar.nColors =  size(cbar.cmap, 1);
cbar.label = label;

for i = 1:2:length(varargin)
	switch lower(varargin{i})
		case 'ncolors', cbar.nColors = varargin{i+1};
		case 'cmap', cbar.cmap = varargin{i+1}; 
                     cbar.nColors =  size(cbar.cmap, 1);
		case 'clim', cbar.clim = varargin{i+1};
		case 'direction', cbar.direction = varargin{i+1};
		case 'label', cbar.label = varargin{i+1};
		case 'units', cbar.units = varargin{i+1};
		case 'labelside', cbar.labelSide = varargin{i+1};
		case 'font', cbar.font = varargin{i+1};
		case {'fontsz' 'fontsize'}, cbar.fontsz = varargin{i+1};
		case 'colorwheel', cbar.colorWheel = varargin{i+1};
		case 'colorwheelstart', cbar.colorWheelStart = varargin{i+1};
		case 'colorwheelextent', cbar.colorWheelExtent = varargin{i+1};
		case 'colorwheeldirection', cbar.colorWheelDirection = varargin{i+1};			
		otherwise, warning( sprintf('Unrecognized property %s', varargin{i}) );
	end
end

return