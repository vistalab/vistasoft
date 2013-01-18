function vw = meshROI2Volume(vw, mapMethod)
%
%    vw = meshROI2Volume(vw, [mapMethod=3]);
%
%  Gets the current mrMesh surface ROI and transforms it to the volume.
%
% There are currently 3 ways to map the ROI to the VOLUME:
%
% mapMethod = 1: map the vertex coords directly to volume coords.
%
% mapMethod = 2: use the vertex-to-gray transform associated with the mesh
% (which will map to the nearest layer-1 gray node).
%
% mapMethod = 3: same as 2, but we also grow from layer 1 to create an ROI
% that covers all the gray layers.
%
% I think most people will want method 3, so that's the default.
%
% Example:
%   vw = meshROI2Volume(vw);
%
% HISTORY:
%  2005.07.15 RFD: wrote it.

mrGlobals;

if notDefined('vw'), vw = getSelectedVolume; end

if(ieNotDefined('mapMethod')), mapMethod = 3; end
if(ieNotDefined('computeArea')), computeArea = true; end

msh = viewGet(vw,'currentmesh');
mrmRoi = mrmGet(msh,'curRoi');

if(~isfield(mrmRoi,'vertices')), error('No mrm ROI!'); end

roiName = '';
if(mapMethod==1)
    vert = meshGet(msh,'initialVertices');
    coords = vert([2 1 3],mrmRoi.vertices);
    for ii=1:3,
        coords(ii,:) = coords(ii,:)./msh.mmPerVox(ii); 
    end
    coords = round(coords);
else % mapMethod = 2 or 3
    verts    = adjustPerimeter(mrmRoi.vertices, [], vw)';
    grayInds = msh.vertexGrayMap(1,verts);
    %grayInds = msh.vertexGrayMap(1,mrmRoi.vertices);
    curLayer = unique(grayInds(grayInds>0));
    allLayers = curLayer;
    if(mapMethod==3)
        %sp = findConmatFromEdges(vw.nodes, vw.edges);
        nodes = viewGet(vw, 'nodes');
        edges = viewGet(vw, 'edges');

        % Start with the ROI vertices, which *should* be just layer 1 nodes.
        % (There is something fundamentally wrong about the logic here --
        % ras, 05/06)
        curLayerNum = 1;
        while(~isempty(curLayer))
            nextLayer = [];
            curLayerNum = curLayerNum+1;
            for ii=1:length(curLayer)
                offset = nodes(5,curLayer(ii));
                if offset>length(edges), continue; end
                numConnected = nodes(4,curLayer(ii));
                neighbors = edges(offset:offset+numConnected-1);
                nextLayer = [nextLayer, neighbors(nodes(6,neighbors)==curLayerNum)];
            end
            nextLayer = unique(nextLayer);
            allLayers = [allLayers, int32(nextLayer)];
            curLayer = nextLayer;
        end
    end
    coords = vw.coords(:,allLayers);
end

vw = newROI(vw,roiName,1,[],coords);
if checkfields(vw, 'ui', 'sliceNumFields')
    %vw = selectCurROISlice(vw);
end

if(computeArea)
    [areaList, smoothAreaList] = mrmComputeMeshArea(msh, mrmRoi.vertices);
    fprintf('ROI surface area: %0.1f mm^2 (%0.1f mm^2 on smoothed mesh)\n', sum(areaList), sum(smoothAreaList));
end

return
