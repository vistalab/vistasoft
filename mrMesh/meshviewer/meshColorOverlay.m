function [vw, dataMask, dataMaskIndices, newColors, msh, roiColors, dataOverlay] = meshColorOverlay(vw,showData,dataOverlayScale,dataThreshold)
% Compute and possibly show color overlays in the mrMesh Window.
%
%  [vw, dataMask,dataMaskIndices,newColors] = ...
%          meshColorOverlay(vw,showData,dataOverlayScale,dataThreshold);
%
% Compute and show color overlays (phase, co, etc) of the mesh in the
% current 3D view (3dWindow).
%
%  vw is a VOLUME{} structure containing the mesh
%  showData (default = 1) indicates whether to show the new colors into
%    the mrMesh window.
%  roiPerimThickness (mm)
%  dataOverlayScale
%  dataThreshold
%
%Example:
%  vw = VOLUME{1};
%  meshColorOverlay(vw);        % Just renders the mesh data
%
% Returns value (and renders).  Can be used to build up images.
%  [junk, dm, dmIndices, newColors] = meshColorOverlay(VOLUME{1},0);
%
% Author: Ress (June, 2003)
%
% 09/2005 SOD: change to handle datasets with NaNs
% 10/2005 SOD: put in switches to handle phase data
% 2007.08.23 RFD: fixed bug that was causing the connection matrix to be
% recomputed several times in here. Should be substantially faster now.
%
% 2010, Stanford VISTA

if notDefined('vw'), vw = getSelectedGray; end
if notDefined('showData'), showData = 1; end
if(~exist('dataOverlayScale', 'var') ||isempty(dataOverlayScale)), dataOverlayScale = 1; end
if(~exist('dataThreshold', 'var')), dataThreshold = []; end

msh = viewGet(vw,'currentmesh');

% NOTE: sometimes a view may be set to map, amp, co, or ph mode, but
% a parameter map or corAnal hasn't been loaded. (Esp. because of loading
% prefs). In this case, auto-set the view to anatomy mode, so these
% functions don't go looking for data that aren't there. (ras, 11/05)
switch vw.ui.displayMode
    case 'anat' % do nothing
    case 'map'
        if isempty(vw.map) || isempty(vw.map{viewGet(vw, 'curScan')})
            vw.ui.displayMode = 'anat';
        end
    case {'co', 'amp', 'ph'}
        if isempty(vw.co) || isempty(vw.co{viewGet(vw, 'curScan')})
            vw.ui.displayMode = 'anat';
        end
end

% Still experimenting with these settings.
prefs = mrmPreferences;
overlayModDepth = prefs.overlayModulationDepth;
dataSmoothIterations = prefs.dataSmoothIterations;

clusterThreshold = prefs.clusterThreshold;

% The vertex gray map can now be N x M, where N is the the number of data
% 'layers' that map to each of the M vertices.
vertexGrayMap = meshGet(msh,'vertexGrayMap');

if isempty(vertexGrayMap) || (strcmp(prefs.layerMapMode,'all'))
    mapToAllLayers = true;
    if size(vertexGrayMap,1)==1
        vertexGrayMap = mrmMapVerticesToGray(msh.initVertices, viewGet(vw,'nodes'), ...
            viewGet(vw,'mmPerVox'), viewGet(vw,'edges'));
        msh.vertexGrayMap = vertexGrayMap;
        vw = viewSet(vw,'currentmesh',msh);
        updateGlobal(vw);
    end
else
    mapToAllLayers = false;
end

% Initialize the new color overlay to middle-grey. This reduces
% edge artifacts when we smooth.
sz = size(meshGet(msh,'colors'),2);

% Center new colors around 127.  Don't forget alpha channel.  These are the
% vertices that are painted in the 3D view.
newColors = ones(4,sz) + 127;

