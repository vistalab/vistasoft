% FORMATFIGURE: Formats Matlab figures
%
% FormatFigure( FIG, FONTNAME, FONTSIZE, FIGSIZE, BORDER )
%
% Formats a figure for presentations or papers.  The font
% style, font size, figure size and border size can all be
% adjusted.  All parameters are optional.
%
% FIG     : Figure handle.
% FONTNAME: Name of the font as a string.
% FONTSIZE: Size of the font (points) as a vector. 
%           Format: [axes_labels tick_labels]
% FIGSIZE : Size of the figure (inches) as a vector.
%           Format: [width height]
% BORDER  : Space around the figure (inches) as a vector.
%           Format: [left bottom right top] or
%                   [left/right  botom/top]
%
% Default settings of the inputs are:
%   FIG     : gcf (current figure)
%   FONTNAME: 'Helvetica'
%   FONTSIZE: [18 14]
%   FIGSIZE : [6 6]
%   BORDER  : [0.8 0.5]
%
% Note: Function has a problem settiing the font size of the
% legend sometimes.  If the legend font is the wrong size,
% call this function again.  The second call corrects the
% problem.  I believe this to be a Matlab problem.
%
% Written By  : Jeffrey DiCarlo
% Last updated: 07-26-00

function FormatFigure( fig, fontname, fontsize, figsize, border )

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Format the input parameters.

% Load default paramemters.

if (~exist('fig','var'))
   fig = 0;
end
if (~exist('fontname'))
   fontname = 'Helvetica';
end
if (~exist('fontsize'))
   fontsize = [18 14];
end
if (~exist('figsize'))
   figsize  = [6 6];
end
if (~exist('border'))
   border = [0.8 0.5];
end

% Check the fontsize.

if (length(fontsize) == 1)
   fontsize = [fontsize fontsize];
end

% Check the figure size.

if (length(figsize) == 1)
   figsize = [figsize figsize];
end

% Check the border.

if (length(border) == 2)
   border = [border(1) border(1) border(2) border(2)];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the figure axes.

if (exist('fig') ~= 1 | fig == 0)
   fig = gcf;
end
axs = get( fig, 'CurrentAxes' );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the current figure position.

if (strcmp(get(fig, 'Units'),'inches') == 1)
   pos = get(fig, 'Position');
else
   pos = [1 1 1 1];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set the figure properties.

set( fig,         'Units', 'inches' );
set( fig,      'Position', [pos(1:2) figsize] );
set( fig, 'PaperPosition', [4.25-figsize(1)/2 5.5-figsize(2)/2 figsize] );
set( fig,         'Color', [1 1 1] );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set the axes properties.

set( get(axs,  'Title'), 'FontName', fontname, ...
   'FontSize', fontsize(1) );
set( get(axs, 'XLabel'), 'FontName', fontname, ...
	'FontSize', fontsize(1) );
set( get(axs, 'YLabel'), 'FontName', fontname, ...
   'FontSize', fontsize(1) );
set( get(axs, 'ZLabel'), 'FontName', fontname, ...
   'FontSize', fontsize(1) );
set( axs,                'FontName', fontname, ...
   'FontSize', fontsize(2) );

set( axs,    'Units', 'inches' );
set( axs, 'Position', [border(1:2) (figsize-border(1:2)-border(3:4))] );

