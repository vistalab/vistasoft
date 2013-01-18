function [cmap,numGrays,numColors] = getColorMap(view,mode,colorOnly)
%
%  [cmap,numGrays,numColors] = getColorMap(view,mode,colorOnly)
%
% Author: JL, BW
% Purpose:
%   Return information about the color map for some particular viewing mode.
%   If no mode is specified, phMode is assumed.
%
%   The full color map contains a gray map region and a color map region.
%   If the user only wants the color part, we extract it here and return
%   only that part.

if ieNotDefined('mode'), mode = 'phMode'; end
if ieNotDefined('colorOnly'), colorOnly = 0; end

switch mode
    case {'phMode','ph'}
        mp = view.ui.phMode.cmap;
        numColors = view.ui.phMode.numColors;
        numGrays = view.ui.phMode.numGrays;
        
    case {'ampMode','amp'}
        mp = view.ui.ampMode.cmap;
        numColors = view.ui.ampMode.numColors;
        numGrays = view.ui.ampMode.numGrays;
        
    case {'coMode','co'}
        mp = view.ui.coMode.cmap;
        numColors = view.ui.coMode.numColors;
        numGrays = view.ui.coMode.numGrays;
        
    otherwise
        error('Unknown mode.')
        
end

if colorOnly
     cmap = mp((numGrays+1):(numGrays+numColors),:);
 else
     cmap = mp;
 end
 
 return;