% VertInds will be a logical map that tells us which vertices have at least
% one data layer that is not null. Some vertices (find(vertInds==0)) have
% no data associated with them. Note that this mask is different from the
% dataMask, which tells us which data values are below the thresholds that
% the user has set.
vertInds = (vertexGrayMap(1,:) > 0);
if(mapToAllLayers)
    for ii=2:size(vertexGrayMap,1)
        vertInds = vertInds | (vertexGrayMap(ii,:) > 0);
    end
end
vertInds = logical(vertInds);

% Create the Color Overlay and Data Mask.  The dataMaskIndices are the
% indices into the data (e.g., co{1}(dataMaskIndices) are the entries that
% have valid data values given the thresholds.  The color overlay describes
% the RGB values for ALL of the data, not just the valid points described
% in dataMaskIndices.
%[dataMaskIndices,colorOverlay] = meshCODM(vw);
% 09/2005 SOD: added a flag (phaseFlag) which indicates whether the
% data (data) is phase (circular) or not. This will have an impact
% on the kind of smoothing that is done later on.
[dataMaskIndices, data, cmap, dataRange, phaseFlag] = meshCODM(vw,clusterThreshold);

%%%%% Grab data for the overlay from the appropiate gray nodes %%%%%
% The new colors are assigned from the color overlay.  The color
% overlay was found from the VOLUME data.  The mapping from volume
% locations to vertex indices is managed by vertexGrayMap.  Each vertex is
% mapped to a gray node- except the vertices that have no nearest gray
% node- they are zeroed-out in vertexGrayMap and here are flagged by
% vertInds. Remeber- the indices to vertexGrayMap are in vertex space-
% each value in vertexGrayMap corresponds to an entry in
% mesh.vertices and specifies which gray matter node is closest to that
% vertex.
%
% ras 05/06 comment: the logic here is pretty painful. Why not consolidate
% the 2 prefs dealing with mapping into a single, expandable preference,
% and make this a switch statement? We start with possible mappings
% {'layer1', 'mean', 'max'} but should allow for other ones: 'layer2',
% 'min', 'max'. Also, needs to be more modular b/c it's clear other pieces
% of code aren't doing things consistently with this (see ROI drawing
% code), and it's very hard to figure out what goes wrong when things
% break.
if(mapToAllLayers && size(vertexGrayMap,1)>1 && ~isempty(data))

    % Initialize dataOverlay with the mean data value to avoid bias when
    % smoothing.
    %dataOverlay = zeros(size(vertexGrayMap(vertInds)));
    allV = vertexGrayMap > 0;

    % ignore non-finite data such as NaN's
    tmpdata = data(vertexGrayMap(allV(:)));
    dataOverlay = repmat(mean(tmpdata(isfinite(tmpdata))),1,sz);
    % dataOverlay = repmat(mean(data(vertexGrayMap(allV(:)))),1,sz);

    switch prefs.overlayLayerMapMode
        case 'mean'
            % take mean data across layers

            if ~phaseFlag
                n = sum(allV,1);
                for ii=1:size(vertexGrayMap,1)
                    % 03/2006 SOD: If we average over the vertexGrayMap layers we
                    % should start from layer 1 and not with the already existing
                    % dataOverlay. The existing dataOverlay is a mean of all data
                    % and will bias the layer-based average.
                    if ii==1
                        dataOverlay(allV(ii,:)) = data(vertexGrayMap(ii,allV(ii,:)));
                    else
                        dataOverlay(allV(ii,:)) = dataOverlay(allV(ii,:)) + data(vertexGrayMap(ii,allV(ii,:)));
                    end
                end
                dataOverlay(vertInds) = dataOverlay(vertInds)./n(vertInds);

            else % for phase data go complex average and go back
                % recompute complex dataOverlay, taking only finite data
                tmpdata = -exp(1i*data(vertexGrayMap(allV(:))));
                dataOverlay = repmat(mean(tmpdata(isfinite(tmpdata))),1,sz);
                %dataOverlay = repmat(mean(-exp(i*data(vertexGrayMap(allV(:))))),1,sz);
                n = sum(allV,1);
                for ii=1:size(vertexGrayMap,1)
                    if ii==1
                        dataOverlay(allV(ii,:)) = -exp(1i*data(vertexGrayMap(ii,allV(ii,:))));
                    else
                        dataOverlay(allV(ii,:)) = dataOverlay(allV(ii,:)) + -exp(1i*data(vertexGrayMap(ii,allV(ii,:))));
                    end
                end
                dataOverlay(vertInds) = angle(dataOverlay(vertInds)./n(vertInds))+pi;
            end

        case 'max'
            % take max value across layers
            curData = zeros(size(dataOverlay));
            for ii=1:size(vertexGrayMap,1)
                curData(:) = -9999;
                curData(allV(ii,:)) = data(vertexGrayMap(ii,allV(ii,:)));
                biggerInds = curData>dataOverlay;
                dataOverlay(biggerInds) = curData(biggerInds);
            end
        case 'min'
            % take min value across layers
            curData = zeros(size(dataOverlay));
            for ii=1:size(vertexGrayMap,1)
                curData(:) = 9999;
                curData(allV(ii,:)) = data(vertexGrayMap(ii,allV(ii,:)));
                smallerInds = curData<dataOverlay;
                dataOverlay(smallerInds) = curData(smallerInds);
            end
       case 'absval'
            % take maximum absolute value (positive and negative extremes) across layers
            curData = zeros(size(dataOverlay));
            signs = zeros(size(dataOverlay));
            for ii=1:size(vertexGrayMap,1)
                curData(:) = -9999;
                curData(allV(ii,:)) = abs(data(vertexGrayMap(ii,allV(ii,:))));
                signs(allV(ii,:)) = sign(data(vertexGrayMap(ii,allV(ii,:))));
                biggerInds = curData>dataOverlay;
                dataOverlay(biggerInds) = curData(biggerInds).*signs(biggerInds);
            end
    end
