function vw = makeROIfromSelectedVoxels(vw,name,select,color, comments)
%
% vw = makeROIfromSelectedVoxels(vw,[name],[select],[color], [comments])
%
% Makes an ROI consisting of all coords according to cothresh. phWindow,
% and mapWindow.
%
% name:     name (string) for the ROI 
% select:   if non-zero, chooses the new ROI as the selectedROI (default=1)         
% color:    sets color for drawing the ROI (default 'b').
% comments: test string. 

% jw, 1/16/2010

mrGlobals;

if notDefined('vw'),        vw      = getCurView;   end
if notDefined('name'),      name    = [];           end
if notDefined('select'),    select  = [];           end
if notDefined('color'),     color   = [];           end
if notDefined('comments'),  comments= [];           end

% Create an ROI with all coordinates
coords = allCoords(vw);
vw = newROI(vw,name,select,color,coords, comments);

% Restrict the coordinates according to cothresh. phWindow, and mapWindow.
vw = restrictROIfromMenu(vw);

return

function coords = allCoords(vw)

viewType = viewGet(vw, 'viewType');

switch lower(viewType)
    case {'gray', 'volume'}           
        coords = viewGet(vw, 'coords');
    case 'inplane'
        sz =  viewGet(vw,'anatsize');
        [a b c] = ind2sub(sz, 1:prod(sz));
        coords = [a; b; c];
    case 'flat'
        leftcoords  = viewGet(vw, 'coords', 'left');
        rightcoords = viewGet(vw, 'coords', 'right');
        coords      = [leftcoords rightcoords];
end

return






