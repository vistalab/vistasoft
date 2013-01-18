function dataCorners2 = atlasMergeAdjacentCorners(dataCorners,dataCorners2);
%
%   dataCorners2 = atlasMergeAdjacentCorners(dataCorners,dataCorners2);
%
% Author:  Wandell
% Purpose:
%     When adding an atlas segment, sometimes we want the corners from
%     adjacent segments to be the same.  This routine finds the two closest
%     corners and makes the corner positions in the second segment equal to
%     the closest ones in the first segment
%
%Examples
%

% First, we check the distance from each corner in corners2 to each corner
% in corners.  This is a 4x4 distance matrix. 
%
for ii=1:4
    for jj=1:4
        d(ii,jj) = norm(dataCorners(ii,:) - dataCorners2(jj,:));
    end
end

% Find the two points with the closest values
[v,idx] = sort(d(:));

% Find the row and column coordinates of these two points
[r1,c1] = ind2sub(size(d),idx(1));

% Set the dataCorners2(c,:) equal to the positions of dataCorners(r,:)
dataCorners2(c1,:) = dataCorners(r1,:);

% Choose the second point that is closest with the constraint that this
% second point in dataCorners2 cannot be attached to the point we have
% already chosen.  Another way to do this is to remove the row containing
% point at r1, recalculale the distance matrix, and then find the minimum.
for ii=2:length(idx)
    [r2,c2] = ind2sub(size(d),idx(ii));
    if r1 ~= r2
        dataCorners2(c2,:) = dataCorners(r2,:);
        break;
    end
end

return;
