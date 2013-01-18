function [thexs,theys] = mrSelLineVol(curImage,curSize,curMin, curMax, X, Y)
%
% mrSelLineVol
%	 [thexs,theys] = mrSelLineVol(curImage,curSize,curMin, curMax, X, Y)
%    Select a line from the current image by clicking.
%    left mouse button -- selects a point
%    middle mouse button -- deletes a point
%    right mouse button -- exits
%
%    returns the x and y coordinates of the selected points.
%    Started by B. Wandell, 06.28.93
%    
% Variable Declarations
num = 0;		% The number of points selected

ord = zeros(curSize(1),curSize(2));
fulpts = zeros(curSize(1),curSize(2));
oldImage = curImage;		% For erasing
num = 1;
while 1 == 1
 [x y but] =  mrGinput(2,'arrow');
  x = floor(x); y = floor(y);
  slope = (y(2)-y(1))/(x(2)-x(1));    % Actually the negative of the slope since
					% Y is increasing from top to bottom.
				    
   if(abs(slope) < 1)	% More unique x's than y's
	  dx = sign(x(2)-x(1))*[0:(round(max(x)-min(x)))];
	  dy = round(slope*dx);
  else			% More unique y's than x's
	  dy = sign(y(2)-y(1))*[0:(round(max(y)-min(y)))];
	  dx = round((1/slope)*dy);
  end
  if(  x(1) > 0 & y(1) > 0 & x(2) > 0 & y(2) > 0 )
     x = x(1); y =y(1); 
     fulx = x  - 1;	% The "-1" is because the upper left is (1,1) not (0,0)
     fuly = y  - 1;	% Ex: If we click in the upper left corner we want
				% fulx and y to be '1', not '0'.
     if but == 1
       for i = (1:length(dx))
	  a = dx(i); b = dy(i);
          fulpts(fuly+b,fulx+a) = 1;
          ord(fuly+b,fulx+a) = num;
	  thept = fuly+b+(fulx+a-1)*curSize(1);
          curImage(thept) = -2;		% blue
          num = num + 1;
	end
     elseif but == 2
       for i = (1:length(dx))
	  a = dx(i); b = dy(i);
          fulpts(fuly+b,fulx+a) = 0;
          ord(fuly+b,fulx+a) = num;
	  thept = fuly+b+(fulx+a-1)*curSize(1);
          curImage(thept) = oldImage(thept);
	end
     elseif but == 3
       break
     end
  myShowImageVol(curImage, curSize, curMin, curMax, X, Y);
  else
   s = sprintf('Out of Range: %d %d',x,y)
  end
end

fulpts = reshape(fulpts,1,prod(size(fulpts)));
ord = reshape(ord,1,prod(size(fulpts))) .* fulpts;
dum = (ord == 0);
ord(dum) = 99999.*ones(sum(dum),1);
[srt, arang] = sort(ord);
xcoord = (1:curSize(2))'*(ones(1,curSize(1)));
xcoord = reshape(xcoord',1,prod(curSize));
ycoord = ones(1,curSize(2))'*(1:curSize(1));
ycoord = reshape(ycoord',1,prod(curSize));
thexs = xcoord(arang(1:sum(fulpts)));
theys = ycoord(arang(1:sum(fulpts)));
