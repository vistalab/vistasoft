function h = displayVol(M, slice, cmap, clim, createFlag)
% h = displayVol(M, [slice], [cmap], [clim]);
%
% Display a 3-D matrix M with some basic UI
% controls. If M is a file path,  will try
% to read the file using loadVolume.
%
%
% Controls include:
%   * a slider for selecting which slice (3rd-dim)
%    of the 3-D matrix to show (+ edit field)
%
%   * brightness/contrast sliders [warning: contrast
%                                   is not really contrast
%                                   but just clipping]
%   * a 'play' button for paging through slices as a movie 
%   (useful if your matrix actually is a set
%   of 2-D images over time)
%   
%   * imclick button: lets you click on small regions of
%     the displayed image and get the values at and around
%     that voxel
%   
%   * histogram: make a figure with a histogram of values for
%     the current slice [ignores values <= 0]
%       
% slice specifies the slice to start off viewing. Defaults to 1.
%
% cmap is an optional color map. If omitted, 
% it defaults to a grayscale colormap.
%
% 07/03 by ras.
% 04/04 ras; heavily updated.
% 02/05 ras: more updates,  added to VISTASOFT repository
% 07/05 ras: imported into mrVista 2.0 repository
% 12/07 ras: added clim argument.
if ~exist('cmap', 'var') || isempty(cmap)
    cmap = [];              
end

if ~exist('createFlag','var') || isempty(createFlag)
    % this variable tells the code whether
    % the function is being called as a callback
    % or not. Should only be 0 if it's being called
    % as a callback -- then M should be a handle
    % to the figure
    createFlag = 1;
end

if ~exist('slice', 'var') || isempty(slice)
    if createFlag==1
        slice = 1;              
    else
        % callback: get from UI
        vol = get(M, 'UserData');
        slice = get(vol.handles.sliceSlider, 'Value');
    end
end

if ~exist('clim', 'var') || isempty(clim)
	clim = [];
end

% if a file path is provided, load the volume from that file
if ischar(M)  % file path
    M = loadVolume(M);
end

% also allow a cell-of-images to be passed in
if iscell(M)
	tmp = M;
	M = M{1};
	for z = 2:length(tmp)
		M = cat(3, M, tmp{z});
	end
end

% check that matrix is no more than 3D
if ndims(M)>3
    M = M(:,:,:,1);
end

% if a 3D matrix is passed,  set up a new window
% for the matrix. Otherwise,  assume the function
% was called as a callback from a uicontrol,  and the
% first argument is a handle to the proper figure
if createFlag==1
    h = openDisplayVolFig(M, cmap, clim);
    varname = sprintf('%s  [displayVol]', inputname(1));
    set(h, 'Name', varname);
else
    % we'll get the data and refresh below
    h = M;
end

switch slice
    case -1,  displayVolMovie;   return;
    case -2,  displayVolUpdatePrefs;     return;
    case -3,  displayVolHistogram;     return;
    case -4,  displayVolReorient;      return;
    case -5,  displayVolColorbar;      return;
    case -6,  displayVolTimeCourse;      return;
    otherwise,  % we'll just update the slice below
end

%----- refresh the window by displaying the selected slice ----- %
slice = round(slice);

vol = get(h, 'UserData');

set(vol.handles.sliceSlider, 'Value', slice);
set(vol.handles.sliceEdit, 'String', num2str(slice));

% set contrast
contrast = get(vol.handles.contrastSlider, 'Value');
if contrast ~= 0.5
    vol.clipMax = vol.clipMin + (max(vol.M(:))-vol.clipMin)*(1-contrast);
end

% produce final image
img = vol.M(:,:,slice);

% display
axes(vol.handles.axes);
hold off
if vol.autoClip==1
    imagesc(img);
    
elseif vol.clipMax > vol.clipMin
    imagesc(img, [vol.clipMin vol.clipMax]);
    
else
    imagesc(img); 
    
end

colormap(vol.cmap);

