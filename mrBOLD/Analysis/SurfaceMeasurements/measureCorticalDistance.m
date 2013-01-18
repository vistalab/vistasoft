function [flat, allDist, sumDist, geodesicCoords, geodesicLayer] = measureCorticalDistance(flat, coords, verboseFlag, gray)
% USAGE: measureCorticalDistance(flat, [coords], [verboseFlag], [gray])
%   
% AUTHOR:  Dougherty
% DATE:    2002.01.15
% PURPOSE:
%   Compute the shortest cortical manifold distance between 
%   points. If coords is passed in, then the points are drawn
%   from there. Otherwise, the points are obtained via ginput.
%   (Note that coords must be a valid nx3 list of flat view coords,
%   such as would be obtained by 'getCurROIcoords(flatView)'.)
% 
% HISTORY
%
% 7/16/02 djh, replaced mrSESSION.vAnatomyPath with global vANATOMYPATH
% 9/02/04 mms, inserted a warning not to use rotated flats.
% 9/22/04 rfd, now returns the geodesic path (as coords) and the gray layer
% of each point along the path.

global vANATOMYPATH;
mmPerPix = readVolAnatHeader(vANATOMYPATH);

% Check some flat and volume stuff here when you
% get a chance to fix this code up

% Get a gray structure because we need the gray nodes.
if notDefined('gray')
    gray = getSelectedGray;
    if isempty(gray)
        gray=initHiddenGray;
    end
end

if(~exist('coords','var') | isempty(coords))
    % Select flat figure and get a single point from the user
    figure(flat.ui.figNum)
    disp('Click left to add points, right to quit');
    button = 1;
    count = 0;
    w = 0.5;
    coords = [];
    z = viewGet(flat, 'Current Slice');
    while(button~=3)
        [x,y,button] = ginput(1);
        if(button==3)
            break;
        end
        count = count+1;
        coords = [coords,round([y;x;z])];
        h(count) = line([x-w,x-w,x+w,x+w,x-w],[y-w,y+w,y+w,y-w,y-w],'Color','w');
        if flat.rotateImageDegrees(coords(3,1))>0  %detects if the Flat your are currently selecting the points ist rotated
            errordlg('Flat must not be rotated','Warning!'); %Results would be wrong!
        end
    end
    % Delete the temporarily drawn squares
    for ii=1:length(h)
        delete(h(ii));
    end
    clear h;
end
if(~exist('verboseFlag','var') || isempty(verboseFlag))
    verboseFlag=1;
end

% the third coordinate is the 'slice', which, for flat views, means left or right hemisphere.
slice = coords(3,1);
if (slice==1)
    nodes = gray.allLeftNodes;
    edges = gray.allLeftEdges;
else
    nodes = gray.allRightNodes;
    edges = gray.allRightEdges;
end

% We loop for the number of line segements, which is the number of
% coords - 1.
geodesic = [];
for(ii=1:size(coords,2)-1)
    % get nearest flat coordinate (not all points on the flat correspond to flat coordinates)
    flatDistances = (flat.coords{slice}(1,:) - coords(1,ii)).^2 + ...
        (flat.coords{slice}(2,:) - coords(2,ii)).^2;
    % There is a one-to-many mapping of flatCoords to grayCoords, but we ignore that
    % here by using 'min', which will always reuturn one value, even if there are several
    % identical minima. 
    % FIX THIS- we should always grab layer 1, or something more consistent
    % than relying on min's arbitrary sort.
    [val,startIndex] = min(flatDistances);
    % Do it again, for ii+1, to find the end point of this line segment.
    flatDistances = (flat.coords{slice}(1,:) - coords(1,ii+1)).^2 + ...
        (flat.coords{slice}(2,:) - coords(2,ii+1)).^2;
    [val,endIndex] = min(flatDistances);
    
    % Draw a line for each measured segment
    % we use the actual gray node coords rather than the ROI coords, so the use can see if
    % there is any non-trivial discrepancy.
    h(ii) = line([flat.coords{slice}(2,startIndex),flat.coords{slice}(2,endIndex)], ...
                 [flat.coords{slice}(1,startIndex),flat.coords{slice}(1,endIndex)], ...
                 'Color', 'r', 'LineWidth', 2);
    
    % Extract the gray node corresponding to the start
    startGrayNode = find(nodes(2,:) == flat.grayCoords{slice}(1,startIndex) & ...
                         nodes(1,:) == flat.grayCoords{slice}(2,startIndex) & ...
                         nodes(3,:) == flat.grayCoords{slice}(3,startIndex));
    endGrayNode = find(nodes(2,:) == flat.grayCoords{slice}(1,endIndex) & ...
                       nodes(1,:) == flat.grayCoords{slice}(2,endIndex) & ...
                       nodes(3,:) == flat.grayCoords{slice}(3,endIndex));
    
    % Catch errors. If we give mrManDist an empty startPoint array, it barfs.
    if(isempty(startGrayNode) | isempty(endGrayNode))
        myErrorDlg('No gray nodes were found for these coords!');
    end
    
    % Now, compute the manifold distance between these points.
    % mrManDist returns the distance to all other points from the given 'start' point.
    %allDist = mrManDist(nodes, edges, startGrayNode, mmPerPix, -1, 0);
    [allDist,nPts,lastPoint] = mrManDist(nodes, edges, startGrayNode, ...
                                      mmPerPix, -1,0);
    nextPoint = endGrayNode;
    while(nextPoint~=startGrayNode)
      geodesic(end+1) = lastPoint(nextPoint);
      nextPoint = lastPoint(nextPoint);
    end

    % We just want the distance from the start point to the end point, so we
    % pull that out by providing the index of the end point.
    dist(ii) = allDist(endGrayNode);
    if(verboseFlag>=0)
        disp(['Cortical distance of segment ',num2str(ii),': ',num2str(dist(ii)),' mm.']);  
    end
end
sumDist=sum(dist);
if(verboseFlag>=0)
    disp(['Total cortical distance: ',num2str(sumDist),' mm.']);
end
if(verboseFlag>0)
    uiwait(msgbox(['Total cortical distance: ',num2str(sumDist),' mm.'], ...
        'Cortical Distance', 'modal'));
end

for ii=1:length(h)
    delete(h(ii))
end
geodesicCoords = nodes([2,1,3],geodesic);
geodesicLayer =  nodes(6,geodesic);
return
