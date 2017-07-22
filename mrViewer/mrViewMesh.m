function [ui msh] = mrViewMesh(ui, msh);
% Project the data currently being displayed on a mrViewer UI onto
% a VTK mesh which is loaded into the selected segmentation.
%
% [ui msh] = mrViewMesh(ui, <mesh struct or mesh num>);
%
% If omitted, the mesh is gotten by the call:
%	msh = mrViewGet(ui, 'mesh'); 
% This returns the selected mesh for the selected segmentation. To ensure
% the proper mesh is updated, check that the proper segmentation is
% selected. (E.g., Right and Left hemisphere gray matter are generally
% loaded as separate segmentations.)
%
% ras, 04/06.
if ~exist('ui','var') | isempty(ui), ui = mrViewGet; end
if ~exist('msh','var') | isempty(msh), msh = []; end
if ishandle(ui), ui = get(ui, 'UserData'); end

% the code below uses method (1), getting a mesh from an installed
% segmentation:
s = ui.settings.segmentation;           % segmentation #
m = ui.segmentation(s).settings.mesh;   % mesh #

%%%%% (1) setup: ensure all the necessary parts are there
%% (a) check that we have the segmentation and a mesh loaded
if isempty(msh), msh = mrViewGet(ui, 'mesh'); end

msg = sprintf('Projecting mrViewer data onto mesh %i', msh.id);
hwait = mrvWaitbar(0, msg);

%% (b) get the vertex to gray map, if it's not there
[nodes edges] = segGet(ui.segmentation(s), 'gray');
if isempty(msh.vertexGrayMap) || all(msh.vertexGrayMap(:)==0)
%     anatHeader = mrLoadHeader(ui.segmentation(s).anatFile);
%     vs = anatHeader.voxelSize(1:3); % voxel size
	try, vs = msh.mmPerVox; end   % voxel size
	if length(vs) < 3, vs = [1 1 1]; end    % back-compatibility
    msh.vertexGrayMap = mrmMapVerticesToGray(msh.initVertices, nodes, vs, edges);    
end

%% (c) get the coordinates, in the base MR anatomy, of the gray nodes
s = ui.settings.segmentation;
grayCoords = segGet(ui.segmentation(s), 'GrayCoords');

