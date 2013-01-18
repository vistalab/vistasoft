function [colors, msh, roiMask] = meshDrawROIs2(msh, rois, nodes, colors, update, edges);
% 'Draw' ROIs on a mesh as colors over different nodes, 
% returning the updated mesh colors. Version for mrVista2.
%
% colors = meshDrawROIs2(msh, rois, <oldColors=mesh curvature>, ...
%                          <perim=1>, <update=0>);
%
% INPUTS:
% msh: mesh structure on which to display ROIs.
%
% rois: struct array of ROI objects. NOTE: the .coords field of each ROI
% should be relative to the gray nodes (e.g., I|P|R space or
% VOLUME{1}.coords). 
%
% If you provide an ROI with the name 'mask', rather than rendering the
% ROI, it will be used as a mask to show only part of the data on the mesh.
%
% nodes: gray nodes matrix (as in VOLUME{1}.nodes). These can be obtained
% from mrGray .gray graphs (and readGrayGraph) or using mrgGrowGray.
% Apparently the latter fixes an old bug in mapping nodes.
%
% colors: existing mesh colors over which to superimpose the ROIs. If
% omitted, gets from mesh.
%
%
% update: flag to update the mesh colors with the new colors. Default is
% 0, don't update, just return colors.
%
% OUTPUTS:
%   colors: 4 x nVertices set of colors for the mesh, w/ ROI colors added.
%
%   msh: updated mesh structure, including any vertexGrayMaps and
%   connection matrices needed for the computation. 
%
%   roiMask: logical mask of size 1 x nVertices indicating where ROIs are.
%
% ras, 07/06.
if isempty(rois), return; end
if ~exist('colors','var') | isempty(colors), colors = meshGet(msh, 'colors'); end
if ~exist('update','var') | isempty(update), update = 0;                      end

% get the ROI mapping mode: may want to make this
% part of mrmPreferences, but maybe this is enough:
prefs = mrmPreferences;
if isequal(prefs.layerMapMode, 'layer1')
    roiMapMode = 'layer1';
else
    roiMapMode = 'any';
end

%%%%%params
nNodes = size(nodes, 2);
nVertices = size(msh.initVertices, 2);
v2g = msh.vertexGrayMap;
if isempty(v2g) 
    myErrorDlg('Need Vertex/Gray Map.');
elseif isequal(unique(v2g(:)), 0)
    myErrorDlg('Mesh doesn''t map to any data.');
elseif isequal(roiMapMode, 'any') & size(v2g, 1)==1
	% we only have the mapping to layer 1 -- we need the other layers
	try, vs = msh.mmPerVox; end   % voxel size
	if length(vs) < 3, vs = [1 1 1]; end    % back-compatibility
	msh.vertexGrayMap = mrmMapVerticesToGray(msh.initVertices, nodes, vs, edges);

end

% We need the connection matrix to compute clustering and smoothing, below.
conMat = meshGet(msh,'connectionmatrix');
if isempty(conMat)
    msh = meshSet(msh,'connectionmatrix',1);
    conMat = meshGet(msh,'connectionmatrix');
end

% initialize ROI mask if it's requested as an output:
if nargout>=3
    roiMask = logical(zeros(1, nVertices));
end

