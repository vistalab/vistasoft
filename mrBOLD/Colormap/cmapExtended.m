function vw = cmapExtended(vw, range, padColor)
%
%   vw = cmapExtended(vw, range, [padColor=gray])
%
% Author: AAB, BW
% Purpose:
%   Compress the current color map to smaller range and add gray (or whatever
%	the padding color is) at the end.
%
%  vw = FLAT{1};
%
% vw = cmapExtended(vw)
%
% range: extend range -- a number between 1 and 2. The proportion of the
% view's color map which is taken up by colors versus padding will be
% (1/range). So, if range=2, the colors will take up 1/2 the # colors, 
% if range=1, the colors will take up all the colors (no extend), and
% if range=1.5 the colors will take up 3/4 (1/1.5) the # colors.
%
% padColor: [R G B] triplet specifying what color is padded to fill out the
% colormap. Default: [127.5 127.5 127.5].
%
%History: 
% 050321:   Mark Schira changed line 23
% ras, 08/07: streamlined code, made pad color an inputtable parameter,
% changed definition of interpolation points to guarantee the right size
% for the cmap (previously it was possible to get the wrong size and
% crash).
if notDefined('vw'),		vw = getCurView;				end
if notDefined('range'),		range = readRange;				end
if notDefined('padColor'),	padColor = [127.5 127.5 127.5]; end
if (range < 1) | (range > 2),  error('Range must be between 1 and 2.'); end

numColors = viewGet(vw, 'cmapcurnumcolors');
curCmap = viewGet(vw, 'cmapcurrent');

nDesiredColors = floor(numColors / range); 
nExtraColors = numColors - nDesiredColors;

% make just the color part of the new cmap, by interpolating
% (used to be a round here what I dont understand because 1:range:goal always
% does "floor" and never ceil) 
% -- ras 08/08: not sure, but the existing
% version of the code seemed to sometimes make the new map 1 entry too
% long. I replaced the [a:range:b] call with a linspace, to guarantee the
% right size.
samplePoints = linspace(1, numColors, nDesiredColors);
newMap = round( interp1(curCmap', samplePoints) );

% now add the padding colors at the end
newMap = [newMap; repmat(padColor, [nExtraColors 1])];

% not clear why some viewSet properties expect the cmap to be
% transposed? Matlab cmaps are always 3 x N for the built-in functions.
% (mrDiffusion conventions?)
vw = viewSet(vw, 'cmapphase', newMap');

return;

%----------------------------------------
function range = readRange

prompt={'Enter compression range for the color map (2 = double color map)'};
def={'1.2'};
dlgTitle='Color map compression factor';
lineNo=1;
range=inputdlg(prompt,dlgTitle,lineNo,def);
range = str2num(range{1});

return;
   
