function fulpts = fancySelect(imag,imSize, xrang, yrang, fulSize, X, Y)
%
% pts = selectPoint
%    Select a set of points from the current image by clicking.
%    left mouse button -- selects a point
%    middle mouse button -- deletes a point
%    right mouse button -- exits
%
%    Started by B. Wandell, 06.28.93
%    
baseMax = round(max(imag));
baseMin = round(min(imag));
curMap = colormap;
mapMax = size(curMap,1);
if mapMax > 252
  error('The color table already runs up to 253.  No overlays allowed now');
end
newMap = zeros(mapMax+1,3);
newMap(1:mapMax,:) = curMap;
newMap(mapMax+1,:) = [0 1 0];
colormap(newMap);
overlay = min(mapMax,floor(mapMax*(imag-baseMin)/(baseMax-baseMin)+1));
image(xrang,yrang,reshape(overlay,imSize(1),imSize(2))); axis equal
line(X,Y,'color',[1,0,0],'clipping','on');

pts = zeros(imSize(1),imSize(2));
ord = zeros(fulSize(1),fulSize(2));
fulpts = zeros(fulSize(1),fulSize(2));

num = 1;
while 1 == 1
 [x y but] =  mrGinput(1,'cross');
  fulx = floor(x); fuly = floor(y);
  x = ceil(x-xrang(1)); y = ceil(y-yrang(1));
 if x <= imSize(2) & y <= imSize(1) & x > 0 & y > 0
  if but == 1
    pts(y,x) = 1;
    fulpts(fuly,fulx) = 1;
    ord(fuly,fulx) = num;
    num = num+1;
  elseif but == 2
    pts(y,x) = 0;
    fulpts(fuly,fulx) = 0;
  elseif but == 3
    break
  end
 else
   s = sprintf('Out of Range: %d %d',x,y)
 end
 nupts = reshape(pts,1,prod(size(pts)));
 nuoverlay = overlay;
 nuoverlay(nupts) = (mapMax+1)*ones(1,sum(nupts));
 image(xrang,yrang,reshape(nuoverlay,imSize(1),imSize(2))); axis equal
 line(X,Y,'color',[1,0,0],'clipping','on');
end

fulpts = reshape(fulpts,1,prod(size(fulpts)));
ord = reshape(ord,1,prod(size(fulpts))) .* fulpts;
dum = (ord == 0);
ord(dum) = 99999.*ones(sum(dum),1);
[srt, arang] = sort(ord);
fulpts = arang(1:sum(fulpts));


