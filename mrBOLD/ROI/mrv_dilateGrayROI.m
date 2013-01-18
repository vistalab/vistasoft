function newROI=mrv_dilateGrayROI(view,ROIcoords,iterations)
% newROI=dilateGrayROI(view,ROIcoords,iterations)
% PURPOSE: Dilates an ROI in the mrVISTA 'GRAY' view.
% ROIs are dilated within the Gray matter respecting the Gray matter
% connections
% The routine first computes the gray matter connection matrix
% using makeGrayConMat. This is (strictly) a mrFlatMesh function.
% example:
% newROICoords=dilateGrayROI(VOLUME{1},VOLUME{1}.ROIs(1).coords,2);
% ARW 100704: Wrote it
% 
% See also mrv_dilateCurrentROI
% Last modified: $date$

% Do some error checking here...

% if (~exist(view,'var'))
%     error('This function requires a mrVISTA view');
% end 
if (~exist('ROIcoords','var'))
    error('No ROI coords passed');
end
if (~exist('iterations','var'))
    iterations=1;
end

% Need to turn the ROI coords (3xn) into indices into coords (3x (nCoords))
anatSize=size(view.anat);
roiSize=size(ROIcoords);
ROIindices=zeros(roiSize(2),1); % make a vector of indices
grayCoords=view.coords;

% Need to convert ROIcoords into indices into the list of gNodes.
[ismem, ROIindices] = ismember(ROIcoords', grayCoords', 'rows');

% Tidy up this list
ROindices=unique(ROIindices);
ROIindices=ROIindices((find(ROIindices~=0)));
ROIindices=ROIindices(:);

newROIindices=ROIindices;

disp('Dilating');

for thisIteration=1:iterations
    fprintf('\nDoing iteration %d',thisIteration);
    messString=sprintf('Iteration #%d',thisIteration);
    [neighborInds,junk] = find(view.grayConMat(:,ROIindices));
    newROIindices = [newROIindices;neighborInds];
end

ROIindices=unique(newROIindices);

%We need to return the new ROI in subscript not index form
newROI=grayCoords(:,ROIindices);

return;