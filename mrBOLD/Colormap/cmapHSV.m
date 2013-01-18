function hsvMap = cmapHSV(hsvColors);
%
%   hsvMap = cmapHSV(hsvColors);
% 
%Author: AB/BW
%Purpose:
%   Create an hsv map such that the magenta/blue boundary is in the middle.
%   This makes manipulation of the colors easier for wedge maps.
%

% shiftSize to make magenta  the middle color is in the center.
magenta = [.1 0 1];
mp = hsv(hsvColors);

% Obscure bit of code.  Have fun.
[val,idx] = min(sum( abs(mp - repmat(magenta,hsvColors,1))'));
shiftSize = -round((idx - hsvColors/2));

hsvMap = circshift(mp,shiftSize);

return;