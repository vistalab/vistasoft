function roivertinds = roiGetMeshVertexIndices(vw, roi, prefs)
% Return mesh indices for each voxel in a gray view ROI
%  roivertinds = roiGetMeshVertexIndices(vw, [roi], [mrmPrefs])
%
% Example:  roivertinds = roiGetMeshVertexIndices(vw);

%% Check Inputs
viewType = viewGet(vw, 'viewType');

% return with warning if not in gray / volume view
if ~ismember(lower(viewType), {'gray', 'volume'})
    warning('vista:viewError', 'Need gray or volume view to get ROI vertyex indices');
    roivertinds = []; return
end

% Parse varargin for ROIs and prefs
if notDefined('roi'),   roi     = vw.selectedROI; end
if notDefined('prefs'), prefs   = mrmPreferences; end

%% 

% get the mesh
msh  = viewGet(vw, 'currentmesh');
if isempty(msh), 
    warning('vista:viewError', 'need a mesh to get ROI vertex indices'); 
    roivertinds = [];
    return; 
end



% get ROI mapMode
if isequal(prefs.layerMapMode, 'layer1'), roiMapMode = 'layer1';
else roiMapMode = 'any';  end

% get the ROI
if isstruct(roi), thisROI = roi; else   thisROI = vw.ROIs(roi); end
try tmp = thisROI.roiVertInds.(msh.name).(roiMapMode); end %#ok<TRYNC>
if exist('tmp', 'var'), roivertinds = tmp; return; end

% get the gray indices
nodeInds = viewGet(vw, 'ROI Gray Indices', roi);

% get the nodes
vertexGrayMap   = meshGet(msh,'vertexGrayMap');

roivertinds     = findROIVertices([], nodeInds, vertexGrayMap);