function [gray,ROI, layers] = makeROIdiskGray(gray, radius, name, select, color, grayCoordStart,addFlag)
%
%  [gray,ROI] = makeROIdiskGray(gray, [radius], [name], [select], [color], [grayCoordStart],[addFlag])
%
% Create an ROI within the gray matter.  The ROI points are within a
% distance radius from a selected point (grayCoordStart).  The
% grayCoordStart point may be computed and passed in, or if that variable
% is empty the user is prompted to select the point in the current VOLUME
% window.  
%
% If requested, the gray matter ROI is returned.  This ROI can be used in other
% routines, such as vol2ipROI. 
%
% If you do not wish to add the ROI to the gray matter volume, set addFlag
% to 0.
%
% djh, 2/15/2001
%
% 7/16/02 djh, replaced mrSESSION.vAnatomyPath with global vANATOMYPATH
%
% Examples:
%
%  VOLUME{1} = makeROIdiskGray(VOLUME{1},5,'test',[],[],[70,168,67])
%  [ignoreMe, ROI] = makeROIdiskGray(VOLUME{1},5,'test',[],[],[70,168,67],0)
%
% ras 03/06: allows you to enter 'roi' as the grayCoordStart, to find the
% center of the current ROI. Also allows you to call the function from 
% an inplane view, xforming automatically to a hidden gray view. (works for
% 'roi' option only right now, though.)
%
% dy 12/2008: "choose start point" option broken (still worked fine for
% "from center of cur ROI", not sure if the "choose" break is recent or
% chronic). debugged on matlabr2007a -glnx86 -- figured out that the
% problem is that if the Sag coordinate in the GUI is not selected,
% viewGet(vw, 'Current Slice') does not get a unique value, and thus one of
% the coordinates is repeated and the disk shows up in some other place.
% Can't think of a quick way to fix it for the moment, so I'm
% "unimplementing" the options that don't work (if Cor or Axi are selected
% instead). ras, 07/09: the old code works for single-orientation view. For
% 3-views (which was the problem above), it just takes the current
% crosshairs location. (It would be easy to fix the code where the user
% clicks, but this just seems more intuitive to me.)

mmPerPix = viewGet(gray, 'vol vox size');

% Fill radius variable
if notDefined('radius')
   prompt={'Radius (mm)'}; def={'5'};lineNo=1;dlgTitle = 'add disk ROI';
   answer=inputdlg(prompt,dlgTitle,lineNo,def);
   if isempty(answer),  myErrorDlg('Canceling addROIdisk');
   else                 radius = str2num(answer{1});
   end
end
% fprintf('radius = %.0f\n',radius);

if notDefined('name'),     name=sprintf('disk%.0f',radius); end
if notDefined('select'),   select=1; end
if notDefined('color'),    color='b'; end
if notDefined('addFlag'), addFlag = 1; end

% if inplane view, create a temp gray view and transform
if isequal(gray.viewType, 'Inplane')
    if ~isequal(grayCoordStart, 'roi')
        error('Sorry, can only use an inplane view if you''re using the ROI option.');
    else
        hG = initHiddenGray(gray.curDataType, gray.curScan);
        hG = ip2volCurROI(gray, hG);
        [hG ROI layers] = makeROIdiskGray(hG, radius, name, 1, ...
                color, grayCoordStart,addFlag);
        gray = vol2ipCurROI(hG, gray);
        if select==1, gray.selectedROI = length(gray.ROIs); end
        return
    end
end


if notDefined('grayCoordStart')
    grayCoordStart = getStartPtFromGUI(gray);
	
elseif isequal(grayCoordStart, 'roi')
    % get start coord from center of current ROI
    coords = gray.ROIs(gray.selectedROI).coords;
    if size(coords,2)==1
        grayCoordStart = coords;
    else
        grayCoordStart = round(mean(coords'))';
    end

elseif isstruct(grayCoordStart)
    % get start coord from center of current ROI
    coords = grayCoordStart.coords;
    if size(coords,2)==1
        grayCoordStart = coords;
    else
        grayCoordStart = round(mean(coords'))';
    end
end

% get nearest gray node (note that not all points on the flat map correspond to
% gray nodes)
tmpDistances = (gray.coords(1,:) - grayCoordStart(1)).^2 + ...
    (gray.coords(2,:) - grayCoordStart(2)).^2 + ...
    (gray.coords(3,:) - grayCoordStart(3)).^2;
[val,index] = min(tmpDistances);

% Find start point in the grayNodes
% Look first in allLeftNodes, then in allRightNodes
startPtGrayCoord = gray.coords(:,index);
if ~isempty(gray.allLeftNodes)
  nodes = gray.allLeftNodes;
  edges = gray.allLeftEdges;
  startNode = ...
    find(nodes(2,:) == startPtGrayCoord(1) & ...
    nodes(1,:) == startPtGrayCoord(2) & ...
    nodes(3,:) == startPtGrayCoord(3));
else
    startNode = [];
end
if ~isempty(gray.allRightNodes) && isempty(startNode)
  nodes = gray.allRightNodes;
  edges = gray.allRightEdges;
  startNode = ...
    find(nodes(2,:) == startPtGrayCoord(1) & ...
    nodes(1,:) == startPtGrayCoord(2) & ...
    nodes(3,:) == startPtGrayCoord(3));
end

if notDefined('nodes') % ras 06/06: to save mem, leave allRight/LeftNodes empty
    nodes = gray.nodes;
    edges = gray.edges;
    startNode = find(nodes(2,:) == startPtGrayCoord(1) & ...
                     nodes(1,:) == startPtGrayCoord(2) & ...
                     nodes(3,:) == startPtGrayCoord(3));
end


% Compute distances: mrManDist expects doubles...
distances = mrManDist(double(nodes), double(edges), startNode, mmPerPix, -1, radius);
diskIndices = find(distances >= 0);

% Coords in the gray matter
coords = nodes([2 1 3],diskIndices);
layers = nodes(6, diskIndices);

% Make grayROI
ROI = roiCreate1;
ROI.coords = coords;
ROI.name = name;
ROI.color = color;
ROI.viewType = 'Gray';
ROI.modified = datestr(now);

% Usually, the ROI is added.  But in some cases, we only want the ROI data.
if addFlag, [gray,pos] = addROI(gray,ROI,select); end

return;
% /-----------------------------------------------------------------/ %



% /-----------------------------------------------------------------/ %
function grayCoordStart = getStartPtFromGUI(gray);
% this interactively gets the start point for the ROI disk. If the view is
% a volume/gray 3-axis view, then the start point is just the location
% indicated by the crosshairs. If it's a single-orientation view, we use
% the older code to prompt the user to click on a point on the current
% slice.
if isequal(gray.refreshFn, 'volume3view')
	%% 3-axis view: get current x-hairs location
	grayCoordStart = viewGet(gray, 'loc');
else
	%% single-orientation view: prompt user for click
    % Select figure and get a single point from the user
    figure(gray.ui.figNum)
    
    % Get mouse input
    [x,y] = ginput(1);
    x = round(x); y = round(y);
    
    % Interpret mouse click according to current slice orientation
    viewGet(gray, 'Current Slice');
    sliceOri = getCurSliceOri(gray);
    switch sliceOri
        case 1				% axi (y=cor pos, x=sag pos)
            grayCoordStart = [curSlice y x];
            return
        case 2 				% cor (y=axi pos, x=sag pos)
            grayCoordStart = [y curSlice x];
            return
        case 3 				% sag (y=axi pos, x=cor pos)
            grayCoordStart = [y x curSlice];
    end
end

return