% the grayCoords we grabbed above are specified in the segmentation's
% antomy. This may not be the current anatomy we're viewing. 
% Check if it's different, and if so, make an educated guess how to
% xform it to the current anatomy's pixel space.
% (TO DO: figure a way to keep track of the relationship between
%  the ui.mr anatomy and the segmented anatomy, probably in ui.mr.spaces.)
if ~isequal( fullpath(ui.mr.path), fullpath(ui.segmentation(s).anatFile) )
    % we'll assume that if the 'I|P|R' space is defined, this contains
    % the proper alignment into the segmented anatomy. (mrGray uses
    % the I|P|R conventions, as does the mrVista VOLUME, so this isn't a 
    % bad guess.)
    ipr = cellfind({ui.mr.spaces.name}, 'I|P|R');
    
    if isempty(ipr)
        myErrorDlg(['The current anatomy doesn'' match the segmented ' ...
                    'anatomy, and an alignment to the proper coordinates ' ...
                    '(I|P|R space) can''t be found. ']);
    end
    
    grayCoords = coordsXform( inv(ui.mr.spaces(ipr).xform), grayCoords' )';
end
        
mrvWaitbar(.2, hwait);


%%%%% (2) loop across overlays, getting color overlay maps for each
if isfield(ui, 'overlays') & ~isempty(ui.overlays)
    overlays = [];
    hidden = [ui.overlays.hide]; % ignore overlays set to 'hidden'
    overlayList = find(~hidden);
    for o = overlayList
        map = ui.maps( ui.overlays(o).mapNum ); % map for this overlay

        %%%%% (a) get values of map at each gray node
        if isequal(map.baseXform, eye(4))  
            mapCoords = grayCoords;
        else
            % must xform map coords into base MR coords
            mapCoords = coordsXform(inv(map.baseXform), grayCoords')'; 
        end
        
        if ndims(map.data) > 3, 
            subVol = ui.overlays(o).subVol;
            mapCoords = [mapCoords; repmat(subVol, 1, size(mapCoords, 2))];
        end
        
        nodeVals = mrGet(map, 'data', mapCoords);

        %%%%% (b) map the gray node data to the mesh vertices
		if map.phaseFlag==1
			% we need to map from the data range to [0, 2*pi] 
			% for meshMapData to work
			nodeVals = rescale2(nodeVals, map.dataRange, [0 2*pi], 0);
		end
		
        vertexVals = meshMapData(msh, nodeVals, map.phaseFlag);
		
		if map.phaseFlag==1
			% map back to data units
			vertexVals = rescale2(vertexVals, [0 2*pi],  map.dataRange, 0);
		end		
		
        %%%%% (c) threshold vertexVals according to the UI settings
        mask = logical(ones(size(vertexVals)));
        for j = find([ui.overlays(o).thresholds.on]==1) % for each active threshold
            th = ui.overlays(o).thresholds(j).mapNum;            

            % see if we can use the existing xformed coords,
            % or if the thresh map has to use diff't xformed coords
            if ui.overlays(o).mapNum==th  
                % thresholding by the overlay map
                testVals = vertexVals;

            elseif all(map.baseXform==ui.maps(th).baseXform)
                % diff't map, same map coordinates
                threshNodeData = mrGet(ui.maps(th), 'data', mapCoords);
                testVals = meshMapData(msh, threshNodeData);

            else
                % diff't map, and also diff't map coordinates 
                threshCoords = coordsXform(inv(ui.maps(th).baseXform), mapCoords')'; 
                threshNodeData = mrGet(ui.maps(th), 'data', threshCoords);
                testVals = meshMapData(msh, threshNodeData);
            end

            % restrict ok voxels to min/max
            mask = mask & (testVals >= ui.overlays(o).thresholds(j).min);
            mask = mask & (testVals <= ui.overlays(o).thresholds(j).max);
        end

        %%%%% (d) convert values into mesh overlay colors
        cmap = ui.overlays(o).cbar.cmap; clim = ui.overlays(o).cbar.clim;
        if map.phaseFlag==1
            ovr = meshOverlay(msh, vertexVals, mask, cmap, clim, 'phaseData');
        else
            ovr = meshOverlay(msh, vertexVals, mask, cmap, clim);
		end
		
		% add this overlay (ovr) to the set of all overlays
        overlays = cat(3, overlays, ovr);
    end
    
else
    overlayList = [];
    
end

mrvWaitbar(.5, hwait);


%%%%% (3) composite multiple overlays, if needed
switch length(overlayList)
    case 0, colors = [meshCurvatureColors(msh)]'; % just the curvature...
    case 1, colors = overlays;    % just one overlay
    otherwise, colors = meshComposite(msh, overlays); % many overlays
end

mrvWaitbar(.6, hwait);


%%%%% (4) draw ROIs 
switch ui.settings.roiViewMode
    case 1, rois = [];
    case 2, rois = ui.rois(ui.settings.roi);
    case 3, rois = ui.rois;
end

if ~isequal( fullpath(ui.mr.path), fullpath(ui.segmentation(s).anatFile) ) & ...
		~isempty(rois)
    % we assume that the 'I|P|R' space is defined, as in (1c) above.    
    xform = ui.mr.spaces(ipr).xform;
	rois = roiXformCoords(rois, ui.mr.spaces(ipr).xform, msh.mmPerVox);
	
	% HACK 02/2009: 
	% For the case of ROIs loaded off the volume anatomy, it makes more
	% sense to use the originally-defined ROI coordinates (stored in
	% roi.definedCoords) to project to the mesh, compared to the xformed
	% coords. The xformed coords may have already been downsampled to
	% another anatomy (e.g., the inplane), while the definedCoords should
	% not need this modification:
	for ii = cellfind( {rois.definedCoords} ) % find ROIs w/ nonempty definedCoords
		[p1 f1 ext1] = fileparts(ui.segmentation(s).anatFile);
		[p2 f2 ext2] = fileparts(rois(ii).referenceMR);
		if isequal(f1, f2) & isequal(ext1, ext2)
			rois(ii).coords = rois(ii).definedCoords;
		end
	end
end

[colors msh] = meshDrawROIs2(msh, rois, nodes, colors, 0, edges);

mrvWaitbar(.8, hwait);


%%%%% (5) update the data on the mesh
if msh.id < 0       % no mesh started
    msh = meshVisualize(msh);     
end
msh = mrmSet(msh, 'colors', colors);

mrvWaitbar(1, hwait);


% % while we're at it, sync the mesh cursor display with the
% % mrViwer cursor display:
% if ui.settings.showCursor==1
%     msh = mrmSet(msh, 'CursorOn');
%     
%     % update location to match viewer location
% %     pos = mrViewGet(ui, 'CursorPosition');
% %     if ismember('I|P|R', {ui.mr.spaces.name});
% %         ii = cellfind({ui.mr.spaces.name}, 'I|P|R');
% %         pos = coordsXform(ui.mr.spaces(ii).xform, pos');
% %     end
%     
% %     vertex = mrmMapGrayToVertices(pos(:), msh.initVertices, msh.mmPerVox);
% %     mrmSet(msh, 'CursorVertex', vertex);
% else
%     msh = mrmSet(msh, 'CursorOff');
% end

ui = mrViewSet(ui, 'mesh', msh);

close(hwait);

return

