function coords = mapIndices2RoiCoords(view,indices);
%
% coords = mapIndices2RoiCoords(view,indices);
%
% Given a vector of indices into a data map
% (like a ph, amp, or map field), return a 
% 3 x nVoxels matrix of ROI coordinates for 
% the same points. Note that these coords 
% are in the view space (for inplanes, the
% underlying anatomicals), and there may
% be several voxels in the view that map 
% to the same data voxel. In this case,
% only one voxel is returned per data voxel --
% the upper right corner.
%
% 01/05 ras.
viewType = viewGet(view,'viewType');

switch viewType
    case {'Inplane','Flat'},
        [y x z] = ind2sub(dataSize(view,1),indices);
        rsFactor = upSampleFactor(view,1);
        y = y .* rsFactor(1);
        x = x .* rsFactor(2);
        coords = [y x z]';
    case {'Volume','Gray'},
        coords = view.coords(:,indices);
end

return
