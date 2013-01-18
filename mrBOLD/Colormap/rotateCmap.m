function view = rotateCmap(view, shiftAmount)
%
% view = rotateCmap(view, [shift])
%
% AUTHOR:  Poirson/Boynton/Heeger
% DATE:    01.13.98
% PURPOSE: Rotates colormap with mouse presses.
%          shiftAmount is amount to shift color part of the view's
%          display mode in DEGREES (used to be in numColors, but updated
%          01/06 by ras since this requires detailed knowledge of the
%          view mode settings): 180 degrees means rotate by half the 
%          number of colors, and so on. Positive values of shiftAmount
%          shift the cmap forward, negative values backward. If omitted,
%          a GUI is created for rotating and flipping the cmap.
%   
% HISTORY:  Started with 'mrShiftCmap'
%           03.18.97  gmb  Wrote mrRotateCmap by borrowing from mrvAreaCmap
%           01.13.98  djh  Updated to mrLoadRet-2
%				03.10.99	 wap	Allowed shift to be passed in
%           01.16.06    ras  Rewritten, makes separate GUI w/ slider
mode = sprintf('%sMode', view.ui.displayMode);

nG = view.ui.(mode).numGrays;
nC = view.ui.(mode).numColors;
cmap = view.ui.(mode).cmap(nG+1:end,:);

if notDefined('shiftAmount')
    view.ui.(mode).cmap(nG+1:end,:) = editCmapGUI(view, cmap, nG, nC);
else
    nShift = round(shiftAmount * nC / 360);
    view.ui.(mode).cmap(nG+1:end,:) = circshift(cmap, nShift);
end

refreshScreen(view);

return
% /-------------------------------------------------------------------/ %





% /-------------------------------------------------------------------/ %
function cmap = editCmapGUI(view, cmap, nG, nC);
%  cmap = editCmapGUI(view, cmap, numGrays, numColors);
% GUI to rotate and flip the cmap. May grow this to do other
% nice editing functions, then break off as a standalone function.
% But for now, it's just for rotateCmap.
% ras, 01/06.
hfig = figure('Color', 'w', 'Name', 'Rotate Color Map', 'UserData', cmap, ...
			  'MenuBar', 'none', 'NumberTitle', 'off');
hax = subplot('Position', [.1 .5 .8 .2]); 

if ~isempty(view.ui.cbarRange), cbarRange = view.ui.cbarRange;
else,                           cbarRange = 1:nC;
end
image(cbarRange, [], 1:nC);
colormap(cmap);
set(gca, 'YTick', []);
title(sprintf('Current colorbar: %s mode', view.ui.displayMode));

%%%%%For polar angle map scans, show the wedge color bar 
params = retinoGetParams(view);
if ~isempty(params)  &  isequal(view.ui.displayMode, 'ph')
	if isequal(params.type, 'polar_angle')
		% render a polar angle color wheel instead of a cbar
		if isequal(lower(params.direction), 'clockwise')
			direction = 0; dirFlag = 1;
		else                                               
			direction = 1; dirFlag = -1;
		end
		startAngle = params.startAngle + dirFlag*params.width/2;
		if params.visualField==360, params.visualField = 'b';
		else, params.visualField = 'l'; 
		end 
		params.doPlot = 0; params.trueColor = 0;
		image(cmapWedge(cmap, startAngle, direction, params));
		axis image; axis off;
		
	elseif isequal(params.type, 'eccentricity')
		% render an eccentricity-sorted color bar
		% get the eccentricity mapped by the colors
		phi = linspace(0, 2*pi, nC);
		xrng = eccentricity(phi, params);

		% deal with circular shift from the mapping (if startPhase ~= 0):
		% we need to give the IMAGE command an xrng that increases linearly, but
		% we want the color range to be remapped so that the appropriate color
		% points to the appropriate eccentricity.  Do this inverse mapping:
		[xrng I] = sort(xrng);
		crng = [1:nC];  % default, increasing color values for the cbar
		crng = crng(I);		 % sorted to correspond to xrng

		% put up the image
		image(xrng, [], crng); 
		set(gca, 'YTick', [], 'FontSize', 10);
		title('Eccentricity, degrees', 'FontSize', 12)
		
	end
end

%%%%%main slider
cb = ['tmp=get(gcf,''UserData''); delta=round(get(gcbo,''Value'')); ' ...
      'tmp=circshift(tmp,delta); colormap(tmp); ' ...
      'set(gcf,''UserData'',tmp); set(gcbo,''Value'',0); clear tmp delta '];
hs = uicontrol('Style', 'slider', 'Min', -nC/2, 'Max', nC/2, 'Value', 0, ...
   'BackgroundColor', 'w', 'ForegroundColor', [.6 .6 .6], ...
   'Units', 'normalized', 'Position', [.1 .2 .6 .08], 'Callback', cb);

%%%%%text label
uicontrol('Style', 'text', 'String', 'Amount of Rotation', ...
    'BackgroundColor', [1 1 1], 'FontSize', 12, ...    
    'Units', 'normalized', 'Position', [.1 .12 .8 .08]);

%%%%%flip button
cb = ['tmp=get(gcf,''UserData''); tmp=flipud(tmp); colormap(tmp); ' ...
      'set(gcf,''UserData'',tmp); clear tmp '];
hf = uicontrol('Style', 'pushbutton', 'String', 'Flip', 'Callback', cb, ...
    'Units', 'normalized', 'Position', [.75 .2 .2 .05]);

%%%%%reset button
cb = ['tmp=get(gcbo,''UserData''); colormap(tmp); ' ...
      'set(gcf,''UserData'',tmp); clear tmp '];
hr = uicontrol('Style', 'pushbutton', 'String', 'Reset', 'Callback', cb, ...
    'UserData', cmap, ...
    'Units', 'normalized', 'Position', [.75 .25 .2 .05]);

%%%%% also add menus to set preset color bars.
cb = ['tmp = mrvColorMaps( get(gcbo, ''UserData'') ); ' ...
	  'colormap(tmp); ' ...
      'set(gcf,''UserData'',tmp); clear tmp '];
mapNames = mrvColorMaps;
mapNames = mapNames(1:end-1); % remove the 'user' option
hm = uimenu('Label','Preset Colormaps','ForegroundColor','b');
for i = 1:length(mapNames)
    uimenu(hm, 'Label', mapNames{i}, 'UserData', i, 'Callback', cb);
end

% add a callback to let the user input a MATLAB expression for the cbar
uimenu(hm, 'Label', 'Set color map using MATLAB expression...', ...
           'UserData', 'Expression', 'Callback', cb);
      
addFigMenuToggle(hm);


%%%%%Accept and Cancel buttons
cb = 'cmap=get(gcf,''UserData''); uiresume; clear cmap ';
uicontrol('Style', 'pushbutton', 'String', 'Accept', 'Callback', cb, ...
    'BackgroundColor', [.1 .5 .1], 'ForegroundColor', [1 1 1], ...
    'Units', 'normalized', 'Position', [.1 .04 .3 .06]);

cb = 'close(gcf); ';
uicontrol('Style', 'pushbutton', 'String', 'Cancel', 'Callback', cb, ...
    'BackgroundColor', [.7 .1 .1], 'ForegroundColor', [1 1 1], ...
    'Units', 'normalized', 'Position', [.5 .04 .3 .06]);

set(gcf, 'CloseRequestFcn', 'uiresume; closereq;');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Wait for user to respond  via GUI % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
uiwait;

cmap = get(hfig, 'UserData');
delete(hfig);
clear view nG nC

return
