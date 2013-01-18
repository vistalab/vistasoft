function volCoords = meshCursor2Volume(volView, msh)
%
%    volCoords = meshCursor2Volume(volView, [msh=viewGet(volView,'currentmesh')]);
%
%  Gets the current mrMesh cursor location and transforms it to mrVista
%  volume coordiantes.
%
% There are currently 3 ways to map the cursor to the VOLUME:
%
% 1. map the 3d cursor location directly to volume coords. This is the
% least accurate, since even smoothing the mesh will throw it off. If the
% mesh is not a real surface (eg. it's a cut plane or a DTI fiber), then
% this method will be used, since we have no other choice.
% 
% 2. get the vertex index of the cursor and then find the 3d location of
% that vertex in the volume space. This avoids the smoothing problem in
% method 1, but is not consistent with all other mapping code that uses the
% vertexToGray map. This method will only be used if the vertex-to-gray
% transform field of the msh struct doesn't exist or is empty.
%
% 3. get the vertex index of the cursor and use the vertex-to-gray
% transform associated with the mesh to map these to layer-1 gray nodes.
% Then, we can just take the 3d coordinates of those layer 1 nodes. This is
% the most accurate method and is consistent with all our other mapping
% code. This method will be used by default, if it can.
%
% HISTORY:
%  2006.06.01 RFD: wrote it.
%  2006.10.24 RAS: doesn't crash, but warns, if cursor is outside volume
%  range.
%  2008.12.16 RFD & DY: 
if(~exist('msh','var')||isempty(msh))
    msh = viewGet(volView,'currentmesh');
end

if(isfield(msh,'vertexGrayMap') && ~isempty(msh.vertexGrayMap))
    vertInd = mrmGet(msh,'cursorVertex');
    if vertInd < 1      % cursor not pointing to a volume vertex
        volCoords = [];
        warning('[%s]: Mesh Cursor is outside volume range.', mfilename); %#ok<*WNTAG>
        return
    end
    layerOneVolumeIndex = msh.vertexGrayMap(1,vertInd);
    
    % If the cursor position falls within the zone where functional data
    % was collected, translate this to a volume coordinate by grabbing the
    % position of the layer 1 node
    if(layerOneVolumeIndex>0 && layerOneVolumeIndex<=size(volView.coords,2) && ~isnan(layerOneVolumeIndex))
        volCoords = volView.coords(:,layerOneVolumeIndex)';
    % If not (and we have not computed layer 1 nodes for that position),
    % just get the cursor position at the gray/white boundary (which is
    % about 1mm off from where the layer 1 node position would be)
    else
        volCoords = round(msh.initVertices([2 1 3],vertInd)');
    end
else
    volCoords = round(mrmGet(msh,'cursor'));
end

return;