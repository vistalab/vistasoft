function bins = buildNodeBins(flatView, volNodeIndices, binDist, slice, grayView)
%
% bins = buildNodeBins(flatView, volNodeIndices, binDist, slice, grayView)
%
% Bins the nodes specified by volNodeIndices. This probably only makes
% sense if the nodes form a rough line and you want to measure something
% along that line. 
%
% volNodeIndices are indices into the gray matter node list for the
% appropriate hemisphere (specified by slice- 1=left, 2=right). You might
% get this from a function like roi_getFlatNodes.
%
% binDist is the bin size (approximately the diameter of the bin) in mm.
%
% grayView will be initialized (hidden) if it isn't provided.
%
% NOTE! this function assumes that the first node in the volNodeIndices
% list is the one that you want to start with. Again, this probably only
% makes sense if the nodes form a rough line or curve, in which case the first node
% should be an endpoint of the line.
%
% RETURNS:
%  bins- an array of bin structs, one for each bin created. This includes:
%   bins.binEdgeNode: the node that defines the leading edge of the bin.
%   bins.distToPrev:  distance (in mm) to previous bin.binEdgeNode.
%   bins.allNodes:    all the other nodes from volNodeIndices that are <=
%                     binDist from bins.binEdgeNode.
%
%
% This is computationally expensive process- use sparingly!
%
% The basic steps that we need to do in here include:
% * find a start point
%    - coords are already sorted, so we just take the first coord
% * find a gray node for each point
% * find distance from start node to every other node
%
% SEE ALSO:
%  roi_getFlatNodes
%  mrManDist
%
% HISTORY:
% 2002.12.20 RFD (bob@white.stanford.edu) wrote it, based on code from
% various other places (esp. cortMag code). However, I rethought the logic
% and made sure that we are doing things correctly.

bins = {};

if (~exist('grayView','var') | isempty(grayView))
    grayView = initHiddenGray;
end

% This is stupid that we have to get this from a file.
global vANATOMYPATH;
mmPerPix = readVolAnatHeader(vANATOMYPATH);

% making a copy of nodes & edges is a VERY expensive convenience! So, we
% don't do it.
if(slice==1)
    nodes = grayView.allLeftNodes;
    edges = grayView.allLeftEdges;
else
    nodes = grayView.allRightNodes;
    edges = grayView.allRightEdges;
end
layerOneInd = find(nodes(6,:)==1);
[nodes,edges,nNotReached] = keepNodes(nodes,edges,layerOneInd,1);
if(nNotReached>0)
    warning(['keepNodes (layer one nodes): some nodes not connected!']);
end

% We loop until we've dealt with all the nodes. The basic idea is to
% pick a binEdgeNode, bin all nodes within binDist of that
% binEdgeNode, then find the next binEdgeNode and do it again.
%
binNum = 1;
oldFirstVal = volNodeIndices(1);
thisNodeIndex  = unique(volNodeIndices);
binCenterIndex = find(thisNodeIndex==oldFirstVal);
distToNext = 0;

while(~isempty(thisNodeIndex))
    % Select binEdgeNode
    bins(binNum).binEdgeNode = thisNodeIndex(binCenterIndex);
    
    % The following seems odd, but it turns out to be most efficient to
    % compute the distance to the next binCenter (since we need to do that
    % anyway to find the next binCenter). So, we save the distToNext (see
    % below) and insert it here as 'distToPrev'. Of course, the first time
    % through, distToPrev should be zero, so we initialize distToNext to 0
    % (above).
    bins(binNum).distToPrev = distToNext;
    if(length(thisNodeIndex)>1)
        % remove the binCenter node from further consideration as a candidate.
        thisNodeIndex(binCenterIndex) = [];
        
        % This will get the dist to ALL nodes.
        allDist = mrManDist(nodes, edges, bins(binNum).binEdgeNode, mmPerPix, NaN, 0);
    
        % Find all points within binDist of binEdgeNode.
        % We actually don't care about the distances right now, so we
        % just grab the indices of the non-NaN entries.
        [c, ia] = intersect(thisNodeIndex, find(allDist <= binDist));
        bins(binNum).allNodes = [bins(binNum).binEdgeNode, c];
        % now we can remove all the nodes that intersected (ia) from
        % thisNodeIndex. 
        if(~isempty(ia))
            thisNodeIndex(ia) = [];
        else
            disp([mfilename,': No nodes to include in this bin- maybe bin size is too small?']);
        end
        % set up the next bin center as the next nearest node.
        % The following finds the indices into allDist of all those nodes
        % > binDist from the current binEdgeNode- ie, all those nNOT in the current bin.
        c = intersect(thisNodeIndex, find(allDist>binDist));
        % the following finds the index into thisNodeIndex of the closest
        % node. The code is dense, but several minutes of quiet reflect
        % will reveal it's efficacy.
        if(~isempty(c))        
            distToNext = min(allDist(c));
            binCenterIndex = find(allDist(thisNodeIndex)==distToNext);
        end
        binNum = binNum+1;
    elseif(length(thisNodeIndex)==1)
        bins(binNum).allNodes = thisNodeIndex(binCenterIndex);
        thisNodeIndex(binCenterIndex) = [];
    else
        % thisNodeIndex is empty- the while loop will end
        thisNodeIndex = [];
    end
end

if(any(isnan(cat(1,bins.distToPrev))))
    % Oops! this shouldn't happen with a properly connected mesh!
    bins = [];
    warning('NO BINS CREATED DUE TO UNCONNECTED NODES.');
else
    disp([num2str(binNum-1),' bins created from ',num2str(length(volNodeIndices)),' nodes.']);
end

return;