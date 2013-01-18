function volROI = flat2volROI(flatROI,flatView,volView)
% 
% volROI = flat2volROI(flatROI,flatView,volView)
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
% djh, 8/98.
%
% djh, 8/4/99.  Need to round the coords because we no longer do it in
%               loadGLocs.  Also, remove duplicate flat coords.
% djh, 2/2001. Use intersectCols instead of coords2Indices

global mrSESSION

% check that the ROI fields are properly set
flatROI = roiCheck(flatROI);

% This should be much fastter but its busted because intersect removes duplicates and
% we need to keep the duplicates here because flat->gray is a one-to-many mapping.
%
% coords = [];
% for h = 1:2
%     ROIcoords = flatROI.coords([1:2],find(flatROI.coords(3,:) == h));
%     if ~isempty(ROIcoords)
%         [tmp,ROIIndices,flatIndices] = intersectCols(ROIcoords,round(flatView.coords{h}));
%         coords = [coords, flatView.grayCoords{h}(:,flatIndices)];
%     end
% end

coords = [];
flatImSize = flatView.ui.imSize;
for h = 1:2
  ROIcoords = flatROI.coords([1:2],find(flatROI.coords(3,:) == h));
  if ~isempty(ROIcoords)
    ROIIndices = coords2Indices(ROIcoords,flatImSize);
    flatIndices = coords2Indices(round(flatView.coords{h}),flatImSize);
    bothIndices = intersect(ROIIndices,flatIndices);
    for id = 1:length(bothIndices)
      indices = find(flatIndices == bothIndices(id));
      coords = [coords, flatView.grayCoords{h}(:,indices)];
    end
  end
end

% Remove duplicates (there shouldn't be any, but just to make sure).
coords = intersectCols(coords,coords);

% Set the fields 
volROI = flatROI;
volROI.coords = coords;
volROI.viewType = volView.viewType;

return


