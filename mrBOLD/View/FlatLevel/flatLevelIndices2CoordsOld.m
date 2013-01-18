function vol = flatLevelIndices2Coords(view,vals,interpFlag);
% vol = flatLevelIndices2Coords(view,vals,[interpFlag]);
%
% For flat level view, convert a set of values stored
% as a row vector (corresponding to entries in the 
% FLAT.coords field) to a 3D volume corresponding to the
% set of slices used to represent the different flat levels.
%
% interpFlag: optional flag to interpolate between
% sampled values (otherwise does nearest-neighbor assignment).
% Default value is 1, interpolate.
%
% The format of the slice order (the 3rd dimension in vol) is 
% [Left avg] [Right Avg] [Left Separate Gray Levels] [Right Sep. Levels]
%
% ras 10/04/04.
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
    sliceInds = find(view.coords(3,:)==slice);
    sliceData = vals(sliceInds);
    subCoords = view.coords(:,sliceInds);
    
    % interpolate if selected
    if interpFlag==1
        
        % The operator .' is the NON-CONJUGATE transpose.  Very important.
        img = myGriddata(subCoords,sliceData.',mask(:,:,slice));
        
        % assign to volume
        vol(:,:,slice) = img;
    else
        % just remap from the corresponding coords
        vol(sliceInds) = sliceData;
    end
end
    

return