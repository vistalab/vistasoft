function roi = roiMatchFunctionals(roi, func, anat);
%
%  roi = roiMatchFunctionals(roi, func, anat);
% 
% 'Flesh out' the list of coordinates in an ROI such that
% they cover all the anatomical voxels which map to a given
% functional voxel. Useful for proper visualization on meshes.
%
% The 'anat' mr object should be the same object on which
% the ROI coordinates are defined. The 'func' should be 
% another mr object which is in some way coregistered to the
% anatomy. (If they both cover the same physical extent
% in space, this will work -- see mrBaseXform.). This function
% will:
%   (1) take all the currently-defined coords in the ROI;
%   (2) see which functional voxels these coordinates map to;
%   (3) for each functional voxel, find all the other anatomy
%       voxels which map to it;
%   (4) ensure that roi.coords includes all these anatomical voxels.
%
% The returned ROI, like the input ROI, will have coordinates defined
% in terms of the anatomy. But these coords may be augmented so that
% all anatomical voxels which map to the functionals are included.
%
%
% ras, 01/2007.
if nargin<3, error('Not enough input args.');       end

% find the xform from func -> anat
func2anat = mrBaseXform(anat, func);

% find the unique voxels in func to which the ROI maps
roiFuncCoords = round( coordsXform(inv(func2anat), roi.coords')' );
roiFuncCoords = intersectCols(roiFuncCoords(1:3,:), roiFuncCoords(1:3,:));

% repeat the process for all coords in the anat size
[X Y Z] = meshgrid(1:anat.dims(2), 1:anat.dims(1), 1:anat.dims(3));
anatCoords = [Y(:) X(:) Z(:)]';
allFuncCoords = round( coordsXform(inv(func2anat), anatCoords')' );

% find the indices I of allFuncCoords which match the roifuncCoords.
I = [];
for v = 1:size(roiFuncCoords, 2)
    c = roiFuncCoords(:,v);
    subInd = find(allFuncCoords(1,:)==c(1) & allFuncCoords(2,:)==c(2) & ...
                  allFuncCoords(3,:)==c(3));
    I = [I subInd];
end


% since the columns of allFuncCoords match those of anatCoords,
% the indices I will identify the anatCoords which should be in the ROI:
tgtCoords = anatCoords(:,I);

% we could just make roi.coords equal to tgtCoords, but this generally
% shuffles the order of the columns. Only do that if necessary:
% if all columns are already included, don't modify the ROI.
commonA = intersectCols(anatCoords, anatCoords);
commonB = intersectCols(roi.coords, roi.coords);
if isequal(commonA, commonB)
    % return an unmodified ROI
    return
else
    % replace with the target coords
    roi.coords = tgtCoords;
end


return
