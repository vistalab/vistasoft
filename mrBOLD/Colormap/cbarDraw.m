function h = cbarDraw(cbar, parent);
%
% h = cbarDraw(cbar, [parent=gca]);
%
% Render a color bar, according to the settings specified in the cbar
% struct.
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
% ras, 08/2006
if ~exist('cbar', 'var') | isempty(cbar), cbar = cbarDefault; end
if ~exist('parent', 'var') | isempty(parent), parent = gca; end

if cbar.colorWheel==1
    % draw a color wheel
    if isequal(lower(cbar.colorWheelDirection), 'clockwise')
        direction = 0;
    else                                               
        direction = 1; 
    end
    startAngle = cbar.colorWheelStart;
	cmap = cbar.cmap;	
	p.doPlot = 0; p.trueColor = 1; p.background = get(gcf, 'Color');
	p.visualField = 'b'; % 'both' fields in cmapWedge    
	h = image(cmapWedge(cmap, startAngle, direction, p), 'Parent', parent);
    axis(parent, 'image'); axis(parent, 'off');
    
%     AX = axis;
%     xText = AX(2) + .1*(AX(2)-AX(1));
%     yText = AX(3) + .5*(AX(4)-AX(3));
%     text(xText, yText, cbar.label, 'Parent', parent);
    
%     % correct funky aspect ratios (gum):
%     pos = get(parent, 'Position');
%     aspectRatio = pos(3) / pos(4);
%     if aspectRatio > 4 | aspectRatio < 1/4
%         set(parent, 'Position', [pos(1) 0 pos(3) 1]);
%     end

    
elseif isequal(cbar.direction, 'horiz');
    % draw a horizontal bar
    if isequal(cbar.clim, 'auto') | isempty(cbar.clim)
        clim = [1 cbar.nColors];
    else
        clim = cbar.clim;
    end
    img = ind2rgb(1:cbar.nColors, cbar.cmap);
	
	% show the image
	% (The Y values maintain an aspect ratio of 35:1)
	aspRatio = 1/15;
    h = image(clim, clim ./ aspRatio, img, 'Parent', parent);
	
% 	axis(parent, 'image'); 
% 	axis(parent, [clim clim .* aspRatio]);
    set(parent, 'YTick', []);
    cbar.label(cbar.label=='_') = '-';
    xlabel(parent, cbar.label, 'FontSize', cbar.fontsz, ...
		  'FontName', cbar.font, 'Interpreter', 'none');
    
else
    % draw a vertical bar
    if isequal(cbar.clim, 'auto')
        clim = [1 cbar.nColors];
    else
        clim = cbar.clim;
	end
    img = ind2rgb([cbar.nColors:-1:1]', cbar.cmap);

	% show the image
	% (The X values maintain an aspect ratio of 15:1)
	aspRatio = 1/15;
	h = image(clim ./ 20, fliplr(clim), img, 'Parent', parent);
	
% 	axis(parent, 'image'); 
	axis(parent, [clim .* aspRatio, clim]);
    set(parent, 'XTick', [], 'Ydir', 'normal');
	if checkfields(cbar, 'labelSide') & cbar.labelSide==1
		set(parent, 'YAxisLocation', 'right');
	end
    cbar.label(cbar.label=='_') = '-';
    ylabel(parent, cbar.label, 'FontSize', cbar.fontsz, ...
			'FontName', cbar.font, 'Interpreter', 'none');
    
end


return
