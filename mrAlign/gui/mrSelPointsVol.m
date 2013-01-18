function fulpts = fancySelect(curImage,curSize,curMin, curMax, X, Y, zoomSize, selOff)
%
% pts = selectPoint
%    Select a set of points from the current image by clicking.
%    left mouse button -- selects a point
%    middle mouse button -- deletes a point
%    right mouse button -- exits
%
%    Started by B. Wandell, 06.28.93
%    
% Variable Declarations
num = 0;		% The number of points selected
ord = zeros(curSize(1),curSize(2));
fulpts = zeros(curSize(1),curSize(2));

oldImage = curImage;		% For erasing
num = 1;
while 1 == 1
 [x y but] =  mrGinput(1,'cross');
  x = floor(x); y = floor(y);
  fulx = x + selOff(1) - 1;	% "-1" offset is required becuase the upper
  fuly = y + selOff(2) - 1;	% left hand corner of the screen is (1,1) not (0,0)
  if x <= zoomSize(2) & y <= zoomSize(1) & x > 0 & y > 0
     thept = fuly+(fulx-1)*curSize(1);
     if but == 1
       fulpts(fuly,fulx) = 1;
       ord(fuly,fulx) = num;
       curImage(thept) = -2;		% blue
       num = num + 1;
     elseif but == 2
       fulpts(fuly,fulx) = 0;
       curImage(thept) = oldImage(thept);
     elseif but == 3
       break
     end
  myShowImageVol(curImage, curSize, curMin, curMax, X, Y, zoomSize, selOff);
  else
   s = sprintf('Out of Range: %d %d',x,y)
  end
end

fulpts = reshape(fulpts,1,prod(size(fulpts)));
ord = reshape(ord,1,prod(size(fulpts))) .* fulpts;
dum = (ord == 0);
ord(dum) = 99999.*ones(sum(dum),1);
[srt, arang] = sort(ord);
fulpts = arang(1:sum(fulpts));