else
    % layer 1 mapping only
    dataOverlay = zeros(size(vertInds));
    if ~isempty(data)
        dataOverlay(vertInds) = data(vertexGrayMap(1,vertInds));
    end
end

% The dataMaskIndices are indices into the gray matter nodes. vertexGrayMap
% maps each vertex to some gray matter nodes and vertInds just tells us which
% entries in vertexGrayMap are non-zero (zero entries mean that vertex has
% no gray node close to it). So, we use ismember to create a new data mask
% that is in vertex space rather than node space. (ie. for each non-zero
% gray-node in vertexGrayMap, is it a memeber of dataMaskIndices?)
tmp = ismember(vertexGrayMap, dataMaskIndices);
dataMask = any(tmp,1);
dataMask(~vertInds) = 0;

if(~isempty(dataOverlayScale))
    dataOverlay = dataOverlay.*dataOverlayScale;
end
if(~isempty(dataThreshold))
    if(numel(dataThreshold)==1)
        dataMask = dataMask & dataOverlay>dataThreshold;
    else
        dataMask = dataMask & dataOverlay>dataThreshold(1) & dataOverlay<dataThreshold(2);
    end
end



% We need the connection matrix to compute clustering and smoothing, below.
conMat = meshGet(msh,'connectionmatrix');
if isempty(conMat)
    msh = meshSet(msh,'connectionmatrix',1);
    vw = viewSet(vw,'currentmesh',msh);
    conMat = meshGet(msh,'connectionmatrix');
end

%%%%%% SMOOTHING. %%%%%%
if(dataSmoothIterations>0)
    for t=1:dataSmoothIterations
        % Smooth and re-threshold the data mask
        dataMask = connectionBasedSmooth(conMat, double(dataMask));
        dataMask = dataMask>=0.5;
        % New: smooth the data, not the colors (RFD 2005.08.15)
        % 09/2005 SOD: smoothing the data can only be done if the
        % data is non-circular (ie not valid for phase maps). So
        % two ways depending on the data:
        if ~phaseFlag
            dataOverlay = connectionBasedSmooth(conMat,double(dataOverlay));
        else
            % phase data, so go complex, smooth and go back
            dataOverlay = -exp(1i*dataOverlay);
            dataOverlay = connectionBasedSmooth(conMat,double(dataOverlay));
            dataOverlay = angle(dataOverlay)+pi;
        end
    end
