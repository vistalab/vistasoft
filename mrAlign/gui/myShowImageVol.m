function imHandle = myShowImageVol(in,imageSize,mymin,mymax,X,Y)
% MYSHOWIMAGEVOL
%	function imHandle = myShowImageVol(in,imageSize,mymin,mymax,X,Y)
%
%	Scales and displays an image in.
%
%	Image values below mymin or above mymax are ignored, and the range mymin-mymax
%	is scaled to fit the whole color map.  Special negative vaules are displayed
%	in color.
%
global axisflag

regimage = (in >= 0);
colorim = (in < 0);
low = ((in < mymin) & regimage);
in(low) = mymin*ones(1,sum(low));
in(in>mymax) = mymax*ones(1,sum(in>mymax));

in(regimage) = min(110,floor(110*(in(regimage)-mymin)/(mymax-mymin)+1));
in(colorim) = (min(220,round(-in(colorim))))+111;
in = reshape(in,imageSize(1),imageSize(2));
image(in); set(gca,'XTick',[],'YTick',[]);


% Seeing if this is the line that actually draws in the sagittal window
if nargin >= 6
%	line(X,Y,'color',[1,0,0],'clipping','on');
	line(X,Y,'color',[0,1,0],'clipping','on');
end

axis image;

if (~axisflag)
	axis off
end










