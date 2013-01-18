function vw = roiRestrictByLayer(vw, roiNum, layer)
%
% vw = roiRestrictByLayer(vw, [roiNum=selectedROI], [layer=1])
%
% Restricts ROI to nodes from one or more layers. Only for GRAY view
%
% Example: 
%   roiNum = viewGet(vw, 'selected ROI');
%   layer = 1;
%   vw = roiRestrictByLayer(vw, roiNum, layer);
 
% Check viewType
if ~strcmpi('gray', viewGet(vw, 'view type'))
    error('%s only works for gray views. The current viewType is %s.', ...
        upper(mfilename), upper(viewGet(vw, 'view type')));
end

% Check Inputs
if notDefined('roiNum'), roiNum = viewGet(vw, 'selected ROI'); end
if notDefined('layer'),  layer = 1; end

% Get indices to ROI voxels and to all Gray nodes
inds   = viewGet(vw, 'roigrayindices', roiNum);
nodes  = vw.nodes(:, inds);

% Row 6 of the nodes struct is the layer number. Check this row to find the
% subset of ROI coords that come from the requested gray layer.
newInds = nodes(6,:) == layer;
newInds = inds(newInds);

% Get current ROI coords
coords = viewGet(vw, 'ROI Coords', roiNum);

% Save prevSelpts for undo
vw.prevCoords = coords;

% Modify ROI.coords
coords = vw.coords(:, newInds);
vw = viewSet(vw, 'ROI coords', coords, roiNum);

vw = viewSet(vw, 'ROI modified', datestr(now), roiNum);

return