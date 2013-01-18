function view = cmapSetStandard(view, mode, phInMiddle)
%
%   view = cmapSetStandard(view,mode,phInMiddle)
%
% Author: JL, BW
% Purpose:
%     Put in place a standard color map for the different modes.

if ieNotDefined('mode'), mode = 'ph'; end
    
switch mode
    case 'ph'
    case 'co'
    case 'amp'
    otherwise
end

% ??? view = refreshView(view);

return;


%---------------------------
function cmap = cmapCenter(mp,centerPhase)

[mp, numGrays,numColors] = getColorMap(FLAT{2},'ph',1);

step = numColors/(2*pi);
horPhase = 2;

% We want the part of the default map from pi to 2pi to be centered around
% the phase that represents the horizontal midline.  That means we want to
% shift the map so that 3pi/2 in the default color map shifts down to the
% horizontal position.

sz = round(( (3*pi/2) - horPhase) *step);
cmap = circshift(mp,sz)

return;