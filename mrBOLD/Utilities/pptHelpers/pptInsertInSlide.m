function pic = pptInsertInSlide(op, img, pos, units, slide_num);
% Paste an image matrix into an existing PowerPoint slide at a user-specified 
% position.
%
%   pic = pptInsertInSlide(op, img, pos, [units='normalized'], [slide_num=last slide]);
%
% INPUTS: 
%	op: ActiveX operation for PowerPoint. You get this by calling pptOpen.
%	img: image matrix. Can be 2D (grayscale) or 3D (truecolor), or can be a 
%		handle to a MATLAB figure containing the contents to be pasted. 
%	pos: 4-element matrix specifying the position of the image in the
%		slide. The format is:
%			[top left corner X, top left corner Y, widht, height]
%	units: either 'pixels' or 'norm' (or 'normalized'). Specifies the units
%		in the pos argument. If 'pixels', the units are pixels down or to the left 
%		of the top-left corner of the slide. If 'norm', units are
%		normalized to the slide width (e.g., 0=at the top/left corner, 1=at
%		the bottom/right corner, .5=halfway). [Default 'norm']
%	slide_num: optional specification of the slide in which to insert the
%		image. Can also be the slide object itself. 
%		[defaults to last slide in the PPT.] 
%
% OUTPUTS:
%	pic: Microsoft shape object representing the inserted picture.
%
% SEE: pptOpen, pptPaste, pptClose.
%
% ras, 10/2008.
if notDefined('op'),	error('Need to run pptOpen first.');		end
if notDefined('img'),	error('Need an image to insert.');			end
if notDefined('pos'),	error('Need a position for the image.');	end
if notDefined('units'),	units = 'norm';								end
if notDefined('slide_num'),	slide_num = get(op.Slides, 'Count');	end

% copy the image into the clipboard 
if length(img)==1 & ishandle(img)
	% 'img' is actually a handle to a figure: copy this figure
	figure(img)
	print('-dbitmap');
else
	% copy by making a figure, copying the image, then closing the
	% figure:
	hFig = figure('Units', 'norm', 'Position', [0 0 1 1], 'Color', 'w');
	imshow(img);
	print('-dbitmap');
	close(hFig);
end

%% get the selected slide
% allow the user to hand in a slide object
classType = 'Interface.Microsoft_PowerPoint_11.0_Object_Library._Slide';
if isequal( class(slide_num), classType )
	slide = slide_num;
else
	% get the slide based on the slide ID
	% (I think this is the way to do it, but I'm not 100% sure:
	%  it seems like the SlideID is 255 + the slide num...
	slide = invoke(op.Slides, 'FindBySlideID', (255 + slide_num));
end

% paste into the powerpoint slide
pic = invoke(slide.Shapes,'Paste');

% if using normalized units, convert into pixels
if strncmp( lower(units), 'norm', 4 )==1
	pos([1 3]) = pos([1 3]) .* op.PageSetup.SlideWidth;
	pos([2 4]) = pos([2 4]) .* op.PageSetup.SlideHeight;
end

% set the position in the slide
set(pic, 'Left', pos(1));
set(pic, 'Top', pos(2));
set(pic, 'Height', pos(4));
set(pic, 'Width', pos(3));


return
