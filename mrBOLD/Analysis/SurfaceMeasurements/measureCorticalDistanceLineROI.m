function [flatView, allDist] = measureCorticalDistanceLineROI(flatView, coords,plotFlag)
% 
% USAGE: measureCorticalDistanceLineROI(flatView, coords)
%   
% AUTHOR:  Dougherty
% DATE:    2002.04.10
% PURPOSE:
%   Compute the shortest cortical manifold distance between 
%   points. The coords is passed in are assume to be a line ROI
%   where the first coord is at one end of the line and the last
%   coord is at the other end.
% 
% HISTORY
%
% 7/16/02 djh, replaced mrSESSION.vAnatomyPath with global vANATOMYPATH

sampleDist = 5;

global vANATOMYPATH;
mmPerPix = readVolAnatHeader(vANATOMYPATH);

if (~exist('plotFlag','var'))
    plotFlag=1;
end

% Get a gray structure because we need the gray nodes.
grayView = getSelectedGray;
if isempty(grayView)
    grayView = initHiddenGray;
end

% the third coordinate is the 'slice', which, for flat views, means left or right hemisphere.
slice = coords(3,1);
if (slice==1)
    nodes = grayView.allLeftNodes;
    edges = grayView.allLeftEdges;
else
    nodes = grayView.allRightNodes;
    edges = grayView.allRightEdges;
end

nCoords = size(coords,2);
disp(['Finding nodes for ',num2str(nCoords),' coords...']);
allNodeIndices = zeros(1,nCoords);
% Find the nearest gray node for each coordinate.
%
for(ii=1:nCoords)
    % get nearest flat coordinate (not all points on the flat correspond to flat coordinates)
    flatDistances = (flatView.coords{slice}(1,:) - coords(1,ii)).^2 + ...
        (flatView.coords{slice}(2,:) - coords(2,ii)).^2;
    % There is a one-to-many mapping of flatCoords to grayCoords, but we ignore that
    % here by using 'min', which will always reuturn one value, even if there are several
    % identical minima. 
    % FIX THIS- we should always grab layer 1, or something more consistent
    % than relying on min's arbitrary sort.
    [val,coordIndex] = min(flatDistances);
        
    grayNode = find(nodes(2,:) == flatView.grayCoords{slice}(1,coordIndex) & ...
            nodes(1,:) == flatView.grayCoords{slice}(2,coordIndex) & ...
            nodes(3,:) == flatView.grayCoords{slice}(3,coordIndex));
    % This should produce exactly one index.
    
    % Catch errors. 
    if(isempty(grayNode))
        myErrorDlg('No gray nodes were found!');
    end
    if(length(grayNode)>1)
        disp([mfilename,': WARNING- coord ',num2str(ii),'- more than one grayNode found!']);
        grayNode = grayNode(1);
    end
    allNodeIndices(ii) = grayNode;
end

sampleNodes = allNodeIndices(1);
nodeIndices = allNodeIndices(2:end);
done = 0;
while(~done)
    % Now, compute the manifold distance to all other points from the given 'start' point.
    allDist = mrManDist(nodes, edges, sampleNodes(end), mmPerPix, -1, 0);
    drop = intersect(find(allDist<=sampleDist), nodeIndices);
    if(~isempty(drop))
        for(ii=1:length(drop))
            nodeIndices = nodeIndices(nodeIndices~=drop(ii)); 
        end
    end
    if(~isempty(nodeIndices))
        % *** WE SHOULD GET THE NEXT NEAREST
        nearest = find(allDist(nodeIndices)==min(allDist(nodeIndices)));
        nearest = nearest(1);
        sampleNodes = [sampleNodes, nodeIndices(nearest)];
        nodeIndices = nodeIndices(nodeIndices~=nodeIndices(nearest));
    end
    if(isempty(nodeIndices))
        done = 1;
    end
end

% This would be much simpler if we kept track of which coords we were sampling in the loop above.
for(ii=1:length(sampleNodes))
    thisOne = find(allNodeIndices==sampleNodes(ii));
    sampleCoords(:,ii) = coords(:, thisOne(1)); 
end

% We loop for the number of line segements, which is the number of coords - 1.
for(ii=1:size(sampleCoords,2)-1)
    % Draw a line for each measured segment
    h(ii) = line(sampleCoords(2,ii:ii+1), sampleCoords(1,ii:ii+1), 'Color', 'r', 'LineWidth', 2);
    
    % Now, compute the manifold distance between these points.
    % mrManDist returns the distance to all other points from the given 'start' point.
    allDist = mrManDist(nodes, edges, sampleNodes(ii), mmPerPix, -1, 0);
    % We just want the distance from the start point to the end point, so we
    % pull that out by providing the index of the end point.
    dist(ii) = allDist(sampleNodes(ii+1));
    disp(['Cortical distance of segment ',num2str(ii),': ',num2str(dist(ii)),' mm.']);  
end
disp(['Total cortical distance: ',num2str(sum(dist)),' mm.']);
if (plotFlag)
uiwait(msgbox(['Total cortical distance: ',num2str(sum(dist)),' mm.'], ...
        'Cortical Distance', 'modal'));
end

    for ii=1:length(h)
    delete(h(ii))
end
return
