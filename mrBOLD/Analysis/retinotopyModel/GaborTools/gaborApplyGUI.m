function [h U] = gaborApplyGUI(img, G);
% Create a graphical user interface for visualizing the application of a
% Gabor wavelet pyramid to an image or set of images.
%
% [h U] = gaborApplyGUI(<img=dialog for image file>, <G>);
%
% This GUI will display the image, the contrast energy across channels
% resulting from application of a gabor pyramid to the image, and one of
% the Gabor channels. It will let the user browse across different
% channels, observing what the wavelet looks like for that channel, and
% offer other tools for understanding how the projection decomposes the
% image. 
%
% If more than one image is loaded (for instance, img is a cell array),
% there will be a popup to select different images.
%
% Returns h, a handle to the GUI figure.
%
% ras, 04/01/08.
if notDefined('G'), G = []; end
if notDefined('img')
	f = {'jpg' 'png'  'tiff'};
	img = mrvSelectFile('r', f, 'Select an image file');
end

%% Are we just refreshing an existing GUI?
if isequal(img, 'refresh')
	[h U] = gaborApplyGUI_refresh(gcf);
	return
end

%% Create a user-data structure for the GUI
% this will reside in the main figure's UserData, and contain all the
% information needed for the GUI.
U = G;
[U.ce U.filt_even U.filt_odd U.img] = gaborApply(img, G);


%% Create the GUI figure
bgCol = [.9 .9 .9];  % background color
h = figure('Color', bgCol, 'Units', 'norm', 'Position', [.3 .3 .5 .5], ...
			'NumberTitle', 'off', 'Name', 'Gabor Apply GUI', ...
			'UserData', U);
colormap( mrvColorMaps('gray') );


%% Create a plot for the contrast energy
U.cePlot = subplot('Position', [.1 .2 .4 .5]);

scrollbar; 

% % we allow the user to hold the plots, so the contrast energy for many
% % pictures can be superimposed.
% cb = 'hold( get(gcbo, ''UserData'') ); ';
% uicontrol('Style', 'checkbox', 'String', 'hold', 'Value', 0, ...
% 		  'Units', 'norm', 'Position', [.05 .05 .12 .06], ...
% 		  'Callback', cb, 'BackgroundColor', bgCol,  'UserData', U.cePlot);
	 
% provide a slider to select the channel
U.selectedChannel = 2;
cb = ['U = get(gcf, ''UserData''); ' ...
	  'cla(U.cePlot); ' ...
	  'U.selectedChannel = round(val); ' ...
	  'set(gcf, ''UserData'', U); ' ...
	  'gaborApplyGUI(''refresh''); clear U '];
U.chSlider = mrvSlider([.1 .8 .25 .08], 'Channel', 'Callback', cb, ...
		  'Range', [1 U.nChannels], 'Value', U.selectedChannel, 'IntFlag', 1);
	  
	  
%% Create a set of axes in which to display the image
U.imPlot = subplot('Position', [.6 .5 .3 .3]);

% if many images are provided, make a slider for selecting an image;
U.selectedImage = 1;
if size(U.img, 3) > 1
	cb = ['U = get(gcf, ''UserData''); ' ...
		  'if ~ishold(U.cePlot), cla(U.cePlot); end; ' ...
		  'U.selectedImage = round(val); ' ...
		  'set(gcf, ''UserData'', U); ' ...
		  'gaborApplyGUI(''refresh''); clear U '];
	U.imSlider = mrvSlider([.6 .9 .25 .08], 'Image', ...
			  'Range', [1 size(U.img, 3)], ...
			  'Value', 1, 'IntFlag', 1, 'Callback', cb);
end

%% Create a set of axes in which to display the current wavelet channel
U.chPlot = subplot('Position', [.6 .15 .3 .3]);

% create buttons to select the odd or even channel
U.selectedPhase = 1;
phaseNames = {'Even' 'Odd'};
pos = {[.6 .05 .1 .06] [.7 .05 .1 .06]};
for ii = 1:2
	htmp(ii) = uicontrol('Style', 'radiobutton', 'String', phaseNames{ii}, ...
						'Units', 'norm', 'Position', pos{ii}, ...
						'BackgroundColor', bgCol, 'Value', ii-1);
end

