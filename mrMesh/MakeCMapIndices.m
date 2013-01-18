function colors = MakeCMapIndices(values, cMap, range)
%
%   colors = MakeCMapIndices(values, cMap, range);
%
% Author: Ress
% Purpose:
%     Create a set of colormap values that correspond to each input value.  The
% color map indices are scaled to account for the indput range and the size
% of the color map.
%
% More explanation goes here.
% This routine is oddly named, no?  It makes colors, it doesn't make
% indices.  Once we are sure about this, let's change the call to something
% like meshData2Colors(data,cMap,range).  (BW).
%
% There seem to be logical errors here, involving mapping colors to values
% of 0, which will be cut out anyway (may not matter much for most
% purposes, but when e.g. I'm using a color map with 3 distinct values and
% 3 distinct colors, adding 0 as a fourth value throws the whole thing
% off). -ras
%
% 2004.02.15 Junjie/BW deal with NaN values.

% Number of colors in the color map.
nMap = max(size(cMap));

% Scale values onto input range, then find appropriate colors:
values = (values-range(1)) ./ diff(range);

% Ugh.
values = 1 + round((nMap-1) * values);
values(values<1 | isnan(values)) = 1;
values(values>nMap) = nMap;
colors = cMap(:, values);

return;