if isequal(get(vol.handles.aspect, 'Checked'), 'on')
    axis equal
end
axis off

% update colorbar if selected
if isfield(vol.handles, 'cbar') & ishandle(vol.handles.cbar)
    delete(vol.handles.cbar); 
    vol.handles.cbar = subplot('Position', [.9 .3 .03 .6]);    
    colorbar(vol.handles.cbar, 'peer', vol.handles.axes);
end

set(gcf, 'UserData', vol);

return
% /-------------------------------------------------------------/ %




% /-------------------------------------------------------------/ %
function h = openDisplayVolFig(M, cmap, clim)
% Opens a figure with the UI controls 
% in place,  and a struct 'vol' stored
% as the figure's userdata,  containing
% both the matrix M and some prefs.
if isempty(cmap)
    cmap = gray(256);   
    cmapName = 'gray';
else
    cmapName = 'custom';
end

% build the vol struct
vol.M = M;
vol.clipMin = min(M(:));
vol.clipMax = max(M(:));
vol.autoClip = 0;
vol.cmap = cmap;
vol.cmapName = cmapName;
vol.fps = 5;
vol.orientation = [1 2 3]; % dimension order

% if a nonempty color limit has been specified, use that instead of
% the default min/max values:
if ~isempty(clim)
	vol.clipMin = clim(1);
	vol.clipMax = clim(2);
end

% open the fig
h = figure('Units', 'Normalized', ...
    'Position', [.3 .3 .5 .5], ...
    'UserData', vol, ...
    'Color', [.9 .9 .9], ...
    'NumberTitle', 'off', ...
    'MenuBar', 'none', ...
    'NextPlot', 'add', ...
    'Tag', 'displayVolFig');

% add the main axis
vol.handles.axes = axes('Position', [0 .15 1 .85]);

% add a frame for the controls
frameColor = [.8 .8 .8];
vol.handles.frame = uicontrol('Style', 'frame', ...
    'Units', 'Normalized', ...
    'Position', [0 0 1 .15], ...
    'BackgroundColor', frameColor);

% add a slider to set the slice
nSlices = size(vol.M, 3);
if nSlices > 1
    cbstr = 'z = get(gcbo, ''Value''); displayVol(gcf, z, [], [], 0);';
    vol.handles.sliceSlider = uicontrol('Style', 'slider', ...
        'Units', 'Normalized', ...
        'Position', [.05 .1 .3 .03], ...
        'Min', 1, 'Max', nSlices, ...
        'Value',  1, ...
        'BackgroundColor', frameColor, ...                           
        'SliderStep', [1/(nSlices-1) 2/(nSlices-1)], ...
        'Callback', cbstr);
else
    vol.handles.sliceSlider = uicontrol('Style', 'slider', ...
        'Units', 'Normalized', ...
        'Position', [.05 .1 .3 .03], ...
        'Min', 1, 'Max', nSlices, ...
        'Value',  1, ...
        'Visible', 'off');
end

% add text for the slice edit field
vol.handles.sliceText = uicontrol('Style', 'text', 'Units', 'Normalized', ...
    'Position', [.05 .05 .1 .05], ...
    'BackgroundColor', frameColor, 'String', 'Slice:');

% add the slice edit field
cbstr = 'z = str2num(get(gcbo, ''String'')); displayVol(gcf, z, [], [], 0);';
vol.handles.sliceEdit = uicontrol('Style', 'edit', ...
    'Units', 'Normalized', ...
    'Position', [.15 .05 .05 .05], ...
    'String', '1', ...
    'BackgroundColor', frameColor, ...
    'Callback', cbstr);                           

% add brighten buttons
uicontrol('style', 'pushbutton', 'units', 'normalized', 'position', [.4 .1 .1 .03], ...
    'string', '<<', 'backgroundcolor', frameColor, 'Callback', 'brighten(-0.3);');
