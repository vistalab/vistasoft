function mrViewScreenshot(ui, imgPath, varargin);
%
% mrViewScreenshot([ui], [imgPath='Images/mrViewer.jpg'], [options]);
%
% Take and save a screenshot of the main mrViewer display. 
% This reproduces the overlay and colorbar images in a separate
% figure, and exports it to the specified file. By default, it then
% closes the figure.
%
% Options include:
%   * 'format', [val]: set the format for the saved image. By default,
%   infers this from the imgPath extension.
%   Available formats: .jpg, .png, .fig, .tiff, .eps, .eps2, preview
%
%   * 'dpi', [val]: set the dots per inch for the exported figure. 
%   Only used if the format is 'jpg', 'png', 'eps', or 'preview'.
%
%   * 'Color', {'bw' | 'gray' | 'cmyk'}: Color format for the image, again
%   only for the same formats as 'dpi'.
%
%   * 'Mesh': Attach an image of the current mesh view in addition
%   to the mrViewer display in the image. [NOT YET IMPLEMENTED]
%   
%   * 'keep': don't close the image figure which is created for the
%   screenshot. Closes it by default.
%   
%
%
% ras, 11/2006.
if notDefined('ui'), ui = mrViewGet; end
if ischar(ui), ui = str2num(ui); end
if ishandle(ui), ui = get(ui, 'UserData'); end

if notDefined('imgPath'), imgPath = 'Images/mrViewer.jpg'; end

ensureDirExists( fileparts(imgPath) );

%% parse params
% defaults
formatList = {'.jpg' '.png' '.fig' '.tiff' '.eps' '.eps2' 'preview'};
[p f ext] = fileparts(imgPath);
if ismember(lower(ext), formatList) 
    format = lower(ext);
else
    format = '.jpg';
end
color = 'cmyk';
dpi = 300;
meshFlag = 0;
keepFlag = 1;
    

% parse options
for i = 1:length(varargin)
    if ischar(varargin{i})
        switch lower(varargin{i})
            case 'format', format = varargin{i+1};
            case 'dpi', dpi = varargin{i+1};
            case 'color', color = varargin{i+1};
            case 'mesh', meshFlag = 1;
            case 'keep', keepFlag = 1;
        end
    end
end


%% create the figure
hfig = figure('Color', 'w');

% display main image
mrViewDisplay(ui, hfig);

% add colorbars
if isfield(ui, 'overlays')
	for i = 1:length(ui.overlays)
		hp(i) = mrvPanel('below', 100, hfig, 'pixels'); 
		set(hp(i), 'Units', 'norm', 'BackgroundColor', 'w');
		hax(i) = axes('Parent', hp(i), 'Units', 'norm', 'Position', [.3 .5 .4 .2]);
		cbarDraw(ui.overlays(i).cbar, hax(i));

		if ui.overlays(i).cbar.colorWheel==1
			set(hax(i), 'Position', [.25 .2 .5 .5]);
		end
	end
end

%% save the image
if ismember(format, {'.jpeg' '.png', '.eps' '.eps2' 'preview'})
    exportfig(hfig, imgPath, 'Format', format(2:end), 'Color', color, ...
              'Resolution', dpi);
else
    saveas(hfig, imgPath, format(2:end));
end
fprintf('Saved image %s.\n', imgPath);


%% clean up
if keepFlag==0
    close(hfig);
end


return
