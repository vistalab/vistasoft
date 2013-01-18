function [cbar] = cbarEdit(cbar);
%
% [cbar] = cbarEdit([cbar]);
%
% Edit a mrVista color bar using a GUI. 
%
% These color bars differ from the built-in matlab color bar tools in a few
% basic respects:
%
%   * They draw colorbars based on any colormap the user inputs, rather
%   than the color map assigned to the current figure. This is useful for
%   illustrating color codes on true color images, or images with overlaid 
%   responses (like fMRI activation maps)
%
%   * In addition to being able to render vertical and horizontal color bars, 
%   these tools may also render 'color wheel' colorbars, showing e.g. polar
%   angle. Other possible renderings (like rings) may be added down the
%   line.
%
% cbar is a struct with the following fields:
%
%   cmap: color map (nColors x 3) for the color bar. (Columns ar [R G B],
%   from 0-255).
%
%   nColors: # of colors to use in the cmap. 
%
%   clim: color limits (aka 'clip mode'), which determines primarily
%   the labeling of the color bar. Can be set to 'auto', in which case
%   the labeling will be from 1:nColors. Otherwise, will label according to
%   the clim values (format is [min max]).
%
%   colorWheel: use a color wheel instead of a bar (e.g., to show polar
%   angle for a polar angle map). 
%
%   colorWheelStart: degrees clockwise from 12-o-clock which map to beginning of
%   color map.
%
%   colorWheelDirection: direction of the color wheel. Can be: 
%   1 or 'clockwise' (equivalent); or, 2 or 'counterclockwise' (equiv.)
%
%   colorWheelExtent: degrees (1 - 360) subtended by the color map, for polar
%   angle maps.
%
% ras, 08/06
if notDefined('cbar')
    cbar = cbarDefault;
end

if ischar(cbar) & isequal(lower(cbar), 'update')
    cbarEditUpdate; return;
end

% Create the GUI, attaching cmap and cbar
hfig = cbarEditGUI(cbar);

% Wait for user to respond  via GUI 
uiwait;

% check if user canceled 
OK = evalin('base', 'OK');
evalin('base', 'clear OK');
if OK==0
    warning('User Canceled.')
    delete(hfig);
    return
end

cbar = get(hfig, 'UserData');
delete(hfig);

cbar = rmfield(cbar, 'ui');

return
% /------------------------------------------------------------------/ %




% /------------------------------------------------------------------/ %
function cbar = cbarEditUpdate;
% update the color map editor GUI, based on the settings in the current
% figure.
cbar = get(gcf, 'UserData');