%%%%%%Main part:
% Substitute the ROI color for appropriate nearest neighbor vertices
for ii = 1:length(rois)
    
	%% find indices of those mesh vertices belonging to this ROI:
	roiVertInds = findROIVertices(rois(ii), nodes, v2g, roiMapMode);	
	
	
	%% adjust the set of ROI vertices to show perimeter / full ROI
	roiVertInds = adjustPerimeter(roiVertInds, msh, prefs, rois(ii).fillMode);
	
    % update the colors to reflect the ROIs
    if(strcmp(rois(ii).name,'mask'))
        % Don't show the ROI- just use it to mask the data.
        oldColors = mrmGet(msh, 'colors');
        tmp = logical(ones(size(dataMask)));
        tmp(roiVertInds) = 0;
        colors(1:3,tmp) = oldColors(1:3,tmp);
        clear tmp;
    else
        if (ischar(rois(ii).color))
            [stdColorValues, stdColorLabels]  = meshStandardColors;
            jj = findstr(stdColorLabels, rois(ii).color);
            colVal = stdColorValues(:,jj);
        else
            % Check to see if we have a 3x1 vector.
            colVal = rois(ii).color(:);
            if (length(colVal)~=3)
                error('Bad ROI color');
            end
        end
        colors(roiVertInds,1:3) = repmat(colVal'*255, [length(roiVertInds) 1]);

        % build ROI mask if requested
        if nargout>=3
            roiMask(roiVertInds) = true;
        end
    end
end

% round and clip
colors(colors>255) = 255;
colors(colors<0) = 0;
colors = round(colors);

return
% /--------------------------------------------------------------------/ %




% /--------------------------------------------------------------------/ %
function roiVertInds = findROIVertices(roi, nodes, v2g, roiMapMode);
% Returns a list of indices to each vertex belonging to the current ROI.

% find the nodes in the segmentation mapping to this ROI
[x nodeInds] = ismember(round(roi.coords'), nodes([2 1 3],:)', 'rows');
nodeInds = nodeInds(nodeInds>0);


switch lower(roiMapMode)
	case 'layer1'
		% The following will give us *a* vertex index for each gray node.
		% However, the same gray node may map to multiple vertices, and we
		% want them all. (Otherwise, the color overlay will have holes.) 
		% So, we loop until we've got them all.
		[nodesToMap roiVertInds] = ismember(nodeInds, v2g(1,:));
		roiVertInds = roiVertInds(roiVertInds>0);
		while(any(nodesToMap))
			v2g(1,roiVertInds) = 0;
			[nodesToMap I] = ismember(nodeInds, v2g(1,:));
			roiVertInds = [roiVertInds; I(I>0)];
		end

	case 'any'
		% if any of the nodes mapping to a given vertex are in the
		% ROI, include that vertex for drawing the ROI
		[I vertInds] = ismember(v2g, nodeInds);
		roiVertInds = find(sum(I)>0); % find columns w/ at least 1 member

	case 'data'
		% take ROI value from the same nodes as the data mapping,
		% rounding up (e.g., for 'mean' data mapping, will behave
		% like 'any'

	otherwise
		error('Invalid ROI Draw Mode preference.')
end



return
% /--------------------------------------------------------------------/ %




% /--------------------------------------------------------------------/ %
function roiVertInds = adjustPerimeter(roiVertInds, msh, prefs, fillMode);
% Sometimes we want to dilate the ROIs a bit. The following does this
% by finding all the neighboring vertices for all the ROI vertices (now
% stored in roiVertInds). The sparse connection matrix comes in handy
% once again, making this a very fast operation.

% We need the connection matrix 
conMat = meshGet(msh,'connectionmatrix');
if isempty(conMat)
    msh = meshSet(msh,'connectionmatrix',1);
    conMat = meshGet(msh,'connectionmatrix');
end

%% draw perimeter or fill in the ROI?
if isequal(fillMode, 'perimeter')
	% Draw a perimeter only
	origROI = roiVertInds;

	perimThickness = max(0, prefs.roiDilateIterations);

	if perimThickness > 0
		for t = 1:perimThickness
			neighbors = conMat(:,roiVertInds);
			[roiVertInds cols] = find([neighbors]);
			roiVertInds = unique(roiVertInds);
		end

		% Subtract the original from the dilated version.
		roiVertInds = setdiff(roiVertInds, origROI);

	else    % any way to make the perimeter thinner?
		neighbors = conMat(:,roiVertInds);
		[roiVertInds cols] = find([neighbors]);
		roiVertInds = setdiff(unique(roiVertInds), origROI);

	end

else
	% We can dilate the area if we are not also rendering the perimeter...
	for t = 1:prefs.roiDilateIterations
		neighbors = conMat(:,roiVertInds);
		[roiVertInds cols] = find([neighbors]);
		roiVertInds = unique(roiVertInds);
	end
end


return