function vw = computeB0DirectionMap(vw, rawFile, lineROIpoint);
% Compute a map which reflects the coordinate along the scanner Z axis,
% parallel to tbe B0 field.
%
%   view = computeB0DirectionMap(view, [rawFile='Raw/Anatomy/Inplane'], [lineROIpoint]);
%
% The B0 axis is potentially important in explaining certain BOLD artifacts
% -- notably, the artifcats produced by large draining veins such as
% sinuses can be modeled as a function of the angle between this axis and
% the direction of the vein/sinus. This function provides a tool to
% estimate the direction of the B0 field based on the anatomical header
% files.
%
% The value of the map produced are the Z-coordinates of each voxel in
% scanner space. The Z direction is parallel to the B0 field: higher Z
% values are toward the back bore of the magnet (and generally towards the
% superior direction of the brain). 
%
% If the 'lineROIpoint' argument is provided (as a 3-vector of [row,
% column, slice] coordinate), the function will also produce a line ROI
% which passes through this point, and which runs parallel to the B0 axis.
% You can also pass lineROIpoint==-1 to use the center of the view's
% current ROI as the anchor point for the new line ROI.
% [if omitted, no ROI is created]. 
%
% 'rawFile' should be a path to the raw DICOM (or other mrLoad-compatible
% format) files used to create the inplane anatomy. [default: guess the
% standard path used by mrInit2, 'Raw/Anatomy/Inplane'.]
%
% This function works only on the inplane view.
%
% ras, 05/20/2009.

if notDefined('lineROIpoint'),  lineROIpoint = [];  end
if ~exist('rawFile', 'var'),    rawFile = [];       end

scannerXform = viewGet(vw, 'scannerXform', rawFile);

%% compute the map values
% initalize an empty map -- the data will go in the first slot
map = cell(1, numScans(vw));

% create a coordinate grid in the inplane space
sDims = viewGet(vw,'Size');
[X, Y, Z] = meshgrid(1:sDims(2), 1:sDims(1), 1:sDims(3));
ipCoords = [Y(:) X(:) Z(:) ones(size(X(:)))]';

% transform these inplane coordinates into scanner space
scannerCoords = scannerXform * ipCoords;

% grab the scanner Z-values of the scanner coords as the map values
map{1} = reshape(scannerCoords(3,:), sDims);

%% save the map
mapName = 'Scanner Z Coordinate';
vw = setParameterMap(vw, map, mapName);
saveParameterMap(vw);


%% create the ROI if an anchor point is provided
% parse the anochor point specification: allow it to be the center of the
% view's current ROI
if ~isempty(lineROIpoint)
	if isequal(lineROIpoint, -1)
		% center of cur ROI
		roi = vw.ROIs(vw.selectedROI);
		lineROIpoint = mean(roi.coords, 2);
	end
	
	if length(lineROIpoint) ~= 3 && numel(lineROIpoint) ~= 3
		error('Line ROI point requires a 3-element vector [row, slice, col].')
	end
	
	% transform this anchor point into the scanner space
	anchor = scannerXform * [lineROIpoint(:); 1];
	
	% find all points with the same X and Y value as the anchor point, but
	% a range of Z values which reflect the range spanned by the inplane
	% coordinates:
	zRange = mrvMinmax(scannerCoords(3,:));
	zRange = zRange(1):zRange(2);
	nPoints = length(zRange);
	[xx, yy, zz] = meshgrid(anchor(2), anchor(1), zRange);
	
	% xform the scanner (xx, yy, zz) points into inplane ROI coordinates
	roiCoords = inv(scannerXform) * [yy(:) xx(:) zz(:) ones(nPoints, 1)]';
	
	% create the ROI
	ROI = roiCreate1;
	ROI.name = sprintf('B0 vector %s', num2str(lineROIpoint));
	ROI.color = [1 1 .9];
	ROI.coords = round(roiCoords(1:3,:));
	ROI.comments = ['Created by ' mfilename '.'];
	
	vw = addROI(vw, ROI, 1);
end


vw = refreshScreen(vw);

return





