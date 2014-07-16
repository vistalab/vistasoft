function ipROI = vol2ipROI(volROI, volView, ipView)
% 
% ipROI = vol2ipROI(volROI, volView, ipView)
%
% Creates a inplane ROI from an volume ROI by mapping
% coordinates, keeping track of partial voluming
%    
% ipROI and volROI are ROI structures, like those found in 
% view.ROIs 
%
% volView must be the VOLUME structure.
% ipView must be the INPLANE structure.
%
% djh, 8/98.
% ras, 10/07 -- deals w/ empty ROIs.

global mrSESSION
global vANATOMYPATH

% check field assignments to make sure it's a current ROI
volROI = roiCheck(volROI);

% Get voxel sizes to make sure that the transformation preserves volume
ipVoxSize = viewGet(ipView, 'voxel size');
volVoxSize = readVolAnatHeader(vANATOMYPATH);

% initialize the inplane ROI
ipROI = volROI;
ipROI.coords = [];
ipROI.viewType = ipView.viewType;

% are there coords to xform? if not, return an empty ROI (warn if needed)
if isempty(volROI.coords)
	if prefsVerboseCheck==1
		fprintf('[%s]: empty ROI %s.\n', mfilename, ipROI.name);
	end
	return
end

% Transform ROI coordinates
xform = inv(mrSESSION.alignment);

coords = xformROIcoords(volROI.coords, xform, volVoxSize, ipVoxSize);

% Toss coords outside the inplanes
ipSize = viewGet(ipView,'Size');
indices = ((coords(1,:) >= 1) & (coords(1,:) <= ipSize(1)) & ...
    (coords(2,:) >= 1) & (coords(2,:) <= ipSize(2)) & ...
    (coords(3,:) >= 1) & (coords(3,:) <= ipSize(3)));
coords = coords(:,indices);

% Set the coordinates 
ipROI.coords = coords;

ipROI = sortFields(ipROI); % just to be safe

return;

%%%%%%%%%%%%%%
% Debug/test %
%%%%%%%%%%%%%%

volROI = VOLUME{1}.ROIs(VOLUME{1}.selectedROI);
ipROI = vol2ipROI(volROI,VOLUME{1},INPLANE{1});
newvolROI = ip2volROI(ipROI,INPLANE{1},VOLUME{1});
volROI.coords
newvolROI.coords
