function cbar = cbarDefault(cmap, label);
%
% cbar = cbarDefault([cmap=hot(256)], [label='']);
%
% Returns a standard cbar structure, which can be 
% displayed in any axes. Default is a 256-color hot cmap, 
% without any colorwheel options set. 
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
%   angle for a polar angle map). 
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
%	label: text describing the colorbar. This label will be attached to the
%	colorbar anytime you invoke CBARDRAW.
%	
%	labelSide: which side of the cbar to attach the label. If 0 [default], 
%	the label will be on the 'regular' position: for horizontal colorbars,
%	this is on top of the cbar; for vertical, this is to the left. If 1,
%	will put on {below, to the right}, respectively.
%
%	fontsz: size of the font in points.
%
%	units: an additional string specifying the units of the colorbar. 
%	E.g., if you're plotting temperatures, you might have label = 'Temp', 
%	and units = 'K'.
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

cbar.nColors = length(cmap);
cbar.cmap = cmap;
cbar.clim = 'auto';
cbar.direction = 'horiz';
cbar.label = label;
cbar.labelSide = 0;  
cbar.fontsz = 12;
cbar.units = '';
if isunix
    cbar.font = 'Helvetica';
else
    cbar.font = 'Arial';
end
cbar.colorWheel = 0;
cbar.colorWheelStart = 0;
cbar.colorWheelExtent = 360;
cbar.colorWheelDirection = 'clockwise';

return
