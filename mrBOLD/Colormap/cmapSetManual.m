function view = cmapSetManual(view,map,mode,colorOnly)
%
%  view = cmapSetManual(view,map,mode,colorOnly);
%
%Author: JL, BW
%Purpose:
%  Set the color map in a view.  If colorOnly is set, then the new map is
%  just for the color part, leaving the gray scale part of the map
%  unchange.
%
% Example:
%   FLAT{2} = cmapSetManual(FLAT{2},newMap,'ph',1);

if ieNotDefined('mode'), mode = 'phMode'; end
if ieNotDefined('colorOnly'), colorOnly = 0; end

% Get the current color map parameters
[tmp,numGrays,numColors] = getColorMap(view,mode,colorOnly);
if colorOnly
    s1 = numGrays+1; s2 = numGrays+numColors;
else
    s1 = 1; s2 = size(tmp,1);
end

if size(map,1) ~= length(s1:s2)
    error('New map has the wrong number of rows');
elseif size(map,2) ~= 3
    error('New map has the wrong number of columns.');
end

switch mode
    case {'phMode','ph'}
        view.ui.phMode.cmap(s1:s2,:) = map;

        
    case {'ampMode','amp'}
        view.ui.ampMode.cmap(s1:s2,:) = map;

        
    case {'coMode','co'}
        view.ui.coMode.cmap(s1:s2,:) = map;

        
    otherwise
        error('Unknown mode.')
        
end
return;