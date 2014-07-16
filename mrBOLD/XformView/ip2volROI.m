function volROI = ip2volROI(ipROI,ipView,volView)
% 
% volROI = ip2volROI(ipROI,ipView,volView)
%
% Creates a volume ROI from an inplane ROI by mapping
% coordinates, keeping track of partial voluming
%    
% ipROI and volROI are ROI structures, like those found in 
% view.ROIs 
%
% ipView must be the INPLANE structure.
% volView must be the VOLUME structure.
%
% djh, 8/98.
global mrSESSION
global vANATOMYPATH

% check that some more-recently-implemented fields are defined
% (ras, 02/2007)
ipROI = roiCheck(ipROI); 

% Get voxel sizes to make sure that the transformation preserves volume
ipVoxSize = viewGet(ipView, 'voxel size');
volVoxSize = readVolAnatHeader(vANATOMYPATH);

% Transform ROI coordinates
xform = mrSESSION.alignment;

coords = xformROIcoords(ipROI.coords, xform, ipVoxSize, volVoxSize);

if isempty(coords)
    % put a warning, but only if these aren't hidden views
    if ~isequal(viewGet(ipView,'Name'), 'hidden') && ~isequal(viewGet(volView,'Name'), 'hidden')
        msg = sprintf(['No voxels from %s map to the volume view. ' ...
                       'No ROI created.'], ipROI.name);
        myWarnDlg(msg);    
        volROI = [];
        return
    end
end

% Toss coords outside the volume
volSize = viewGet(volView,'Size');
indices = ((coords(1,:) >= 1) & (coords(1,:) <= volSize(1)) & ...
    (coords(2,:) >= 1) & (coords(2,:) <= volSize(2)) & ...
    (coords(3,:) >= 1) & (coords(3,:) <= volSize(3)));
coords = coords(:,indices);

% Set the other fields and sort
volROI = ipROI;
volROI.coords = coords;
volROI.viewType = volView.viewType;

return;

%%%%%%%%%%%%%%
% Debug/test %
%%%%%%%%%%%%%%

ipROI = INPLANE{1}.ROIs(INPLANE{1}.selectedROI);
volROI = ip2volROI(ipROI,INPLANE{1},VOLUME{1});
newipROI = vol2ipROI(volROI,VOLUME{1},INPLANE{1});
ipROI.coords
newipROI.coords
