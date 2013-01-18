function cortMag = buildCortMagBins(cortMag, flatView, grayView)
%
%  cortmag = buildCortMagBins(cortMag, flatView, grayView)
%
%  Loads the bins for all the ROIs. This is a necessary and computationally%  expensive
%   step torward computing the cortical magnification function. We should%   avoid doing it
%   more often than necessary.
%
% HISTORY:
%   2002.03.20 RFD (bob@white.stanford.edu) wrote it, based
%   on code by Wandell, Baseler and Brewer.
%   2002.12.11 RFD: added flatDataFlag check so that we can 
%   either use the data pulled from the flat map, or get the
%   data from the volume.


% The basic steps that we need to do:
% * find a start point
%    - ROI coords are already sorted, so we just take the first coord
% * find a gray node for each point
% * find distance from start node to every other node
% * grab the co and ph for each node.

bins = {};

% if(strcmp(cortMag.hemisphere,'left'))
%     nodes = grayView.allLeftNodes;
%     edges = grayView.allLeftEdges;
% else
%     nodes = grayView.allRightNodes;
%     edges = grayView.allRightEdges;
% end
nodes = grayView.nodes;
edges = grayView.edges;
            
for(roiNum=1:length(cortMag.ROIs))
    disp(['Binning nodes for ROI ',num2str(roiNum),' of ',num2str(length(cortMag.ROIs)),'...']);

    % We loop until we've dealt with all the nodes. The basic idea is to
    % pick a binCenterNode, bin all nodes within binDist of that    % binCenterNode, 
    % compute the phase of all those points, then find the next    % binCenterNode and
    % do it again.
    %
    binNum = 1;
    thisNodeIndex = cortMag.nodeIndices{roiNum};
    % Here we use a sparse matix to create a look-up table of phase and co values
    % for each nodeIndex. These data have been derived from the flat map
    % coranal. The corMag struct has a flag (flatDataFlag) that tells us if we should use
    % the flat data or actually go and get the data from the volume. 
    nodePhTable = sparse(cortMag.nodeIndices{roiNum}, 1, cortMag.data{roiNum}.ph);
    nodeCoTable = sparse(cortMag.nodeIndices{roiNum}, 1, cortMag.data{roiNum}.co);
    while(~isempty(thisNodeIndex))
        % Select binCenterNode
        bins{roiNum}(binNum).binCenterNode = thisNodeIndex(1);
        if(length(thisNodeIndex)>1)
            thisNodeIndex = thisNodeIndex(2:end);
            
            % Find all points within binDist of binCenterNode.
            % We actually don't care about the distances right now, so we            % just grab the
            % indices of the non-NaN entries.
            nodesInBin = find(~isnan(mrManDist(nodes, edges, bins{roiNum}(binNum).binCenterNode, ...
                                            cortMag.mmPerPix, NaN, cortMag.binDist)));
            [c, ia] = intersect(thisNodeIndex, nodesInBin);
            bins{roiNum}(binNum).allNodes = [bins{roiNum}(binNum).binCenterNode, c];
            % now we can remove all the nodes that intersected (ia) from            % thisNodeIndex.
            % BUT- if ia is not consecutive- that's a problem. These nodes            % are supposed to be sorted for
            % us! We do a hack for now.
            if(~isempty(ia))
                thisNodeIndex = thisNodeIndex(max(ia):end);
            end
            
            if(isfield(cortMag,'flatDataFlag') & cortMag.flatDataFlag==1)
                bins{roiNum}(binNum).allPh = full(nodePhTable(bins{roiNum}(binNum).allNodes));
                bins{roiNum}(binNum).allCo = full(nodeCoTable(bins{roiNum}(binNum).allNodes));
            else
                
                bins{roiNum}(binNum).allPh = grayView.ph{cortMag.expNumber}(bins{roiNum}(binNum).allNodes);
                bins{roiNum}(binNum).allCo = grayView.co{cortMag.expNumber}(bins{roiNum}(binNum).allNodes);
            end
            
            % But, the clipped nodes may contain some unconnected nodes.            % So, we may need to go back to
            % the complete set of nodes. And, since those have different            % indices, we need to extract the
            % volume coords and then look up the corresponding data.
            % Unfortunately, this makes this loop an order of magnitude            % slower. So, we cheat with the above shortcut.
            % The following code is a stream-lined version of            % 'getCurDataROI' to try to speed things up a bit.
%             coords = nodes([2,1,3], bins{roiNum}(binNum).allNodes);
%             [inter,ROIIndices,viewIndices] = intersectCols(coords,%             grayView.coords);
%             bins{roiNum}(binNum).allPh = NaN*ones([1,size(coords,2)]);
%             bins{roiNum}(binNum).allPh(ROIIndices) =%             grayView.co{cortMag.expNumber}(viewIndices);
%             bins{roiNum}(binNum).allCo = NaN*ones([1,size(coords,2)]);
%             bins{roiNum}(binNum).allCo(ROIIndices) =%             grayView.ph{cortMag.expNumber}(viewIndices);     

            binNum = binNum+1;
        else
            thisNodeIndex = [];
        end
    end
    bins{roiNum}(1).distToPrev = 0;
    for(binNum=2:length(bins{roiNum}))
        allDist = mrManDist(nodes, edges, bins{roiNum}(binNum).binCenterNode, ...
                            cortMag.mmPerPix, NaN, 0);
        bins{roiNum}(binNum).distToPrev = allDist(bins{roiNum}(binNum-1).binCenterNode);
    end
    if(any(isnan(cat(1,bins{roiNum}.distToPrev))))
        % Oops! this shouldn't happen with a properly connected mesh!
        bins{roiNum} = [];
        disp(['   ROI ',num2str(roiNum),' DROPPED BECAUSE OF UNCONNECTED NODES.']);
    else
        disp(['   ',num2str(binNum-1),' bins created from ',num2str(length(cortMag.nodeIndices{roiNum})),' nodes.']);
    end
end
cortMag.bins = bins;

return;

% Debugging
dist={}; meanPh={};
for(roiNum=1:length(cortMag.ROIs))
    for(binNum=1:length(bins{roiNum}))
        dist{roiNum}(binNum) = bins{roiNum}(binNum).distToPrev;
        meanPh{roiNum}(binNum) = mean(unwrap(bins{roiNum}(binNum).allPh));
    end
    figure;plot(cumsum(dist{roiNum}), meanPh{roiNum});
end