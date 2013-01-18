function [flatNodeIndices, volNodeIndices, flatNodeDist, slice] = roi_getFlatNodes(view, coords, layer, grayView)
%
% [flatNodeIndices, volNodeIndices, flatNodeDist, slice] = roi_getFlatNodes(view, coords, [layer], [grayView])
%
% layer specifies which layer you want your nodes to be drawn from. Default
% is '1' for layer 1 nodes. If this is <0, you get all the layers for each
% node.
% Note that you will always get a cell array for volNodeIndices. If you grab 
% one layer, then there should be just one node per ROI coord. To convert
% the cell array to a normal array, you can do something like: 
%     nodeArray = [volNodeIndices{:}];
%
% The volNodeIndices are indices into the appropriate node list - if slice
% is 1, this is grayView.allLeftNodes and if slice is 2 this is
% grayView.allRightNodes. We use the separate node lists because they are
% propely connected meshes. The grayView.nodes list is clipped to the data
% and includes both left and right hemispheres. Hence, it is not
% appropriate to use it for cortical measurements.
%
% HISTORY
% 2002.12.20 RFD (bob@white.stanford.edu) wrote it, based on code from
% various other places (esp. cortMag code). However, I rethought the logic
% and made sure that we are doing things correctly.

if(nargin<2)
    help(mfilename);
    return;
end
if (~exist('layer','var') | isempty(layer))
    layer = 1;
end
slice = coords(3,1);
if(any(coords(3,:)~=slice))
    error('Not all corrds are in the same hemisphere!');
end
if (layer<0)
    disp(mfilename,': Finding nodes from all layers...');
else
    disp([mfilename,': Finding layer ',num2str(layer),' nodes...']);
end
if (~exist('grayView','var') | isempty(grayView))
    grayView = initHiddenGray;
end

numCoords = size(coords,2);
flatNodeDist = zeros(1,numCoords);
flatNodeIndices = cell(1,numCoords);
volNodeIndices = cell(1,numCoords);
for(ii=1:numCoords)
    % We find the nearest flat gray node for each coordinate.
    % First, take all the distances.
    d = (view.coords{slice}(1,:) - coords(1,ii)).^2 + ...
        (view.coords{slice}(2,:) - coords(2,ii)).^2;
    % Now find the nearest nodes.
    minDist = min(d);
    % min always returns one item, even if there are multiple minima. So,
    % we need to find them all ourselves:
    curFlatInd = find(d==minDist);
    
    % Now find the 3d node indices
    curVolInd = zeros(1,length(curFlatInd));
    curLayers = zeros(1,length(curFlatInd));
    for(jj=1:length(curFlatInd))
        if(slice==1)
            curVolInd(jj) = find(grayView.allLeftNodes(2,:) == view.grayCoords{slice}(1,curFlatInd(jj)) & ...
                grayView.allLeftNodes(1,:) == view.grayCoords{slice}(2,curFlatInd(jj)) & ...
                grayView.allLeftNodes(3,:) == view.grayCoords{slice}(3,curFlatInd(jj)));
            curLayers(jj) = grayView.allLeftNodes(6,curVolInd(jj));
        else
            curVolInd(jj) = find(grayView.allRightNodes(2,:) == view.grayCoords{slice}(1,curFlatInd(jj)) & ...
                grayView.allRightNodes(1,:) == view.grayCoords{slice}(2,curFlatInd(jj)) & ...
                grayView.allRightNodes(3,:) == view.grayCoords{slice}(3,curFlatInd(jj)));
            curLayers(jj) = grayView.allRightNodes(6,curVolInd(jj));
        end
    end
    
    flatNodeDist(ii) = minDist;
    if(layer<0)
        flatNodeIndices{ii} = curFlatInd;
        volNodeIndices{ii} = curVolInd;
    else
        l = find(curLayers==layer);
        if(~isempty(l))
            flatNodeIndices{ii} = curFlatInd(l);
            volNodeIndices{ii} = curVolInd(l);
        else
            flatNodeIndices{ii} = [];
            volNodeIndices{ii} = [];
        end
    end
end

return;
