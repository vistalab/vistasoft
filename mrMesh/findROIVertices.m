function [roiVertInds, roiMapMode] = findROIVertices(roi, nodeInds, v2g)
% Returns a list of indices to each vertex belonging to the current ROI.
% [roiVertInds, roiMapMode] = findROIVertices(~, nodeInds, v2g)

% get ROI map mode 
prefs = mrmPreferences;
if isequal(prefs.layerMapMode, 'layer1')
    roiMapMode = 'layer1';
else
    roiMapMode = 'any';
end

switch lower(roiMapMode)
	case 'layer1'
		% The following will give us *a* vertex index for each gray node. However,
		% the same gray node may map to multiple vertices, and we want them
		% all. (Otherwise, the color overlay will have holes.) So, we loop
		% until we've got them all.
		[junk, roiVertInds] = ismember(nodeInds, v2g(1,:));
		roiVertInds = roiVertInds(roiVertInds>0);
		while(any(junk))
			v2g(1,roiVertInds) = 0;
			[junk,tmp] = ismember(nodeInds, v2g(1,:));
			roiVertInds = [roiVertInds; tmp(tmp>0)];
		end
		
	case 'any'
		% if any of the nodes mapping to a given vertex are in the
		% ROI, include that vertex for drawing the ROI
		I = ismember(v2g, nodeInds);
		roiVertInds = find(sum(I)>0); % find columns w/ at least 1 member

	case 'data'
		% take ROI value from the same nodes as the data mapping,
		% rounding up (e.g., for 'mean' data mapping, will behave
		% like 'any'

	otherwise
		error('Invalid ROI Draw Mode preference.')
end

return