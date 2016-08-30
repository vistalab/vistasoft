function fig = centerOnscreen(fig)
% Center a figure onscreen, or relative to a parent figure.
%
% fig = centerOnscreen(fig, <parent>);
%
% If the second 'parent' argument is omitted, fig is
% centered relative to the screen bounds. If a handle
% to another figure is provided, fig will be centered 
% relative to that figure (e.g., for a dialog from a GUI).
% Note that this won't resize the image (so if the dialog 
% is bigger than the GUI, it will obscure the 'parent').
%
% If called w/o args, will center the current figure onscreen.
%
% ras, 03/03/2006.
if nargin==0, fig = gcf; end

if nargin<2
    % just center onscreen
    newCenter = [.5 .5];
else
    % get center of parent figure for the new center
    parUnits = get(parent, 'Units');
    set(parent, 'Units', 'normalized');
    parPos = get(parent, 'Position');
    newCenter = parPos(1:2) + parPos(3:4)./2;
    set(parent, 'Units', parUnits);
end

% get info on the screen size, and the figure position in pixels
oldUnits = get(fig, 'Units');
set(fig, 'Units', 'pixels');
posPixels = get(fig, 'Position'); 
screenSize = get(0, 'ScreenSize');

% screen size is in the format [xleft ybottom xsize ysize].
% We care about the size arguments for normalizing, but not
% the corner position arguments:
screenSize = [screenSize(3:4) screenSize(3:4)]; 

% compute the new position in units relative to screen corners
pos = posPixels ./ screenSize;
pos(1:2) = newCenter - pos(3:4)./2; % updated position

% convert normalized units into pixel units, which the figure uses
pos = pos .* screenSize;

% set the new position, restore to old units
set(fig, 'Position', pos);
set(fig, 'Units', oldUnits);

return
