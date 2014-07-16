function [subCoords, ind] = roiSubCoords(vw,roiCoords)
%
% [subCoords, indices] = roiSubCoords(vw,roiCoords)
%
% Given a set of coords as they're specified in an
% inplane vw (i.e., in terms of the underlying inplane
% image or viewGet(vw,'Size')), return a set of coords, also
% relative to the viewSize, but subsampled, such that each
% functional voxel is only referenced by a single coordinate.
%
% If you don't do this, when you run things like voxelTSeries,
% you get multiple tSeries that are the same -- the coordinates point
% to different voxels in the anatomical, but since the functional is
% lower-res, they all point to the same functional voxel.
%
% Avoiding this is useful for across-voxel analyses.
%
% Note, however, that both the size and order of the coordinate
% specifications change as a result of this -- there are fewer
% coordinates, and they are reordered as if we were rastering
% across the volume (ascending indices).
%
% 05/04 ras.
% 07/07 ras: 2nd argument, ind, is now the same length as subCoords
% (subsampled).
if notDefined('roiCoords'), roiCoords = getCurROICoords(vw); end

switch vw.viewType
    case 'Inplane',
        % get the coords in terms of functional size
        [ind, subCoords] = roiIndices(vw, roiCoords);

        % preserve unique (distinct) coords
        [subCoords subInd] = intersectCols(subCoords, subCoords);
				
        % resample to anatomy coords:
        % (ras 09/08: see comments in getTSeriesROI)
        rsFactor = upSampleFactor(vw);
        subCoords(1,:) = subCoords(1,:) .* rsFactor(1);   % this is agnostic about whether
        subCoords(2,:) = subCoords(2,:) .* rsFactor(2); % upSampling is isometric in X+Y
		
        % let's arrange the columns of the subCoords by the third row (slices),
        % so that the order corresponds more closely to spatial location,  as if
        % we were scanning across rows, then columns, then paging through
        % slices:
        subCoords = sortrows(subCoords',3)';
		
		if nargout > 1
			% resample ind to match subCoords
			ind = ind(subInd);
		end
		
    case 'Flat',
        % the tSeries will only cover points
        % on the flat map mapped by the ROI,
        % ignoring ones on blank/masked nodes
        ind = sub2ind(size(vw.indices),roiCoords(1,:),...
            roiCoords(2,:),roiCoords(3,:));
        ind = find(vw.indices(ind)>0);
        subCoords = roiCoords(:,ind);
    otherwise,
        % keep all coords
        ind = 1:size(roiCoords, 2);
        subCoords = roiCoords;
end

return
