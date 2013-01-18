function [skelXYZ, skelPerimDist, skelLinearDist, roiIm] = dtiCallosalSkeleton(ccCoords)
%
% [skelXYZ, skelPerimDist, skelLinearDist, roiImg] = dtiCallosalSkeleton(ccCoords)
%
% Skeletonizes the corpus callosum with a single stroke and returns the
% coordinates of this skeleton (sorted from the most posterior end to the
% most anterior). Also returns the distance of each skeleton point to the
% CC edge (skelPerimDist) and the distance along the skeleton from each
% skeleton point to the first (posterior-most) point (skelLinearDist).
%
% Note that the ccCoords are assumed to be in AC-PC space, but any space
% will work if left-right is along the first dim, anterior-posterior is
% along the second dim, and the lower values along the second dim are the
% more posterior regions.
%
% Note that the current algorithm assumes that the CC is in a plane
% perpendicular to the left-right axis.
%
% Depends on: Matlab's Image Processing Toolbox.
%
% 2006.11.20 RFD: wrote it.

% work on a uniform grid
ccCoords = round(ccCoords);
        
% Extract midline coords
% *** TO DO: fit a plane rather than assumeing that the CC is perpendicular
% to the left-right axis
midLine = median(ccCoords(:,1));
ccCoords = ccCoords(ccCoords(:,1)==midLine,:);

% Convert to a binary image (with some padding) to use Matlab's bw tools.
imSize = [min(ccCoords(:,2)) max(ccCoords(:,2)); min(ccCoords(:,3)) max(ccCoords(:,3))]';
offset = imSize(1,:)-10;
imSize = diff(imSize)+20;
roiImg = zeros(imSize);
roiImg(sub2ind(imSize,ccCoords(:,2)-offset(1),ccCoords(:,3)-offset(2))) = 1;
roiImg = bwmorph(roiImg,'clean');
roiImg = bwmorph(roiImg,'close');
roiImg = bwmorph(roiImg,'fill');
%skelImg = bwmorph(roiImg,'thin',Inf);
skelImg = bwmorph(bwmorph(bwmorph(roiImg,'thin',inf),'dilate'),'thin',inf);
perimImg = bwperim(bwmorph(roiImg,'dilate'));
distImg = bwdist(perimImg).*skelImg;
%figure;imagesc((distImg+perimImg)'); axis image xy;
[tmpY,tmpZ,tmpPerimDist] = find(distImg);
% Find the posterior end of the skeleton line
[postY,postZ,tmp] = find((bwmorph(skelImg,'spur')-skelImg));
postZ = postZ(postY==min(postY));
postY = postY(postY==min(postY));
keepInds = ~(tmpY==postY&tmpZ==postZ);
clear skelDist skelYZ skelPerimDist;
skelLinearDist(1) = 0;
skelYZ(1,:) = [postY postZ];
skelPerimDist(1) = tmpPerimDist(~keepInds);
for(jj=2:length(tmpPerimDist))
    [ind, bestSqDist] = nearpoints2d(skelYZ(jj-1,:)', [tmpY(keepInds)';tmpZ(keepInds)']);
    tmp = find(keepInds);
    ind = tmp(ind);
    skelYZ(jj,:) = [tmpY(ind) tmpZ(ind)];
    skelPerimDist(jj) = tmpPerimDist(ind);
    skelLinearDist(jj) = sqrt(bestSqDist);
    keepInds(ind) = 0;
end
roiIm.img = double(roiImg);
roiIm.img(skelImg) = distImg(skelImg);
roiIm.offset = offset;
skelXYZ = [repmat(midLine,size(skelYZ,1),1) skelYZ(:,1)+offset(1) skelYZ(:,2)+offset(2)];
skelLinearDist = cumsum(skelLinearDist);
return;