uicontrol('style', 'pushbutton', 'units', 'normalized', 'position', [.52 .1 .1 .03], ...
    'string', '>>', 'backgroundcolor', frameColor, 'Callback', 'brighten(0.3);');

% add text for the brightness field
uicontrol('Style', 'text', 'Units', 'Normalized', 'Position', [.4 .05 .1 .05], ...
    'BackgroundColor', frameColor, 'String', 'Brightness');

% add a slider to set the contrast
cbstr = 'displayVol(gcf, [], [], [], 0);';
vol.handles.contrastSlider = uicontrol('Style', 'slider', ...
    'Units', 'Normalized', ...
    'Position', [.7 .1 .25 .03], ...
    'Min', 0, 'Max', 1, ...
    'Value',  0.5, ...
    'BackgroundColor', frameColor, ...
    'Callback', cbstr);

% add text for the contrast field
uicontrol('Style', 'text', 'Units', 'Normalized', 'Position', [.7 .05 .1 .05], ...
    'BackgroundColor', frameColor, 'String', 'Contrast');

% add a time course button
vol.handles.tc = uicontrol('Style', 'pushbutton', ...
    'Units', 'Normalized', ...
    'Position', [.5 .02 .15 .03], ...
    'String', 'Time Course', ...
    'Callback', 'displayVol(gcf, -6, [], [], 0);');

% add a prefs button
vol.handles.prefs = uicontrol('Style', 'pushbutton', ...
    'Units', 'Normalized', ...
    'Position', [.85 .02 .1 .03], ...
    'String', 'Prefs', ...
    'Callback', 'displayVol(gcf, -2, [], [], 0);');

% add a histogram button
vol.handles.histogram = uicontrol('Style', 'pushbutton', ...
    'Units', 'Normalized', ...
    'Position', [.75 .02 .1 .03], ...
    'String', 'Histogram', ...
    'Callback', 'displayVol(gcf, -3, [], [], 0);');

% add an imclick button
cbstr = ['h = mrMessage(''Left Click to get image values at a '...
        'point on the image. Right Click to end.''); imclick;'...
        'close(h);'];
vol.handles.imclick = uicontrol('Style', 'pushbutton', ...
    'Units', 'Normalized', ...
    'Position', [.65 .02 .1 .03], ...
    'String', 'Imclick', ...
    'Callback', cbstr);


%%%%%%%%%%%%%%%%
% Menu Options %
%%%%%%%%%%%%%%%%
vol.handles.menu = uimenu('Label', 'DisplayVol Options');
uimenu('Label', '     '); % spacer

% add an aspect ratio menu
vol.handles.aspect = uimenu('Parent', vol.handles.menu, ...
    'Label', 'Preserve Aspect', ...
    'Checked', 'on',  ...
    'Separator', 'off', ...
    'Callback', 'umtoggle(gcbo); displayVol(gcf, [], [], [], 0);');

% add an aspect ratio menu
vol.handles.cbarToggle = uimenu('Parent', vol.handles.menu, ...
    'Label', 'Colorbar', ...
    'Checked', 'off',  ...
    'Separator', 'off', ...
    'Callback', 'umtoggle(gcbo); displayVol(gcf, -5, [], [], 0);');

% add a play ratio menu
vol.handles.play = uimenu('Parent', vol.handles.menu, ...
    'Label', 'Play Through Slices', ...
    'Separator', 'on', ...
    'Callback', 'displayVol(gcf, -1, [], [], 0);');

addFigMenuToggle(vol.handles.menu);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Buttons to flip axes around %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% show Y | X (2nd dim over first dim)
cbstr = ['vol=get(gcf, ''UserData''); '...
        'ori=get(gcbo, ''UserData''); '...
        'selectButton(vol.handles.orient, ori);'...
        'displayVol(gcf, -4, [], [], 0);'];
vol.handles.orient(1) = uicontrol('Style', 'radiobutton', ...
    'Units', 'Normalized', ...
    'Position', [0.02 .01 .1 .04], ...
    'String', 'Y | X', ...
    'UserData', 1, ...
    'BackgroundColor', frameColor, ...
    'Callback', cbstr);
