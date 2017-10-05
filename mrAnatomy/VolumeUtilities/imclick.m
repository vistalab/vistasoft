function imclick(r)
% IMCLICK: click around an image, getting pixel values around where you
% clicked.
%
% This is a very simple tool: after entering IMCLICK, click at various
% points in an image in a figure window. The Command Window will display
% the pixel values of a rectangle centered where you clicked. This
% rectangle will by default be size 5 X 5; entering IMCLICK(R) will make
% the window size R X R.
%
% Press the right mouse button to stop IMCLICK. 
%
% 07/2003 ras.
if ~exist('r','var')
    r = 5;
end

% convert to a range relative to the center of a rect
r = floor(r/2);

% find the image data in the current axes
h = findobj('Type','Image','Parent',gca);
if isempty(h)
    fprintf('IMCLICK requires that an image be displayed in the active window.\n');
    return
end
img = get(h,'CData');

% % scale by the limits set by the 'CLim' property:
% % this reverts from color-map values to image data values
% % (don't think this is actually true -- ras 12/07)
% clim = get(gca,'CLim');
% img = normalize(img,clim(1),clim(2));

% initialize
format long g;
b = 0;

while b~=3 && b~=2
	[x,y,b] = ginput(1);
    if b==3 || b==2,  break;  end
	
	% re-index into the axes' X and Y ranges: this way, you can get values
	% after plotting data centered at, say, 0:
	X = get(h, 'XData');
	Y = get(h, 'YData');
	x = round( size(img, 2) * (x - min(X)) / diff(mrvMinmax(X)) );
	y = round( size(img, 1) * (y - min(Y)) / diff(mrvMinmax(Y)) );
	
	% expand range to span the rectangle determined by size r
	rngX = x-r:x+r;
	rngY = y-r:y+r;	


	% make sure range isn't out of matrix bounds
	rngX = rngX( rngX > 0 & rngX < size(img, 2) );
	rngY = rngY( rngY > 0 & rngY < size(img, 1) );
	
	% report on the image values in the command line
    fprintf('Location: %i, %i\n',round(x),round(y));
	img(rngY,rngX,:)
	
	% make patch showing the matrix range (delete old patches 1st)
    if exist('h2','var'),  delete(h2);   end
    h2 = patch([rngX(1) rngX(end) rngX(end) rngX(1)], ...
			   [rngY(1) rngY(1) rngY(end) rngY(end)], 'c');
end

if exist('h2','var'),  delete(h2);   end

return
