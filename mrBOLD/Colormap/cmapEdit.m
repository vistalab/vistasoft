function [cmap, params] = cmapEdit(cmap, varargin);
%
% [cmap, params] = cmapEdit(cmap, [params]);
%
% Edit a color map using a GUI. 
%
% The optional 'params' struct specifies the cmap settings. Some of the
% fields:
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

% default params
params.nColors = 256;
params.cmap = hot(params.nColors);
params.clim = 'auto';
params.colorWheel = 0;
params.colorWheelStart = 0;
params.colorWheelExtent = 360;
params.colorWheelDirection = 'clockwise';

% this is a convoluted switch -- if the optional arg 'update' 
% is entered, will update the UI rather than starting a new one.
if ~isempty(varargin)     
    if isequal(lower(varargin{1}),'update')
        params = cmapEditUpdate; 
        return
        
    elseif isstruct(varargin{1})
        params = varargin{1};
        
    end            
end

% Create the GUI, attaching cmap and params
params.cmap = cmap;
hfig = cmapEditGUI(params);

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

params = get(hfig, 'UserData');
cmap = params.cmap;
% params = rmfield(params, 'cmap');
delete(hfig);

return
% /------------------------------------------------------------------/ %




% /------------------------------------------------------------------/ %
function params = cmapEditUpdate;
% update the color map editor GUI, based on the settings in the current
% figure.
params = get(gcf, 'UserData');

% modify the cmap according to any callback objects
if ishandle(gcbo)
    switch get(gcbo, 'Tag')
        case 'Shift'            % shift according to slider
            delta = round( get(gcbo, 'Value') );
            params.cmap = circshift(params.cmap, delta);
            set(gcbo, 'Value', 0);   % reset slider

        case 'Flip'             % flip cmap order
            params.cmap = flipud(params.cmap);

        case 'Reset'            % reset to original params
            params = get(gcbo, 'UserData'); % stashed here
            
        case 'NumColors'        % set # colors in cmap
            params.nColors = str2num(get(gcbo, 'String'));
            while size(params.cmap, 1) < params.nColors
                params.cmap = [params.cmap; params.cmap];
            end
            params.cmap = params.cmap(1:params.nColors,:);
            
        case 'Preset'           % use a preset color map
            params.cmap = mrvColorMaps(get(gcbo, 'Label'), params.nColors);            
            
        case 'ColorWheel'       % set to color wheel
            params.colorWheel = get(gcbo, 'Value');
            vals = {'off' 'on'};
            set(params.ui.colorWheelPanel, 'Visible', vals{params.colorWheel+1});
            
        case 'ColorWheelDirection' % set color wheel CW / CCW
            options = {'clockwise' 'counterclockwise'};            
            params.colorWheelDirection = options{ get(gcbo, 'Value') };
            
        case 'ColorWheelStart'  % set start angle for color wheel
            params.colorWheelStart = str2num(get(gcbo, 'String'));

        case 'ColorWheelExtent'  % set angle subtended by cmap
            params.colorWheelExtent = str2num(get(gcbo, 'String'));
            
    end
end

% draw the color bar
if params.colorWheel==1
    % draw a color wheel
    if isequal(lower(params.colorWheelDirection), 'clockwise')
        direction = 0;
    else                                               
        direction = 1; 
    end
    startAngle = params.colorWheelStart;
    if params.colorWheelExtent==360, p.visualField = 'b';
    else, p.visualField = 'l'; 
    end 
    p.doPlot = 0; p.trueColor = 1;
    image( cmapWedge(params.cmap, startAngle, direction, p));
    axis image; axis off;

else
    % draw a regular bar
    if isequal(params.clim, 'auto')
        clim = 1:params.nColors;
    else
        clim = params.clim;
    end
    image(clim, [], 1:params.nColors);
    set(gca, 'YTick', []);
    
end

% set axes to look nice
colormap(params.cmap);
title('Edit Color Map');

% update GUI figure
set(gcf, 'UserData', params);

return
% /------------------------------------------------------------------/ %




% /------------------------------------------------------------------/ %
function hfig = cmapEditGUI(params);
% creates the figure for cmapEdit.

%%%%% create figure, main axes
hfig = figure('Color', 'w', 'Name', 'Edit Color Map', 'MenuBar', 'none');
hax = subplot('Position', [.1 .7 .8 .16]); 


%%%%% callback for all uicontrols
cb = 'cmapEdit(gcf, ''update''); ';

%%%%%main slider
nC = params.nColors;
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
    'UserData', params, 'Units', 'normalized', 'Position', [.75 .5 .2 .05]);

% edit field for setting # of colors
uicontrol('Style', 'text', 'String', '# Colors in Cmap', 'Callback', cb, ...
    'BackgroundColor', 'w', 'FontSize', 10, 'FontWeight', 'bold', ...
    'UserData', params, 'Units', 'normalized', 'Position', [.75 .5 .2 .05]);

uicontrol('Style', 'edit', 'String', num2str(params.nColors), 'Callback', cb, ...
    'Tag', 'NumColors', 'Units', 'normalized', 'Position', [.75 .45 .15 .05]);



%%%%%% wedge params controls
% checkbox to set the colorbar as a color wheel (wedge)
uicontrol('Style', 'checkbox', 'String', 'Color Wheel (Wedge)', ...
          'Units', 'normalized', 'Position', [.1 .3 .4 .08], ...
          'BackgroundColor', 'w', 'FontSize', 10, 'FontWeight', 'bold', ...
          'Tag', 'ColorWheel', 'Callback', cb);

% put the subsidiary controls in a uipanel
hp = uipanel('Units', 'normalized', 'Position', [.4 .1 .5 .3], ...
             'BorderType', 'none', 'BackgroundColor', 'w');
params.ui.colorWheelPanel = hp;          
            
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
          'String', num2str(params.colorWheelStart), ...
          'BackgroundColor', 'w', ...
          'Units', 'normalized', 'Position', [.6 .35 .3 .25], ...
          'Tag', 'ColorWheelStart', 'Callback', cb);

% edit field to set the color wheel extent
uicontrol('Parent', hp, 'Style', 'text', 'String', 'Extent', 'Callback', cb, ...
          'BackgroundColor', 'w', 'Units', 'normalized', 'Position', [.1 .05 .4 .25]);

uicontrol('Parent', hp, 'Style', 'edit', ...
          'String', num2str(params.colorWheelExtent), ...
          'Units', 'normalized', 'Position', [.6 .05 .4 .25], ...
          'BackgroundColor', 'w', ...
          'Tag', 'ColorWheelExtent', 'Callback', cb);
      
set(hp, 'Visible', 'off');

          
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

set(hfig, 'CloseRequestFcn', 'uiresume;', 'UserData', params);

cmapEditUpdate;

return