vol.handles.orient(2) = uicontrol('Style', 'radiobutton', ...
    'Units', 'Normalized', ...
    'Position', [.12 .01 .1 .04], ...
    'String', 'Y | Z', ...
    'UserData', 2, ...
    'BackgroundColor', frameColor, ...
    'Callback', cbstr);
vol.handles.orient(3) = uicontrol('Style', 'radiobutton', ...
    'Units', 'Normalized', ...
    'Position', [.22 .01 .1 .04], ...
    'String', 'Z | X', ...
    'UserData', 3, ...
    'BackgroundColor', frameColor, ...
    'Callback', cbstr);
selectButton(vol.handles.orient, 1);

% flip L/R button
cbstr = ['vol=get(gcf, ''UserData''); vol.M=flipdim(vol.M, 2); ' ...
        'set(gcf, ''UserData'', vol); displayVol(gcf, [], [], [], 0);'];
vol.handles.fliplr = uicontrol('Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [.32 .015 .08 .03], 'String', 'Flip L\R', ...
    'BackgroundColor', frameColor, 'Callback', cbstr);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If only 1 slice,  hide irrelevant controls %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nSlices==1
    set(vol.handles.sliceEdit, 'Visible', 'off');
    set(vol.handles.sliceText, 'Visible', 'off');
    set(vol.handles.orient, 'Visible', 'off');
    set(vol.handles.tc, 'Visible', 'off');
end

set(gcf, 'UserData', vol);

return
% /-------------------------------------------------------------/ %




% /-------------------------------------------------------------/ %
function displayVolMovie;
% Play the volume from the 
% current slice to the end,  like
% a movie.
vol = get(gcf, 'UserData');
nSlices = size(vol.M, 3);
currSlice = str2num(get(vol.handles.sliceEdit, 'String'));
for z = currSlice:nSlices
    displayVol(gcf, z, [], [], 0);
    pause(1/vol.fps);
end
return
% /-------------------------------------------------------------/ %




% /-------------------------------------------------------------/ %
function displayVolUpdatePrefs;
% set up an input dialog to get prefs
vol = get(gcf, 'UserData');
prompt = {...
        'clipMin:', ...
        'clipMax:', ...
        'Find clip vals for each slice? [1 for yes,  0 for no]', ...
        'Frames Per Second:', ...
        'Color Map:', ...
    };
defaults = {num2str(vol.clipMin), ...
        num2str(vol.clipMax), ...
        num2str(vol.autoClip), ...
        num2str(vol.fps), ...
        vol.cmapName};
AddOpts.Resize = 'on';
AddOpts.Interpreter = 'tex';
AddOpts.Interpreter = 'Normal';
answers = inputdlg(prompt, 'displayVol prefs...', 1, defaults);
vol.clipMin = str2num(answers{1});
vol.clipMax = str2num(answers{2});
vol.autoClip = str2num(answers{3});
vol.fps = str2num(answers{4});
if ~isequal(answers{5}, 'custom')
    vol.cmapName = answers{5};
    vol.cmap = eval(answers{5}, 256);
end
set(gcf, 'UserData', vol);
displayVol(gcf, [], [], [], 0);
return
% /-------------------------------------------------------------/ %



% /-------------------------------------------------------------/ %
function displayVolHistogram;
% plot a histogram of the current slice
vol = get(gcf, 'UserData');
slice = get(vol.handles.sliceSlider, 'Value');
sliceData = vol.M(:, :, slice);
nbins = round(prod(size(sliceData))/100);
newpos = get(gcf, 'Position');
newpos(3:4) = newpos(3:4) ./ 2;
newpos(1:2) = newpos(1:2) + newpos(3:4)/2;
figure('Units', 'Normalized', 'Position', newpos, 'Color', 'w');
hist(sliceData(sliceData>0), nbins);
xlabel('Voxel Value');
ylabel('# Voxels');
title(sprintf('Histogram Slice %i', slice));
return
% /-------------------------------------------------------------/ %



