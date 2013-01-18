function view = cmapOverlap(view, colors);
%
% view = cmapOverlap(view, <colors = {'r' 'g' 'y'});
% 
% Set the parameter map mode on a view to be for
% an overlap color map, with four color bands: one
% for map A, one for map B, and one for overlap. A
% fourth one (black) will be used for zero. Also 
% sets the clip mode to manual, between 0.01 and 3. 
% 
% colors is a 1x2 or 1x3 cell specifying the diff't color bands.
% Each entry can be a letter color designator, or [r g b] triplet.
% defaults to red / green / yellow colors. If the last entry is
% omitted, it'll be the combination of the first 2.
%
% A replacement for the awful way we had to call setColormap.
% Should really overhaul the whole damn thing.
% 
%
% ras, 06/06.
if notDefined('view'), view = getCurView; end
if notDefined('colors'), colors = {'r' 'g' 'y'}; end

% convert characters to [r g b] values
c = cell2ColorOrder(colors);

if size(c, 1) < 3
    c(3,:) = c(1,:) + c(2,:);
    c(c>1) = 1;
end

numGrays = view.ui.mapMode.numGrays;
numColors = view.ui.mapMode.numColors;

rngA = 1:round(numColors/3);
rngB = round(numColors/3)+1:ceil((2/3)*numColors);
rngC = ceil((2/3)*numColors)+1:numColors;

colors = zeros(numColors,3);
colors(rngA,:) = repmat(c(1,:), [length(rngA) 1]);
colors(rngB,:) = repmat(c(2,:), [length(rngB) 1]);
colors(rngC,:) = repmat(c(3,:), [length(rngC) 1]);
colors(1,:) = [0 0 0];
view.ui.mapMode.cmap = [gray(numGrays); colors];

view.ui.mapMode.clipMode = [0.01 3];

view = refreshScreen(view);

return