end

% compute newColors now after data smoothing
if ~isequal(vw.ui.displayMode, 'anat') && sum(data) ~= 0
    % 09/2005 SOD: remove NaNs from vertInds. This is otherwise done by
    % meshData2Colors, changing the size of the output colors, which
    % will consequently result in an error due to subscripted
    % assignment dimension mismatch.
    vertInds(isnan(dataOverlay))=0;
    newColors(1:3,vertInds) = meshData2Colors(dataOverlay(vertInds), cmap, dataRange);
end

% Assign the anatomy colors to the locations where there are no data
% values.
oldColors = meshGet(msh,'colors');

% ras, 08/2007: added a flag to allow you to set the transparency
% according to the 'co' field. This way, weaker activations appear fainter.
% This seems to work nicely in Freesurfer-generated figures from papers.
% (I put this before the ROI drawing, b/c we don't want to fade the ROIs.)
if prefs.coTransparency==1 && ~isequal(vw.ui.displayMode, 'co')
    co = viewGet(vw, 'scanco');  % coherence for this scan

    if ~isempty(co)
        % map the co values to each mesh vertex (need a mrVista2
        % function here)
        co = meshMapData(msh, co, 0, 'layer1');

        % convert the coherence levels to a scan weight: the cothresh should
        % be very transparent, but reasonably high co should be opaque.
        % Let's try getting this range from the clip mode of the coherence
        % display mode (i.e., vw.ui.coMode.clipMode.) Usually this is [0 1],
        % but you can set it to max out at a lower value (and won't need to
        % make the mrmPreferences specification more complex).
        if checkfields(vw, 'ui', 'coMode', 'clipMode')
            clim = vw.ui.coMode.clipMode ./ 2;
            if isempty(clim) || isequal(clim, 'auto')
                clim = [min(co(:)) max(co(:))];
            end
        else
            clim = [viewGet(vw, 'cothresh') max(co(:))/2];
        end

        % clip and rescale to [0, 1]
        co(co < clim(1)) = clim(1);
        co(co > clim(2)) = clim(2);
        w = normalize(co, 0, 1);

        %% manually alpha the underlay colors through the overlay

        % we don't want to modify new colors outside the data mask:
        w( ~dataMask ) = 1;

        % replicate w to affect the [R G B] values (but not the [alpha])
        % channel, which is not working, and which is why I need to
        % manually compute the alpha layering):
        w = [repmat(w(:)', [3 1]); ones(1, length(w))];

        % main alpha layering (don't worry about dataMask, taken care of
        % above)
        newColors = w .* newColors  +  (1-w) .* double(oldColors);
    end
end


%%%%% Modulate overlay colors to allow underlying curvature to show %%%%%
% This is useful when your mesh is completely painted, but
% you need some clue about the surface curvature (which is presumable what
% the original mesh colors represent). -Bob
if (overlayModDepth>0)
%     newColors(:,dataMask) = (1-overlayModDepth)*newColors(:,dataMask) ...
%         + overlayModDepth*double(oldColors(:,dataMask));
%     newColors(newColors>255) = 255;
%     newColors(newColors<0) = 0;

    newColors = (1-overlayModDepth)*newColors ...
        + overlayModDepth*double(oldColors);
    newColors(newColors>255) = 255;
    newColors(newColors<0) = 0;
end

%%%% Draw ROIs: now in separate function %%%%%
[newColors, roiVertInds, dataMask, vw, roiColors] = meshDrawROIs(vw, newColors, vertexGrayMap, [], dataMask, prefs);

% Apply the data mask
newColors(1:3,~dataMask) = oldColors(1:3,~dataMask);

% Place the new colors in the rendering
newColors = uint8(round(newColors));

% Sometimes we just want the values.  Usually, we want to show the data.
if showData
    msh = mrmSet(msh,'colors',newColors');
end

return;
