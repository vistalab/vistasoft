function cbar=makeColorBar(view)
%
% cbar=makeColorBar(view)
%
% Makes a horizontal colorbar at the top of the view, that can be
% set/drawn using setColorBar.  Returns a handle to the axis of
% the colorbar.
%
% djh, 1/98
% Modified from mrColorBar, written by gmb 9/96.
% ras, 09/04 -- moved to bottom of window and
% made thinner, personal preference

% Make colorbar
viewType = viewGet(view,'viewType');
switch viewType
    case {'Inplane','Volume','Gray'},
        cbar_pos = [0.2 0.05 0.6 0.03]; % Old pos: [0.2 0.85 0.6 0.05]; New: [.15 0.03 .6 .03]; 
    otherwise,
        cbar_pos = [0.2 0.82 0.6 0.03];
end

cbar = axes('position',cbar_pos);

set(gcf,'NextPlot','add');

% Return the current axes to the main image
set(gcf,'CurrentAxes',view.ui.mainAxisHandle);

return