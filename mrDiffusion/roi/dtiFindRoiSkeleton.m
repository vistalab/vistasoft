function skeletonRoi = dtiFindRoiSkeleton(roi, dim)
%Find a line that runs along dim through the ROI center of mass
%
% skeletonRoi=dtiFindRoiSkeleton(roi, dim)
%
% For example, if you want to find ROI center of mass line perpendicular to
% coronal plane (that is, aline running anterior to posterior) you would
% use dtiFindRoiSkeleton(roi, 2) 
% Input: dim can take values 1, 2, 3 for LR (coronal), AP, IS
% 
% Note 1: sometimes using dtiRoiClean leads to a more continuous skeleton.
% Example 1 
%
%      skeletonRoi = dtiFindRoiSkeleton(dtiRoiClean(myRoi, [], {'fillHoles', 'dilate'}), dim);
%
% Note 2: sometimes you may want to turn the skeletonRoi into a fiber to do
% further cool things it -- e.g., dtiFiberResample to obtain a perfectly
% evenly spaced sequence of coordinates along the skeleton. 
% Example 2 
%
%       newFiber=dtiNewFiberGroup('mySkeletonFiber'); 
%       newFiber.fibers{1}=skeletonRoi.coords'; 
%       
% See also: dtiFindBorderBetweenRois
%
% (c) Vistalab

% HISTORY: ER wrote it 03/2010


alldims=1:3; 
otherDims=alldims(~ismember(alldims, dim)); 
skeletonRoi=dtiNewRoi([roi.name '--skeleton, dim' num2str(dim)], [0 0 0 ]); 

mainDirectionCoordinates=unique(round(roi.coords(:, dim))); 
for skeletonCoord=1:length(mainDirectionCoordinates)
skeletonRoi.coords(skeletonCoord, dim)=mainDirectionCoordinates(skeletonCoord); 
skeletonRoi.coords(skeletonCoord, otherDims(1))=mean(roi.coords(find(round(roi.coords(:, dim))==mainDirectionCoordinates(skeletonCoord)), otherDims(1))); 
skeletonRoi.coords(skeletonCoord, otherDims(2))=mean(roi.coords(find(round(roi.coords(:, dim))==mainDirectionCoordinates(skeletonCoord)), otherDims(2))); 
    
end


return

%% Continuing Example 2. 
roisLocation='/biac3/wandell4/data/reading_longitude/dti_y1/ss040804/dti06trilinrt/ROIs'; 
numNodes = 10; 
newFiberResampled =dtiFiberResample(newFiber.fibers{1}, numNodes); %get 10 nodes
%create 10 sphere ROIs (with radius of 5) along the skeleton fiber 
radius = 5; gradmap = colormap(jet); 

%==Here goes some way of generating a wholeBrainFG

if numNodes>64
    error('Only up to 64 color are supported, hence you have to choose <=64 nodes'); 
end
 for roiID=1:numNodes
     color=gradmap(roiID*floor(size(gradmap, 1)/(numNodes-1))-floor(size(gradmap, 1)/(numNodes-1))+1, :); %In this line a color will be formed
     rois{roiID}=dtiNewRoi(['Node ' num2str(roiID)], color, dtiBuildSphereCoords(newFiberResampled(:, roiID), radius)); 
     % == Here goes dtiIntersectFibersWithRoi with arguments wholeBrainFG
     % and rois{roiID}
     dtiWriteRoi(rois{roiID}, fullfile(roisLocation, ['border1015and1030node' num2str(roiID)])); 
 end

