function figOffscreenCheck(fig);
% figOffscreenCheck([fig]): check that a figure
% doesn't get moved off the edges of the screen.
%
% This function checks the figure fig [default gcf]
% and, if it's running off the edge of the screen, moves / reshapes
% it to fit within the screen.
%
% ras, 07/05/05.
if ~exist('fig','var') | isempty(fig), fig = gcf;     end

% record the existing units of the figure, then set to normalized
% for now:
exUnits = get(fig,'Units');
set(fig,'Units','normalized');
pos = get(fig,'Position');

% first, check if either size argument is larger
% than the screen size (normalized value > 1):
if pos(3)>1, pos(3)=1; end
if pos(4)>1, pos(4)=1; end

% check if right edge out of bounds
if pos(1)+pos(3)>1,  pos(1) = 1-pos(3);    end

% check if left edge out of bounds
if pos(1)<0,    pos(1) = 0;    end

% check if upper edge out of bounds
% (allow extra 0.05 for toolbars which matlab sometimes adds)
if pos(2)+pos(4)>0.95,  pos(2) = 0.95-pos(4);    end

% check if lower edge out of bounds
if pos(2)<0,    pos(2) = 0;    end

% set new position
set(fig,'Position',pos);

% restore old unit convention
set(fig,'Units',exUnits);

return