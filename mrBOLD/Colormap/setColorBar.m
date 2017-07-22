function setColorBar(vw, hideState, cmapRange)
%
% setColorBar(vw, hideState, [cmapRange]);
%
% Redraws the horizontal colorbar at the top of the view.
%
% Inputs:
%   cmapRange: range of colormap entries that you want
%            included in the colorbar
%
% djh, 1/98
% Modified from mrColorBar, written by gmb 9/96.
% ras, 09/04 -- Labels what map is shown on the cbar.
%               This looks nicer when the cbar is moved away
%               from the annotation.
if ~exist('cmapRange','var')
    cmapRange=[1 256];
end

if notDefined('hideState')
    % guess hide state from GUI
    mode = viewGet(vw, 'displaymode');
    if isequal(mode, 'anat')
        hideState = 'off';
    else
        hideState = 'on';
    end
end

cbar = vw.ui.colorbarHandle;

% Hide or show the color bar
set(cbar, 'Visible', hideState);
children = get(cbar,'Children');
set(children, 'Visible', hideState);


%% main IF statement: are we showing a colorbar?
if strcmp(hideState,'on')
    % delete pre-existing ui context menus
    oldImgs = get(cbar, 'Children');
    for ii = 1:length(oldImgs)
        delete( get(oldImgs(ii), 'UIContextMenu') )
    end
    
    % check if we're using a special colorbar for retinotopic data
    params = retinoGetParams(vw);
    if ~isempty(params) && isequal(vw.ui.displayMode, 'ph')
        % Visual-field map: set special legend depending on type
        if isequal(params.type, 'polar_angle')
            setColorBarPolarAngle(vw, params, cbar);
        else
            setColorBarEccentricity(vw, params, cbar);
        end
    else
        % undo any changes to the cbar position made by the above plots
        pos=get(cbar,'Position'); pos(3:4)=[.6 .03]; set(cbar,'Position',pos);
        axis(cbar, 'equal')
        
        %% Core part of code:
        % get range (color limits) for colorbar
        cbarRange = vw.ui.cbarRange;
        if isempty(cbarRange) 
            setColorBar(vw, 'off');
            return
        end
        
        % Re-draw the colorbar and set its axes (if xTicks is valid)
        axes(cbar);
        image([cbarRange(1) cbarRange(2)], [], [cmapRange(1):cmapRange(2)]);
        set(gca, 'YTick', []);
        set(gca, 'FontSize', 10);
        
        % label what the color bar denotes
        dispMode = viewGet(vw,'displayMode');
        switch dispMode
            case 'amp',
                label = 'Traveling Wave Amplitude';
            case 'co',
                label = 'Traveling Wave Coherence';
            case 'ph',
                label = 'Phase (radians)';
            case 'map',
                if isfield(vw, 'mapUnits') && ~isempty(vw.mapUnits)
                    label = sprintf('%s (%s)', vw.mapName, vw.mapUnits);
                else
                    label = vw.mapName;
                end
            otherwise,
                label = '';
        end
        subplot(cbar);
        title(label, 'FontSize',12, 'FontName','Helvetica');
        
    end     % if visual field map cbar / regular cbar
    
end

% set UI context menu
try
    set(get(cbar, 'Children'), 'UIContextMenu', cbarContextMenu(vw));
catch
    % don't worry for now
end

% Return the current axes to the main image
set(vw.ui.windowHandle, 'CurrentAxes', vw.ui.mainAxisHandle);

return
% /--------------------------------------------------------------------/ %




% /--------------------------------------------------------------------/ %
function setColorBarPolarAngle(vw, params, cbar)
% set the color bar to illustrate the polar angle traversed in this scan
dispMode = sprintf('%sMode', vw.ui.displayMode);
nG = vw.ui.(dispMode).numGrays;
cmap = vw.ui.(dispMode).cmap(nG+1:end,:);
bgColor = [1 1 1]; % get(vw.ui.windowHandle, 'Color');

% wedge = polarAngleColorBar(params, cmap, 256, bgColor);

% alt: use my older code, it seems to be stable
if isequal(lower(params.direction), 'clockwise')
    direction = 0;
else
    direction = 1;
end
startAngle = params.startAngle;
if params.visualField==360, p.visualField = 'b';
elseif params.visualField==180, p.visualField = 'l';
else   p.visualField = 'r';
end
p.doPlot = 0; p.trueColor = 1;
wedge = cmapWedge(cmap, startAngle, direction, p);

% display the image: we'll need to make the color bar axes a bit larger
axes(cbar);
pos=get(cbar,'Position'); pos(3:4)=[.1 .1]; set(cbar,'Position',pos);
set(cbar, 'Position', pos);
image(wedge);
axis image; axis off;
text(256, 270+280, 'Polar Angle', 'FontSize', 10, 'FontName', 'Helvetica', ...
    'FontWeight', 'bold', 'HorizontalAlignment', 'center');
return
% /--------------------------------------------------------------------/ %




% /--------------------------------------------------------------------/ %
function setColorBarEccentricity(vw, params, cbar)
% set the color bar to illustrate the eccentricity traversed in this scan
dispMode = sprintf('%sMode', vw.ui.displayMode);
nG = vw.ui.(dispMode).numGrays;
nC = vw.ui.(dispMode).numColors;
cmap = vw.ui.(dispMode).cmap(nG+1:end,:);

% undo any changes to the cbar position made by the above plots
pos=get(cbar,'Position'); pos(3:4)=[.6 .03]; set(cbar,'Position',pos);

%% get the eccentricity mapped by the colors
% each entry in the colormap (cmap) corresponds to this phase in radians:
phi = linspace(0, 2*pi, nC);

% for each entry, we solve for the corresponding eccentricity estimate:
xrng = eccentricity(phi, params);

% deal with circular shift from the mapping (if params.startPhase ~= 0):
% we need to give the IMAGE command an xrng that increases linearly, but
% we want the color range to be remapped so that the appropriate color
% points to the appropriate eccentricity.  Do this inverse mapping:
[xrng, I] = sort(xrng);
crng = (1:nC) + nG;  % default, increasing color values for the cbar
crng = crng(I);		 % sorted to correspond to xrng

% put up the image
set(gcf, 'CurrentAxes', cbar);
image(xrng, [], crng);
set(gca, 'YTick', [], 'FontSize', 10);
title('Eccentricity, degrees', 'FontSize', 12)
return
% /--------------------------------------------------------------------/ %


