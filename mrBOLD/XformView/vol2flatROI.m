function flatROI = vol2flatROI(volROI,volView,flatView)
% 
% flatROI = vol2flatROI(volROI,volView,flatView)
%
% Creates a flat ROI from a volume ROI by looking up the
% corresponding coords.  Because VOL -> FLAT is a many
% to one mapping, we need to remove duplicates from the
% flat ROI. 
%    
% flatROI and volROI are ROI structures, like those found in 
% view.ROIs 
%
% volView must be the VOLUME structure.
% flatView must be the FLAT structure.
%
% djh, 8/98.
%
% djh, 8/4/99.  Round the coords because we no longer do it in
% loadGLocs.  Also, use intersectCols instead of intersecting indices.
% Remove duplicate flat coords.
global mrSESSION

% check that the ROI has up-to-date fields
volROI = roiCheck(volROI);

% Intersect volROI.coords with volView.coords.  When in gray mode, 
% this restricts the ROI to the gray matter.
ROIcoords = double(volROI.coords);
ROIcoords = intersectCols(ROIcoords,volView.coords);

coords = [];
for h = 1:2
   [bothCoords,ia,ib] = intersectCols(ROIcoords,flatView.grayCoords{h});
   flatCoords = round(flatView.coords{h}(:,ib));
   flatCoords = [flatCoords; h*ones([1,size(flatCoords,2)])];
   coords = [coords,flatCoords];
end

% if (size(ROIcoords,2) ~= size(coords,2)) & (strcmp(volView.viewType,'Gray'))
%    fprintf(['\nGray nodes loaded from gray classification file are ',...
%          'incompatible with those loaded from the flat.mat file. ',...
%          'Rebuild the Gray and Flat view: rm Gray/*.mat Flat/*.mat']);
% end

% Remove duplicates (there shouldn't be any, but just to make sure).
coords = intersectCols(coords,coords);

% Set the fields 
flatROI = volROI;
flatROI.coords = coords;
flatROI.viewType = flatView.viewType;

return;

%%%%%%%%%%%%%%
% Debug/test %
%%%%%%%%%%%%%%

volROI = VOLUME{1}.ROIs(VOLUME{1}.selectedROI);
flatROI = vol2flatROI(volROI,VOLUME{1},FLAT{1});
newvolROI = flat2volROI(flatROI,FLAT{1},VOLUME{1});
