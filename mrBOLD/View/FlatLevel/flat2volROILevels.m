function volROI = flat2volROILevels(flatROI,flatView,volView)
% 
% volROI = flat2volROILevels(flatROI,flatView,volView)
%
% Creates a volume ROI from a flat ROI by looking up the
% corresponding coords.  The tricky thing about this function
% is that FLAT -> VOL is a one to many mapping, and we need to
% find all the corresponding volume coords. 
%    
% flatROI and volROI are ROI structures, like those found in 
% view.ROIs 
%
% volView must be the VOLUME structure.
% flatView must be the FLAT structure.
%
% ras, 10/04. Created off flat2volROI.
ROIcoords = flatROI.coords;

for slice = 1:numSlices(flatView)
    % get the ROI coords from this slice
    subCoords = ROIcoords(:,ROIcoords(3,:)==slice);
    
	% for flat level view, there's an indices matrix that
	% tells you which columns in coords/grayCoords come
	% from what ROI coords:
    if ~isempty(subCoords)
		ind = sub2ind(size(flatView.indices),subCoords(1,:),...
                        subCoords(2,:),subCoords(3,:));
		flatIndices = flatView.indices(ind);
		
		% remove any non-measured flat points -- the index will be 0
		flatIndices = flatIndices(flatIndices > 0);
		
		% grab the corresponding gray coords
		coords = flatView.grayCoords{slice}(:,flatIndices);    end
end

% Remove duplicates (there shouldn't be any, but just to make sure).
coords = intersectCols(coords,coords);

% Set the fields 
volROI.coords = coords;
volROI.name = flatROI.name;
volROI.color = flatROI.color;
volROI.viewType = volView.viewType;

return