% modify the cmap according to any callback objects
if ishandle(gcbo)
    switch get(gcbo, 'Tag')
        case 'Shift'            % shift according to slider
            delta = round( get(gcbo, 'Value') );
            cbar.cmap = circshift(cbar.cmap, delta);
            set(gcbo, 'Value', 0);   % reset slider

        case 'Flip'             % flip cmap order
            cbar.cmap = flipud(cbar.cmap);

        case 'Reset'            % reset to original cbar
            cbar = get(gcbo, 'UserData'); % stashed here
            
        case 'NumColors'        % set # colors in cmap
            cbar.nColors = str2num(get(gcbo, 'String'));
            while size(cbar.cmap, 1) < cbar.nColors
                cbar.cmap = [cbar.cmap; cbar.cmap];
            end
            cbar.cmap = cbar.cmap(1:cbar.nColors,:);
            
        case 'Preset'           % use a preset color map
            cbar.cmap = mrvColorMaps(get(gcbo, 'Label'), cbar.nColors);                       
			
        case 'ColorWheel'       % set to color wheel
            cbar.colorWheel = get(gcbo, 'Value');
            vals = {'off' 'on'};
            set(cbar.ui.colorWheelPanel, 'Visible', vals{cbar.colorWheel+1});
            
        case 'ColorWheelDirection' % set color wheel CW / CCW
            options = {'clockwise' 'counterclockwise'};            
            cbar.colorWheelDirection = options{ get(gcbo, 'Value') };
            
        case 'ColorWheelStart'  % set start angle for color wheel
            cbar.colorWheelStart = str2num(get(gcbo, 'String'));

        case 'ColorWheelExtent'  % set angle subtended by cmap
			% ras 02/07: new strategy; will set things so that the wedge
			% always goes a full 360 degrees, but will pad the cmap such
			% that it only occupies [extent] degrees. This should help it
			% to work properly for all extents in [0 360].
            newExtent = str2num(get(gcbo, 'String'));
			
			% bounds check
			newExtent = max(1, min(360, newExtent));
			set(gcbo, 'String', num2str(newExtent));
			
			if newExtent ~= cbar.colorWheelExtent
				% undo any previous gray padding
				cbar.cmap = cbar.cmap(1:cbar.nColors,:);
			end
			
			if cbar.colorWheelExtent < 360
				prop = cbar.colorWheelExtent / 360; % proprtion of cbar filled by cmap
				totalColors = ceil(cbar.nColors / prop);
				grayPad = repmat(.5, [(totalColors - cbar.nColors) 3]);
				cbar.cmap = [cbar.cmap; grayPad];
			end
			
			cbar.colorWheelExtent = newExtent;
            
        case 'Expression'       % user inputs expression for color map
			map = cbar.cmap;
			msg = ['Enter a MATLAB expression for the color map. ' ...
				'The color map should be a matrix of 3 x ncolors, ' ...
				'with values from 0 - 255. ' ...
				'You can directly enter the expression, or assign ' ...
				'it to a variable named "map". ' ...
				'E.g.:    [gray(128); hot(128)]; ' ...
				'or:      tmp = hsv(256);  map = tmp(1:100,:); '];
			def = sprintf('gray(%i); ', cbar.nColors);
			resp = inputdlg({msg}, mfilename, 4, {def});
			if strfind(resp{1}, '=') & strfind(resp{1}, 'map')
				% presume that the expression is assigning a value to the
				% 'map' variable:
				eval(resp{1})
			else
				% the map assignment is implied
				map = eval(resp{1});
			end
			cbar.cmap = map;
            
    end
end

% draw the color bar
cbarDraw(cbar);
title('Edit Color Map');

% update GUI figure
set(gcf, 'UserData', cbar);

return
% /------------------------------------------------------------------/ %




% /------------------------------------------------------------------/ %
function hfig = cbarEditGUI(cbar);
% creates the figure for cbarEdit.

%%%%% create figure, main axes
hfig = figure('Color', 'w', 'Name', 'Edit Color Map', 'MenuBar', 'none');
hax = subplot('Position', [.1 .7 .8 .16]); 


%%%%% callback for all uicontrols
cb = 'cbarEdit(''update''); ';

%%%%%main slider
nC = cbar.nColors;
hs = uicontrol('Style', 'slider', 'Min', -nC/2, 'Max', nC/2, 'Value', 0, ...
   'BackgroundColor', 'w', 'ForegroundColor', [.6 .55 .6], 'Tag', 'Shift', ...
    'Units', 'normalized', 'Position', [.1 .55 .6 .08], 'Callback', cb);

% text label
uicontrol('Style', 'text', 'String', 'Amount of Rotation', ...
    'BackgroundColor', [1 1 1], 'FontSize', 12, ...    
    'Units', 'normalized', 'Position', [.1 .47 .8 .08]);

% flip button
uicontrol('Style', 'pushbutton', 'String', 'Flip', 'Callback', cb, ...
    'Tag', 'Flip', ...
    'Units', 'normalized', 'Position', [.75 .55 .2 .05]);

% reset button
uicontrol('Style', 'pushbutton', 'String', 'Reset', 'Callback', cb, ...
    'Tag', 'Reset', ...
    'UserData', cbar, 'Units', 'normalized', 'Position', [.75 .5 .2 .05]);

% edit field for setting # of colors
uicontrol('Style', 'text', 'String', '# Colors in Cmap', 'Callback', cb, ...
    'BackgroundColor', 'w', 'FontSize', 10, 'FontWeight', 'bold', ...
    'UserData', cbar, 'Units', 'normalized', 'Position', [.75 .5 .2 .05]);

uicontrol('Style', 'edit', 'String', num2str(cbar.nColors), 'Callback', cb, ...
    'Tag', 'NumColors', 'Units', 'normalized', 'Position', [.75 .45 .15 .05]);



