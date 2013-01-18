function ui = mrViewMeshFromSession(ui, msh);
%
% ui = mrViewMeshFromSession(ui, msh);
%
% Project overlay / ROI data from a mrViewer UI onto 
% a mrVista mesh, given that the mesh is loaded into 
% one of the mrVista VOLUME views.
%
% This is the original way I encoded it, but it's pretty
% locked into the notion that you have a session initialized
% in mrVista, and a VOLUME{}, struct, etc. The default way is now
% more general, relying on your having loaded a segmentation 
% into the ui.segmentation field. If no segmentation is loaded,
% but the VOLUME{1} field is assigned, mrViewMesh redirects the
% data here.
%
% ras, 10/2006.
mrGlobals2

%%%%% (1) setup: ensure all the necessary parts are there
% (a) check that we have the segmentation and a mesh loaded
sessionGUI_checkSegmentation;
if ~exist('msh','var') | isempty(msh), msh = mrViewMeshCheck; end

% (b) get the vertex to gray map, if it's not there
if isempty(msh.vertexGrayMap)   
    msh.vertexGrayMap = mrmMapVerticesToGray(msh.initVertices, VOLUME{1}.nodes, ...
                                             VOLUME{1}.mmPerVox, VOLUME{1}.edges);
end

% (c) get the coordinates, in the base MR anatomy, of the gray nodes stored
% in VOLUME{1} (this is where sessionGUI_loadSegmentation puts it):
if isequal(ui.mr.name, 'vAnatomy')
    % coords specified in this space
    grayCoords = VOLUME{1}.coords; 
    
elseif ismember('I|P|R', {ui.mr.spaces.name});
    % must map volume ('I|P|R') coords into the base anatomy space
    ii = cellfind({ui.mr.spaces.name}, 'I|P|R');
    vol2AnatXform = inv(ui.mr.spaces(ii).xform);
    grayCoords = coordsXform(vol2AnatXform, VOLUME{1}.coords')';
    
else
    error('Can''t project MR data into gray coordinates.')
    
end


%%%%% (2) loop across overlays, getting color overlay maps for each
if isfield(ui, 'overlays') & ~isempty(ui.overlays)
    overlays = [];
    hidden = [ui.overlays.hide]; % ignore overlays set to 'hidden'
    overlayList = find(~hidden);
    for o = overlayList
        map = ui.maps( ui.overlays(o).mapNum ); % map for this overlay

        %%%%% (a) get values of map at each mesh gray node
        if isequal(map.baseXform, eye(4))  
            mapCoords = grayCoords;
        else
            % must xform map coords into base MR coords
            mapCoords = coordsXform(inv(map.baseXform), grayCoords')'; 
        end
        nodeVals = mrGet(map, 'data', mapCoords);

        %%%%% (b) map the gray node data to the mesh vertices
        % infer phase flag from the data units, map name.
        if isequal(lower(map.dataUnits), 'radians') | isequal(lower(map.name), 'phase')
            phaseFlag = true;
        else
            phaseFlag = false;
        end
        vertexVals = meshMapData(msh, nodeVals, phaseFlag);

        %%%%% (c) threshold vertexVals according to the UI settings
        mask = logical(ones(size(vertexVals)));
        for j = find([ui.overlays(o).thresholds.on]==1) % for each active threshold
            th = ui.overlays(o).thresholds(j).mapNum;            

            % see if we can use the existing xformed coords,
            % or if the thresh map has to use diff't xformed coords
            if ui.overlays(o).mapNum==th  
                % thresholding by the overlay map
                testVals = vertexVals;

            elseif (map.baseXform==ui.maps(th).baseXform)
                % diff't map, same map coordinates
                threshNodeData = mrGet(ui.maps(th), 'data', mapCoords);
                testVals = meshMapData(msh, threshNodeData);

            else
                % diff't map, and also diff't map coordinates 
                threshCoords = coordsXform((ui.maps(th).baseXform), coords')'; 
                threshNodeData = mrGet(ui.maps(th), 'data', threshCoords);
                testVals = meshMapData(msh, threshNodeData);
            end

            % restrict ok voxels to min/max
            mask = mask & (testVals >= ui.overlays(o).thresholds(j).min);
            mask = mask & (testVals <= ui.overlays(o).thresholds(j).max);
        end

        %%%%% (d) convert values into mesh overlay colors
        cmap = ui.overlays(o).cbar.cmap; clim = ui.overlays(o).cbar.clim;
        if phaseFlag
            ovr = meshOverlay(msh, vertexVals, mask, cmap, clim, 'phaseData');
        else
            ovr = meshOverlay(msh, vertexVals, mask, cmap, clim);
        end
        overlays = cat(3, overlays, ovr);
    end
    
else
    overlayList = [];
    
end


%%%%% (3) composite multiple overlays, if needed
switch length(overlayList)
    case 0, colors = [meshCurvatureColors(msh)]'; % just the curvature...
    case 1, colors = overlays;    % just one overlay
    otherwise, colors = meshComposite(msh, overlays); % many overlays
end

%%%%% (4) draw ROIs 
switch ui.settings.roiViewMode
    case 1, rois = [];
    case 2, rois = ui.rois(ui.settings.roi);
    case 3, rois = ui.rois;
end
if ~isequal(ui.mr.name, 'vAnatomy') & ~isempty(rois)
   % convert into Volume (I|P|R) coords
   mrGlobals2;
   for ii = 1:length(rois)
       rois(ii).coords = coordsXform(inv(vol2AnatXform), rois(ii).coords)';
       rois(ii).coords = round(rois(ii).coords);
   end
end
[colors msh] = meshDrawROIs2(msh, rois, VOLUME{1}.nodes, colors);

%%%%% (5) update the data on the mesh
if msh.id < 0       % no mesh started
    msh = meshVisualize(msh);     
end
msh = mrmSet(msh, 'colors', colors);

% while we're at it, sync the mesh cursor display with the
% mrViwer cursor display:
if ui.settings.showCursor==1
    msh = mrmSet(msh, 'CursorOn');
    
    % update location to match viewer location
    pos = mrViewGet(ui, 'CursorPosition');
    if ismember('I|P|R', {ui.mr.spaces.name});
        ii = cellfind({ui.mr.spaces.name}, 'I|P|R');
        pos = coordsXform(ui.mr.spaces(ii).xform, pos');
    end
    
    vertex = mrmMapGrayToVertices(pos(:), msh.initVertices, msh.mmPerVox);
%     mrmSet(msh, 'CursorVertex', vertex);
else
    msh = mrmSet(msh, 'CursorOff');
end

VOLUME{1} = viewSet(VOLUME{1}, 'selectedMesh', msh);

return
% /-------------------------------------------------------------------/ %





% /-------------------------------------------------------------------/ %
function msh = mrViewMeshCheck;
% checks that a mesh is loaded for the current view; if not, offers to 
% load one. Returns the selected mesh.
mrGlobals2;

if isfield(VOLUME{1}, 'mesh') & ~isempty(VOLUME{1}.mesh)
    n = viewGet(VOLUME{1}, 'curMeshN');
    msh = VOLUME{1}.mesh{n};
else
    VOLUME{1} = meshLoad(VOLUME{1});
    msh = viewGet(VOLUME{1}, 'curMesh');
end

return