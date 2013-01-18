function view = getFlatLevelCoords(view)
%
% view = getFlatLevelCoords(view)
%
% view: must be a flat view
%
% Loads gLocs2d and gLocs3d coordinates.  Keeps only those voxels
% that correspond to the inplane coordinates.  Sets FLAT
% fields: coordsRight, coordsLeft, grayCoordsRight,
% grayCoordsLeft.
%
% To clarify, here's the format of important
% fields in the flat level view's flat struct:
%
%  anat: 3D matrix with the following slice order: 
%       first slice -- LH, across levels,
%       second slice -- RH, across levels,
%       slices 3:numLeftLevels+2: separate left levels
%       numLeftLevels+3:end: separate right levels
%
%  map,amp,ph,co: cell of size numScans. Each entry
%  contains a map resized to be the same size as the
%  anat field. The code will therefore treat
%  overlaying fields on the anat in the same manner
%  as with inplane slices. The UI simply selects
%  the appropriate slice subset for display based on 
%  the hemisphere buttons / level controls.
%
% coords: now consolidated to a single 3 x N matrix. 
% N represents the number of nodes from the gray
% view (after up- and down-sampling). Row 1 represents
% each voxel's x position along the flat surface, Row 2
% represents the y position, and Row 3 represents the
% slice number (the slice number following the same
% format as the anat field, specified above). This way,
% saved ROIs have the same format as inplane ROIs, but
% will have an additional field (named 'Tag', and with
% the value 'Flat-Level-Specific ROI') to distinguish from
% other flat ROIs. NOTE: loading in other flat ROIs
% into a flat level view should work, since, like the old
% flat view, the first and second slices are the L and R
% hemispheres across levels.
%
% ROIs.coords: ROI coords will specify x,y, and slice num,
% similar to Inplane ROI coords
%
% If the rescale factor is changed, make parallel changes
% to expandAnatFlatLevels.

% ras, 08/04. For Flat Multi-level view, compute a third row
%             for the flat coords: in addition to gLocs2d, also
%             add the information on the gray level to which each node
%             belongs (in the hiddenGray's 'nodes' field, 6th row).
if ~strcmp(view.viewType,'Flat')
    myErrorDlg('function getFlatLevelCoords only for Flat Level view.');
end

pathStr = fullfile(viewGet(view,'subdir'),'coordsLevels');

if ~check4File(pathStr) 
    buildFlatLevelCoords(view,pathStr);
end

% Load Flat/coords and fill the fields
load(pathStr);
view.coords = coords;
view.grayCoords = grayCoords;
view.indices = indices;
view.leftPath = leftPath;
view.rightPath = rightPath;
view.numLevels = numLevels;

if isfield(view,'ui')
    view.ui.imSize = imSize;
end

return
