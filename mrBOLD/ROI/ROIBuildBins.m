function ROIdata = ROIBuildBins(ROIdata, flatView, grayView)
%
%  ROIdata = ROIBuildBins(ROIdata, flatView, grayView)
%
%  Creates the bins for all nodes of a FLAT line ROI. This is a
%  necessary and computationally
%  expensive step torward computing the distance along an ROI. 
%
% HISTORY:
%   2002.01.05 AAB adapted it for flat line ROI distance measurements based
%   on the cortical magnification code by Dougherty, Wandell, Baseler and Brewer.

% The basic steps that we need to do:
% * find a start point
%    - ROI coords are already sorted, so we just take the first coord
% * find a gray node for each point (gray nodes indices are built by ROIBuildNodes
%      and stored in ROIdata).
% * find distance from start node to every other node
% * grab the co and ph for each node.

bins = {};
nodes = double(grayView.nodes);
edges = double(grayView.edges);
nodeIndices = ROIdata.nodeIndices

% We loop until we've dealt with all the nodes. The basic idea is to
% pick a binCenterNode, bin all nodes within binDist of that binCenterNode,compute 
% the phase of all those points, then find the next binCenterNode and do it again.
%
binNum = 1;
% Here we use a sparse matix to create a look-up table of phase and co values
% for each nodeIndex. These data have been derived from the flat map
% coranal. The corMag struct has a flag (flatDataFlag) that tells us if we should use
% the flat data or actually go and get the data from the volume.

% There's an issue here with duplicate nodeIndices. We are just going to
% find the unique ones and toss a bit of data.

[nodeIndices i j]=unique(nodeIndices);
ROIdata.ph=ROIdata.ph(i);
ROIdata.co=ROIdata.co(i);
ROIdata.map=ROIdata.map(i);
ROIdata.amp=ROIdata.amp(i);

nodePhTable = sparse(nodeIndices, ones(length(nodeIndices),1), ROIdata.ph,length(nodes),1);
nodeCoTable = sparse(nodeIndices, ones(length(nodeIndices),1), ROIdata.co,length(nodes),1);
nodeMapTable = sparse(nodeIndices, ones(length(nodeIndices),1), ROIdata.map,length(nodes),1);
nodeAmpTable = sparse(nodeIndices, ones(length(nodeIndices),1), ROIdata.amp,length(nodes),1);

while(~isempty(nodeIndices))
    % Select binCenterNode
    bins(binNum).binCenterNode = nodeIndices(1);
    if(length(nodeIndices)>1)
        nodeIndices = nodeIndices(2:end);
        
        % Find all points within binDist of binCenterNode.
        % We actually don't care about the distances right now, so
        % we
        % just grab the indices of the non-NaN entries.
        nodesInBin = find(~isnan(mrManDist(nodes, edges, bins(binNum).binCenterNode, ...
            ROIdata.mmPerPix, NaN, ROIdata.binDist)));
        [c, ia] = intersect(nodeIndices, nodesInBin);
        bins(binNum).allNodes = [bins(binNum).binCenterNode, c];
        
        % now we can remove all the nodes that intersected (ia) from thisNodeIndex.
        % BUT- if ia is not consecutive- that's a problem. These
        % nodes are supposed to be sorted for us! We do a hack for now.
        if(~isempty(ia))
            nodeIndices = nodeIndices(max(ia):end);
        end
        
        % Assign the ph and co values for each bin
        bins(binNum).allPh = full(nodePhTable(bins(binNum).allNodes));
        bins(binNum).allCo = full(nodeCoTable(bins(binNum).allNodes));
        bins(binNum).allMap = full(nodeMapTable(bins(binNum).allNodes));
        bins(binNum).allAmp = full(nodeAmpTable(bins(binNum).allNodes));
        
        binNum = binNum+1;
    else
        nodeIndices = [];
    end
end

bins(1).distToPrev = 0;
for(binNum=2:length(bins))
    allDist = mrManDist(nodes, edges, bins(binNum).binCenterNode, ...
        ROIdata.mmPerPix, NaN, 0);
    bins(binNum).distToPrev = allDist(bins(binNum-1).binCenterNode);
end
if(any(isnan(cat(1,bins.distToPrev))))
    % Oops! this shouldn't happen with a properly connected mesh!
    bins= [];
    disp([ROIdata.name ' DROPPED BECAUSE OF UNCONNECTED NODES.']);
else
    disp(['   ',num2str(binNum-1),' bins created from ',num2str(length(ROIdata.nodeIndices)),' nodes.']);
end

ROIdata.bins = bins;

return;