%%%%%% wedge cbar controls
% checkbox to set the colorbar as a color wheel (wedge)
uicontrol('Style', 'checkbox', 'String', 'Color Wheel (Wedge)', ...
          'Units', 'normalized', 'Position', [.1 .3 .4 .08], ...
          'BackgroundColor', 'w', 'FontSize', 10, 'FontWeight', 'bold', ...
          'Value', cbar.colorWheel, ...
          'Tag', 'ColorWheel', 'Callback', cb);

% put the subsidiary controls in a uipanel
hp = uipanel('Units', 'normalized', 'Position', [.4 .1 .5 .3], ...
             'BorderType', 'none', 'BackgroundColor', 'w');
cbar.ui.colorWheelPanel = hp;          
            
% popup to set the colorbar direction
uicontrol('Parent', hp, 'Style', 'text', 'String', 'Direction', 'Callback', cb, ...
         'BackgroundColor', 'w', 'Units', 'normalized', 'Position', [.1 .85 .8 .1]);

uicontrol('Parent', hp, 'Style', 'popup', ...
          'String', {'clockwise' 'counterclockwise'}, ...
          'BackgroundColor', 'w', ...
          'Units', 'normalized', 'Position', [.1 .6 .8 .25], ...
          'Tag', 'ColorWheelDirection', 'Callback', cb);
      
% edit field to set the color wheel start angle
uicontrol('Parent', hp, 'Style', 'text', 'String', 'Start Angle', 'Callback', cb, ...
          'BackgroundColor', 'w', 'Units', 'normalized', 'Position', [.1 .35 .3 .25]);

uicontrol('Parent', hp, 'Style', 'edit', ...
          'String', num2str(cbar.colorWheelStart), ...
          'BackgroundColor', 'w', ...
          'Units', 'normalized', 'Position', [.6 .35 .3 .25], ...
          'Tag', 'ColorWheelStart', 'Callback', cb);

% edit field to set the color wheel extent
uicontrol('Parent', hp, 'Style', 'text', 'String', 'Extent', 'Callback', cb, ...
          'BackgroundColor', 'w', 'Units', 'normalized', 'Position', [.1 .05 .4 .25]);

uicontrol('Parent', hp, 'Style', 'edit', ...
          'String', num2str(cbar.colorWheelExtent), ...
          'Units', 'normalized', 'Position', [.6 .05 .4 .25], ...
          'BackgroundColor', 'w', ...
          'Tag', 'ColorWheelExtent', 'Callback', cb);
      
onoff = {'off' 'on'};     
set(hp, 'Visible', onoff{cbar.colorWheel+1});

          
%%%%% also add menus to set preset color bars.
mapNames = mrvColorMaps;
mapNames = mapNames(1:end-1); % remove the 'user' option
hm = uimenu('Label','Preset Colormaps','ForegroundColor','b');
for i = 1:length(mapNames)
    uimenu(hm, 'Label', mapNames{i}, 'Tag', 'Preset', 'Callback', cb);
end

% add a callback to let the user input a MATLAB expression for the cbar
uimenu(hm, 'Label', 'Set color map using MATLAB expression...', ...
           'Tag', 'Expression', 'Callback', cb);
      
addFigMenuToggle(hm);


%%%%%Accept and Cancel buttons
evalin('base', 'OK=0;');
cb = 'OK = 1; close(gcf); ';
uicontrol('Style', 'pushbutton', 'String', 'Accept', 'Callback', cb, ...
    'BackgroundColor', [.1 .5 .1], 'ForegroundColor', [1 1 1], ...
    'Units', 'normalized', 'Position', [.1 .04 .3 .06]);

cb = 'OK = 0; delete(gcf); uiresume;';
uicontrol('Style', 'pushbutton', 'String', 'Cancel', 'Callback', cb, ...
    'BackgroundColor', [.7 .1 .1], 'ForegroundColor', [1 1 1], ...
    'Units', 'normalized', 'Position', [.5 .04 .3 .06]);

set(hfig, 'CloseRequestFcn', 'uiresume;', 'UserData', cbar);

cbarEditUpdate;

return

