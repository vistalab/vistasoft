function vol = flatLevelIndices2Coords(view,vals,interpFlag);
% vol = flatLevelIndices2Coords(view,vals,[interpFlag]);
%
% For flat level view, convert a set of values stored
% as a row vector (corresponding to entries in the 
% FLAT.coords field) to a 3D volume corresponding to the
% set of slices used to represent the different flat levels.
%
% Currently (10/11/04), vals must be a 3D matrix of size
% 1 x nVoxels x nSlices. This may sound pretty silly, but it
% reflects the conventions of the GLM code. nVoxels should be
% largest number of voxels within a slice (as determined from
% the view's coords and grayCoords fields). This format is
% produced in er_selxavg (omnibus map) and er_computeContrastMap
% (contrast maps).
%
% interpFlag: optional flag to interpolate between
% sampled values (otherwise does nearest-neighbor assignment).
% Default value is 1, interpolate.
%
% The format of the slice order (the 3rd dimension in vol) is 
% [Left avg] [Right Avg] [Left Separate Gray Levels] [Right Sep. Levels]
%
% ras 10/04/04.
% ras 10/11/04: updated to do slices separately, way less
% elegant but saves memory/maybe time.
if ieNotDefined('interpFlag')
    interpFlag = 1;
end

% initialize vol
vol = zeros(size(view.indices));

% get mask for the unfold
mask = view.ui.mask;

% loop through each slice in vol
numSlices = size(vol,3);
for slice = 1:numSlices
    
    % get data from vals corresponding to this slice
    sliceData = vals(:,:,slice);
    subCoords = view.coords{slice};
    
    if ~isempty(subCoords)        
        % interpolate if selected
        if interpFlag==1 & ~(size(subCoords,2)<3)
            
            % The operator .' is the NON-CONJUGATE transpose.  Very important.
            img = myGriddata(subCoords,sliceData.',mask(:,:,slice));
            
            % assign to volume
            vol(:,:,slice) = img;
        else
            % just remap from the corresponding coords
            sliceInds = sub2ind(view.ui.imSize,subCoords(1,:),subCoords(2,:));
            vol(sliceInds) = sliceData(1:size(subCoords,2));
        end
    end
end
    

return