function [new_slide pic] = pptPaste(op, fig, fmt, ttl);
% Paste the contents of a MATLAB figure into a powerpoint presentation.
% 
% [new_slide, pic] = pptPaste(op, fig, fmt, ttl);
% 
% Replacement for saveppt, which crashes with gusto. The ActiveX PowerPoint
% file should already be opened with pptOpen (op is the project object). 
% fig is a handle to the figure to paste. fmt is a format string: 'meta'
% or 'bitmap'. Defaults to bitmap.  
%
% If the optional 'ttl' argument is specified as a character string,
% then the slide will be created with the text set as the appropriate
% title. (The code will automatically set the title text to be a bit
% smaller than the default template as well, since the default 44-pt is
% quite large.) Otherwise, the new slide will be created without a 
% title placeholder, and the figure graphics will occupy the whole slide.
%
% written by ras, 01/05; imported into mrVista2 repository, 10/05.
% ras, 05/2007: for 'meta' format, ungroups the object by default.
% ras, 06/2007: added optional title input.
% ras, 10/2008: fixed pasting images to fit within the slide; now returns
% the new_slide object as well as the pasted picture object.
if notDefined('fmt')
    fmt = '-dbitmap';
else
    fmt = ['-d' fmt];
end

if notDefined('fig'),		fig = gcf;		end
if notDefined('ttl'),		ttl = '';		end

% paste figure into clipboard
figure(fig);
print(fmt);

% Get current number of slides:
slide_count = get(op.Slides, 'Count');

% Get the numeric index of the appropriate slide style:
% 12 = just graphics, 11 = graphics + title
if isempty(ttl)
	slideStyle = 12;
else
	slideStyle = 11;
end

% Add a new slide (no title object):
slide_count = int32(double(slide_count)+1);
new_slide = invoke(op.Slides, 'Add', slide_count, slideStyle);

% % Insert text into the title object:
% set(new_slide.Shapes.Title.TextFrame.TextRange,'Text',titletext);

% Figure out height and width of figure data on the slide:
if isempty(ttl)
	% take up whole slide
	slide_H = op.PageSetup.SlideHeight;
	slide_W = op.PageSetup.SlideWidth;
	slide_T = 0;
else
	% leave the top 10% for the title
	slide_H = (8/9) * op.PageSetup.SlideHeight;
	slide_W = op.PageSetup.SlideWidth;	
	slide_T = (1/9) * op.PageSetup.SlideHeight;
end

% Paste the contents of the Clipboard:
pic = invoke(new_slide.Shapes,'Paste');

% Set picture to fill slide
% (the order in which to set things depends on the aspect ratio; 
%  we want the longer side to fill the slide): 
if pic.Width < pic.Height
	set(pic, 'Height', slide_H);
	set(pic, 'Width', slide_W);
else
	set(pic, 'Width', slide_W);
	set(pic, 'Height', slide_H);
end

% Center picture on page:
set(pic, 'Left', 0);
set(pic, 'Top', slide_T);

% set title if provided
if ~isempty(ttl)
	set(new_slide.Shapes.Title.TextFrame.TextRange, 'Text', ttl)
	set(new_slide.Shapes.Title, 'Top', 0) % flush to top of frame
	
	% though this may be intrusive, I'm going to go ahead and
	% set the master title size: the default is just too intrusive
	set(op.SlideMaster.Shapes.Title.TextFrame.TextRange.Font, 'Size', 24);	
	set(op.SlideMaster.Shapes.Title.TextFrame, 'MarginTop', 0)
	set(op.SlideMaster.Shapes.Title.TextFrame, 'MarginBottom', 0)
end

% Ungroup the object if format is 'meta'
% (for some Office versions, it won't let you do this for some reason)
if isequal(fmt, '-dmeta')
	try
		invoke(pic, 'Ungroup');
	catch
		warning('Could not ungroup slide.')
	end
end

return
