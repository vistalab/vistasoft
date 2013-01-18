function distances = RoiToRoiDist(targetROI, sourceROI, view)
% RoiToRoiDist - find distance from each voxel in source ROI to nearest voxel in target ROI
%
%	distances = RoiToRoiDist(sourceROI, targetROI, view)
%
% Notes: This code is very slow. The bottleneck is the size of targetROI.
%   The original intention was that the target ROI be a line, such as an
%	isoeccentricity line. But any shape will work. The two ROIs must be
%	defined in the same view. The view can either be Flat or Gray. Once you
%	get the distances, you can plot data as a function of the distances
%	using plotParamVsDistToRoi.m
%
% Arguments:
%
%  sourceROI:   mrVista ROI struct or integer indexing a mrVista ROI struct  
%  targetROI:   mrVista ROI struct or integer indexing a mrVista ROI struct
%  view:        mrVista view struct 
%
% Outputs:
%  distances : a vector of distances of length sourceROI.coords 
%  
% Example: 
%	d = RoiToRoiDist(FLAT{1}.ROIs(1), 2);
%	gets the distance from ROI 2 in the current view to the nearest voxel
%	in FLAT{1}.ROIs(1)
%	
%	d = RoiToRoiDist(1);
%	gets the distance from the selcted ROI in the current view to the
%	nearest voxel in ROI 1 in the current view.
%
% HISTORY:
%     2008.02.23: JW adapted it from SOD's plotLineROI and AAB's
%     plotParamVsDistance. The purpose is to be able to plot data in an
%     ROI as a function of its distance on the mesh to a line, such as an
%     isoeccentricity line. Thus the target ROI will typically be a line,
%     but the function will work for any shape ROI.
%
%     2008/04/25: DY: When checking for corresponding nodes for target or
%     source ROIS, code now counts number of voxels (number of columns of
%     the ROI.coords) rather than just taking the length. This allows code
%     to appropriately handle ROIs with less than 3 voxels.  
%
%     2008/05/05: RFD/DY: When calculating distance, calculates distance
%     between nodes on layer 1 only (does this by setting X coord of nodes
%     on other layers to a large number). This avoids the problem of taking
%     shortcuts through nodes in other layers. Also, use nearpoints instead
%     of intersect function on line 97. 
%     

mrGlobals;
% Set up variables and ROIdata structure
if ieNotDefined('view'), view = getCurView; end
if ieNotDefined('targetROI') 
    if isempty(view.ROIs(1)), error ('Must have a target ROI defined'); 
    else targetROI = view.ROIs(1); end
end 
if ieNotDefined('sourceROI') 
    if isempty(view.ROIs(view.selectedROI)), error ('Must have a target ROI selected'); 
    else sourceROI = view.ROIs(view.selectedROI); end
end
if isnumeric(targetROI), targetROI = view.ROIs(targetROI); end
if isnumeric(sourceROI), sourceROI = view.ROIs(sourceROI); end
mmPerPix = readVolAnatHeader(vANATOMYPATH);

% Define the views. If necessary open a hidden volume view
switch(view.viewType)
    case 'Inplane'
        error([mfilename,' doesn''t work for ',view.viewType,'.']);
    case 'Flat'
        % Get a gray structure because we need the gray nodes.
        grayView = getSelectedGray;
        if ieNotDefined('grayView.nodes'), grayView = initHiddenGray; end
        % Old: Convert flat ROIs to Vol and get map data from Gray view        %           
        %       sourceROI = flat2volROI(sourceROI,view,grayView);
        %       targetROI = flat2volROI(targetROI,view,grayView);
        % New: leave ROIs in Flat view and call ROIBuildNodes below to get
        %   Gray nodes, and use the map data from the Flat view
    case 'Gray'
        grayView = view;
    otherwise
        error([view.viewType,' is unknown!']);
end

% Get all nodes and edges from VOLUME view
nodes   = double(grayView.nodes);
edges   = double(grayView.edges);

% Get nearest gray nodes
%   Get nearest gray nodes to all voxels in each of the two ROIs. 'nodes' is an
%   8xn array. The first 3 rows correspond to the y, x, and z coordinates of
%   the nodes.
switch view.viewType
    case 'Gray'
        remappedNodes = [nodes(2,:); nodes(1,:); nodes(3,:)];
        remappedNodes(1,nodes(6,:)~=1)=99999; % remap/exclude that is not a layer1 node -- guarantee that it's layer 1
        %use nearpoints to find nearest layer 1 node, ieven if not in ROI
        [sourceNodeIndices,dist]=nearpoints(double(sourceROI.coords),double(remappedNodes));
        [tmp numSourceVoxels] = size(sourceROI.coords);
        if length(sourceNodeIndices) ~= numSourceVoxels
            error('No gray node found for %d voxels in source ROI' , numSourceVoxels - length(sourceNodeIndices));
        end
        [lineNodeIndices,dist]=nearpoints(double(targetROI.coords),double(remappedNodes));
        %[tmp,lineNodeIndices,tmp] = intersect(remappedNodes', targetROI.coords', 'rows');
        [tmp numTargetVoxels] = size(targetROI.coords);        
        if length(lineNodeIndices) ~= numTargetVoxels
            error('No gray node found for %d voxels in target ROI' , numTargetVoxels - length(lineNodeIndices));
        end

    case 'Flat'
        %% Find gray nodes for each flat ROI coordinate
        sourceROI = ROIBuildNodes(sourceROI, view, grayView);
        targetROI = ROIBuildNodes(targetROI, view, grayView);
        sourceNodeIndices = sourceROI.nodeIndices;
        lineNodeIndices = targetROI.nodeIndices;
  
    otherwise
        error('This function does not work in %s view', view.viewType) 
end
    
% Get the distances
nodes(4,nodes(6,:)~=1)=0; % set neighbors for all non-layer-1 nodes to 0 (eliminate incorrect possible distance paths)

allDist = zeros(numel(sourceNodeIndices), numel(lineNodeIndices));
for n=1:numel(lineNodeIndices)
    tmp = mrManDist(nodes, edges, lineNodeIndices(n), mmPerPix, 100000, 0);
    allDist(:,n) = tmp(sourceNodeIndices);
end

% Find  shortest distance from each voxel in source ROI to target ROI     
distances = min(allDist, [], 2)';