for ii = 1:2
	cb = ['U = get(gcf, ''UserData''); ' ...
		  'U.selectedPhase = ' num2str(ii) '; ' ... 
		  'selectButton( get(gcbo, ''UserData''), ' num2str(ii) ' ); ' ...
		  'set(gcf, ''UserData'', U); ' ...
		  'gaborApplyGUI(''refresh''); clear U '];
	set(htmp(ii), 'UserData', htmp, 'Callback', cb);
end

% create a checkbox for showing the image filtered with this channel,
% rather than the channel itself.
U.showFilteredImage = 0;
cb = ['U = get(gcf, ''UserData''); ' ...
	  'U.showFilteredImage = get(gcbo, ''Value''); ' ...
	  'set(gcf, ''UserData'', U); ' ...
	  'gaborApplyGUI(''refresh''); clear U '];
uicontrol('Style', 'checkbox', 'String', 'Show Filtered Image', 'Value', 0, ...
		  'Units', 'norm', 'Position', [.82 .05 .12 .06], ...
		  'Callback', cb, 'BackgroundColor', bgCol);

%% create a little 'status LED' image to show whether the GUI is updating
U.statusAxes = subplot('Position', [.05 .9 .05 .05]);
U.statusLED = plot(0, 0, 'o', 'MarkerSize', 10, 'MarkerEdgeColor', 'r', ...
				   'MarkerFaceColor', 'r');
set(gca, 'Color', bgCol);  axis off			   
	  
%% perform an initial refresh
set(h, 'UserData', U);
gaborApplyGUI_refresh(h);

return
% /-----------------------------------------------------------------/ %



% /-----------------------------------------------------------------/ %
function [h U] = gaborApplyGUI_refresh(h);
U = get(h, 'UserData');

%% set the status LED to show a red circle: wait until we've updated
set(U.statusLED, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r');
drawnow;

%% get color order and symbol order
colors = jet(16);
symbols = {'x' 'o' 's' 'd' 'p' '^' '*' '>'};
	
%% some convenient shorthand for variables
ii = U.selectedImage;
ch = U.selectedChannel;

%% plot contrast energy
axes(U.cePlot);

% to plot the various lines, we need to set hold on, and remove
% some existing lines:
% delete(findobj('Tag', 'CurChannel', 'Parent', gca));
% holdState = ishold;
cla
hold on

% because there may be contrast energy plots held for other images, figure
% out what color to use based on how many lines already exist
n = mod( length(findobj('Parent', gca, 'Tag', 'ce')), 16 ) + 1;

% plot separate lines (w/ distinct symbols) for each layer
for layer = unique(U.layer)
	X = find(U.layer==layer);
	plot(X, U.ce(X,ii), 'LineWidth', 1.5, 'Tag', 'ce', ...
			'Color', colors(n,:), 'Marker', symbols{layer}, ...
			'MarkerSize', 3);
	ylabel('Contrast Energy (arb units)', 'FontSize', 14);
	xlabel('Wavelet Channel', 'FontSize', 14);
end

% highlight the selected channel
AX = axis;
line([ch ch], AX(3:4), 'Color', 'k', 'LineStyle', '--', ...
	 'LineWidth', 2.5, 'Tag', 'CurChannel');


% add a button-down function which allows the user to select the channel
bdf = ['U = get(gcf, ''UserData''); ' ...
	   'pt = get(gca, ''CurrentPoint''); ' ...
	   'U.selectedChannel = round(pt(1)); ' ...
	   'mrvSliderSet(U.chSlider, ''Value'', U.selectedChannel); ' ...
	   'set(gcf, ''UserData'', U); ' ...
	   'gaborApplyGUI(''refresh''); clear U pt'];
set(gca, 'ButtonDownFcn', bdf);

% % restore the previous hold state
% if holdState==1, hold on, else, hold off; end

%% show selected image
axes(U.imPlot);

imagesc(U.img(:,:,ii));
axis image; axis off;


%% show selected wavelet channel
axes(U.chPlot);

% figure out which field to show, based whether the user has selected even
% or odd phase, and filtered image or raw channel
if U.selectedPhase==1, f = 'even'; else, f = 'odd'; end
if U.showFilteredImage==1, z = ii; f = ['filt_' f]; else, z = 1; end

% show the relevant field, and channel number
imagesc( U.(f)(:,:,ch,z) );
axis image; axis off;

%% done updating: set the status LED to green
set(U.statusLED, 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'g');
drawnow;

return
