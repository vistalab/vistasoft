function new_slide = pptTitle(op, ttlText, fontSize, fontName);
%
% new_slide = pptTitle(op, ttlText, [fontSize=32], [fontName]);
%
% Add a title slide to a PowerPoint presentation, with the provided
% text. The optional fontSize and fontName fields allow you to specify
% the type and size of the text font. The default fontSize is 32, the 
% default fontName is whatever is saved in the power point file's template.
%
% SEE ALSO: pptOpen, pptPaste, pptClose.
%
% ras, 07/2007.
if ~exist('fontSize', 'var'),	fontSize = 32;		end
if notDefined('fontName'),	fontName = '';		end

slide_count = get(op.Slides, 'Count');

% Add a the title slide:
slide_count = int32(double(slide_count)+1);
new_slide = invoke(op.Slides, 'Add', slide_count, 1);

% Set the title text, font
set(new_slide.Shapes.Title.TextFrame.TextRange, 'Text', ttlText);

if ~isempty(fontSize)
	set(new_slide.Shapes.Title.TextFrame.TextRange.Font, 'Size', fontSize);
end

if ~isempty(fontName)
	set(new_slide.Shapes.Title.TextFrame.TextRange.Font, 'Name', fontName);
end

return
