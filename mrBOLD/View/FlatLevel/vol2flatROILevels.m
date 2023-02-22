function flatROI = vol2flatROILevels(volROI,volView,flatView)
% 
% flatROI = vol2flatROILevels(volROI,volView,flatView)
%
% Creates a flat ROI from a volume ROI by looking up the
% corresponding coords. Will create coordinates in the 
% 'separate gray levels' slices.
%    
% flatROI and volROI are ROI structures, like those found in 
% view.ROIs 
%
% volView must be the VOLUME structure.
% flatView must be the FLAT structure.
%
% ras, 10/04. Version for flat level views, off vol2flatROI.
% Intersect volROI.coords with volView.coords.  When in gray mode, 
% this restricts the ROI to the gray matter.
ROIcoords = volROI.coords;
ROIcoords = intersectCols(ROIcoords,volView.coords);

% init coords for flat ROI
coords = [];

% get grayCoords for flat, across all slices
grayCoords = []; flatCoords = [];
for slice = 1:numSlices(flatView)
    grayCoords = [grayCoords flatView.grayCoords{slice}];
    sliceCoords = flatView.coords{slice};
    sliceCoords(3,:) = slice;
    flatCoords = [flatCoords sliceCoords];
end

[bothCoords ia ib] = intersectCols(ROIcoords,grayCoords);
coords = flatCoords(:,ib);

% % error check. ROIcoords should be contained entirely within gray coords.
% if (size(ROIcoords,2) ~= size(coords,2)) & (strcmp(volView.viewType,'Gray'))
%    fprintf(['\nGray nodes loaded from gray classification file are ',...
%          'incompatible with those loaded from the flat.mat file. ',...
%          'Rebuild the Gray and Flat view: rm Gray/*.mat Flat/*.mat']);
% end

% Remove duplicates (there shouldn't be any, but just to make sure).
coords = intersectCols(coords,coords);

% Set the fields 
flatROI.coords = coords;
flatROI.name = volROI.name;
flatROI.color = volROI.color;
flatROI.viewType = flatView.viewType;

return


% from the older intersect code:
% flatCoords = round(flatView.coords(:,ib));
% flatCoords = [flatCoords; h*ones([1,size(flatCoords,2)])];
% coords = [coords,flatCoords];