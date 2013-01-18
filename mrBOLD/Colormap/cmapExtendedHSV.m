function cmap = cmapExtendedHSV(numGrays,numColors,range)
%
% cmap = cmapExtendedHSV([numGrays=128],[numColors=96],[range=query user])
% 
%The map created here are hsv maps where all of the colors
% can be placed in a subsection of the full color map.  In this way, the
% full range of colors spans less than 2pi, like in the double color map.
% Rather than compressing by a complete factor of 2, like the double color
% map, the compression factor can be a bit smaller.
%
%   There are numGrays gray scale entries.  They occupy the first part of the cmap, 1:numGrays
%   There are numColors hsv colors.  They fill the map entries following the gray, 
%   from (numGrays+1):numGrays+numColors
%   When the range is 1, the hsv map is hsv(numColors) and we insert it
%   into the cmap.
%   When the range is 1.5, we compute tmp = hsv(numColors/1.5) and we
%   create [tmp,tmp(1:needed)] to fill up numColors entries.
%
% Examples:
%   cmap = cmapExtendedHSV(128,96,1.1);
%   cmap = cmapExtendedHSV(128,96);    -- 128 gray levels, 96 color levels,
%          query use for compression
%   cmap = cmapExtendedHSV;
%   cmap = cmapExtendedHSV(128,96,2);  -- Same as hsvDoubleCmap
%


function vw = cmapExtended(vw,range)
%
%   vw = cmapExtended(vw,range)
%
% Author: AAB, BW
% Purpose:
%   Compress the current color map to smaller range and add gray at the end.
%
%  vw = FLAT{1};

numGrays = viewGet(vw,'cmapcurnumgrays');
numColors = viewGet(vw,'cmapcurnumcolors');
mpColors = viewGet(vw,'cmapcurrent');

if ieNotDefined('vw'),  error('Must pass in the view.'); end
if ieNotDefined('range'), range = 1.2; end

if (range < 1) | (range > 2),  error('Range must be betweem 1 and 2.'); end

desiredColors = round(numColors/range);
extraColors = numColors - desiredColors;
newMap = [round(interp1(mpColors',(1:range:numColors)')')];
newMap = [newMap,ones(3,extraColors)*128];

vw = viewSet(vw,'cmapcurrent',newMap);

% cmap = zeros(numGrays+numColors,3);
% 
% % If you want the map symmetric at the boundary, you should do this.
% % We could trap range == 2 and do it then ... which would be backwards
% % compatible?
% % cmap = [gray(numGrays); hsvMap; flipud(hsvMap(1:hsvColorsExtra,:))];
% cmap = [hsvMap; hsvMap(1:hsvColorsExtra,:)];
% shiftSize = round(hsvColorsExtra/2);
% hsvMap = circshift(cmap,shiftSize);
% 
% cmap = [gray(numGrays); cmap];

return;

%----------------------------------------
function range = readRange

prompt={'Enter compression range for the hsv map (2 = double color map)'};
def={'1.2'};
dlgTitle='Color map compression factor';
lineNo=1;
range=inputdlg(prompt,dlgTitle,lineNo,def);
range = str2num(range{1});

return;
   
