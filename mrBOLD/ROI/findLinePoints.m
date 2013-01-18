function [x, y] = findLinePoints(p1,p2);
% 
%   [x, y] = findLinePoints(p1,p2)
%
% Author:  I think it was me. 
% Purpose:
%      Find the x,y values that fall along a line between p1 and p2.
% 
% 2002.07.24 RFD & FWC- fixed bug in vertical and horizontal special cases.
%            (Was returning column vectors instead of row.)

x1 = p1(1); y1 = p1(2);
x2 = p2(1); y2 = p2(2);

if y2 == y1
  if x1 == x2
    error;
    return;
  end
  x = [x1:x2];  y = y1*ones(1,length(x));
elseif x1 == x2
  if y1 == y2
    error;
    return;
  end
  y = [y1:y2];  x = x1*ones(1,length(y));
else
  slope = (y2-y1)/(x2-x1);
  b = y1 - slope*x1;   
  if abs(y2 - y1) > abs(x2 - x1)
    if y1 < y2,  y = y1:y2;
    else,        y = y2:y1;
    end
    x = round( (y - b) / slope);
  else
    if x1 < x2, x = x1:x2;
    else        x = x2:x1;
    end
    y = round(slope*x + b);
  end
end

return;
