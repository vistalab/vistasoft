function [roiInd, coords] = roiIndices(view, coords, preserveCoords)
% [roiInd, dataCoords] = roiIndices(view, roiCoords, [preserveCoords=0]);
%
% figure out the indices in the map
% which correspond to the current ROI.
%
% Also returns the coords in terms of the view's
% data size, rather than the view size.
%
% Note that this doesn't remove redundant coordinates (which
% result because many anaomtical coordinate may specify the same
% functional coordinate) -- that's done in roiSubCoords.
%
% The preserveCoords flag determines whether or not roiInd will have the
% same number of voxels as the input roiCoords. This is particularly
% relevant to Volume/Gray views, where an ROI may specify regions of a
% volume anatomy outside the current session's data. If preserveCoords is
% set to 1, roiInd will have as many columns as roiCoords; voxels for which
% there is no data will have a NaN index. If 0 [default], will only return
% indices which are defined; this is faster, but will also sort the voxel
% order along the way.
%
% ras 10/04
% ras 03/07: added preserveCoords flag. Currently only affects Volume/gray
% views.
if notDefined('view'),	view = getCurView;		end

if notDefined('coords')
    coords = view.ROIs(view.selectedROI).coords;
end

if notDefined('preserveCoords'), preserveCoords = 0; end

% 10/2005 SOD: if coords is a cell structure, then
% we need to convert it to a matrix. This probably should not be done
% here but it works.
% (yeah, this indicates you're probably using getTseriesOneROI, which
% I'd hope could be replaced by voxelTSeries, which doesn't return cells
% -- I really hope the whole cell-of-coords thing goes away. The proper
% thing to do, which had been designed from the start, was to treat
% several ROIs as a cell-of-structs anyway. -ras, 11/2005.)
if iscell(coords),
    if length(coords) == 1,
        % straightforward conversion
        coords = coords{1};
    else
        % pick view.selectedROI
        coords = coords{view.selectedROI};
    end;
end;


switch viewGet(view, 'viewType')
    case 'Inplane'
        rsFactor = upSampleFactor(view, 1);
        coords(1,:) = ceil(coords(1,:) ./ rsFactor(1));
        coords(2,:) = ceil(coords(2,:) ./ rsFactor(2));
        roiInd = sub2ind(dataSize(view,1), coords(1,:),...
                    coords(2,:), coords(3,:));
                
    case {'Gray' 'Volume'}
        if size(coords,1) == 1
            % coords are indices and need to be converted to coordinates
            idx = coords;
            coords = view.coords(:, idx);
        end
		if preserveCoords==0
	        [coords, roiInd] = intersectCols(view.coords, coords);
		else
			% intersectCols sorts the voxel order; avoid this, although 
			% this will be substantially slower:
            if isequal(view.coords, coords)
                % then there is no need to search
                roiInd = 1:size(coords, 2);
                return
            else
                roiInd = NaN([1 size(coords, 2)]);
                for v = 1:size(coords, 2)
                    I = find( view.coords(1,:)==coords(1,v) & ...
                        view.coords(2,:)==coords(2,v) & ...
                        view.coords(3,:)==coords(3,v) );
                    if ~isempty(I)
                        roiInd(v) = I(1);
                    end
                end
            end
		end
        
    case 'Flat'
        roiInd = sub2ind( size(view.indices), coords(1,:),...
                          coords(2,:), coords(3,:) );
end

return