% /-------------------------------------------------------------/ %
function displayVolColorbar;
% toggle a color bar for the volume
vol = get(gcf, 'UserData');
if isequal(get(vol.handles.cbarToggle, 'Checked'), 'on')
    % cbar doesn't exist -- make it
    oldsz = get(vol.handles.axes, 'Position');
    set(vol.handles.axes, 'Position', [oldsz(1:2) oldsz(3)*.85 oldsz(4)]);
    vol.handles.cbar = subplot('Position', [.9 .3 .03 .6]);
    colorbar(vol.handles.cbar, 'peer', vol.handles.axes);
else
    % cbar exists -- turn off
    delete(vol.handles.cbar);
    oldsz = get(vol.handles.axes, 'Position');
    set(vol.handles.axes, 'Position', [oldsz(1:2) oldsz(3)/.85 oldsz(4)]);
end
set(gcf, 'UserData', vol);
return
% /-------------------------------------------------------------/ %




% /-------------------------------------------------------------/ %
function displayVolReorient;
% permute the volume matrix M to reflect a new orientation;
% check the slice UI settings
vol = get(gcf, 'UserData');
ori = findSelectedButton(vol.handles.orient);
switch ori
    % get a target order of dimensions,  
    % relative to the original dimension order
    % (the first 2 dims are plotted,  the 3rd is slices)
    case 1,  tgtOrder = [1 2 3]; % [Y X Z]
    case 2,  tgtOrder = [1 3 2]; % [Y Z X]
    case 3,  tgtOrder = [3 2 1]; % [Z X Y];
end
% based on the current orientation, 
% the order given to the permute command
% will vary:
for i = 1:3
    permuteOrder(i) = find(vol.orientation==tgtOrder(i));
end
vol.M = permute(vol.M, permuteOrder);
vol.orientation = tgtOrder;
% check slice UI for out-of-bounds
nSlices = size(vol.M, 3);
slice = get(vol.handles.sliceSlider, 'Value');
if slice > nSlices
    set(vol.handles.sliceSlider, 'Value', 1);
end
set(vol.handles.sliceSlider, 'Max', nSlices);
set(gcf, 'UserData', vol);
displayVol(gcf, [], [], [], 0);
return
% /-------------------------------------------------------------/ %



% /-------------------------------------------------------------/ %
function displayVolTimeCourse;
% allow user to click on voxels,  and plot the time course
% data: that is,  the values at that (x, y) location,  across 
% all slices (z). 
vol = get(gcf, 'UserData');
slice = get(vol.handles.sliceSlider, 'Value');
sliceData = vol.M(:, :, slice);

nbins = round(prod(size(sliceData))/100);
newpos = get(gcf, 'Position');
newpos(3:4) = newpos(3:4) ./ 2;
newpos(1) = newpos(1) + 2*newpos(3);

h1 = figure('Units', 'Normalized', 'Position', newpos, 'Color', 'w');
a1 = axes;
hold off;
msg = 'Click on location to get time course. Right-click to stop.';
h2 = mrMessage(msg);

b = 0;
while b~=3 & b~=2
    axes(vol.handles.axes);
    hold on
  	[x, y, b] = ginput(1);
    x = round(x); y = round(y);
    if exist('h3', 'var')  delete(h3);   end
    h3 = plot(x, y, 'sc');

    if b==3 | b==2  break;  end

    axes(a1)
    plot(squeeze(vol.M(y, x, :)), 'LineWidth', 1.5);
    xlabel('Z Dimension (slice)');
    ylabel('Value (pix intensity)');
    grid on;
    title(sprintf('Time Course row %i,  column %i', y, x));
end

close(h2);
if exist('h3', 'var')  delete(h3);   end
return
% /-------------------------------------------------------------/ %
