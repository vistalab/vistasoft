function [tSeries, coords, params] = rmLoadTSeries(view, params, whichData, preserveCoords, scans)
% rmLoadTSeries - Load Time Series associated with a retinotopy model and the specified data.
%
% [tSeries, coords, params] = rmLoadTSeries(view, [params], [whichData], [preserveCoords], [scans]);
%
% view: mrVista view. Defaults to current view.
%
% params: retinotopy model params. Defaults to view's loaded params.
%
% whichData: one of 'roi', 'fig', or 'all', or an ROI specification
%    (index into an ROI in the view, or 3xN coords).
%   If whichData is 'roi', will load data from the view's selected ROI;
%   if it's an ROI index / coords / struct, will use that ROI.
%
% preserveCoords: flag to indicate that the order of ROI coordinates should
% be preserved whenever possible. Can make loading substantially slower.
% [Default 0]
%
% ras, 12/2006.
% sod, 05/2007: removed allTimePoints from this function (see
% rmRecomputeParams).
if notDefined('view'),      view = getCurView;                      end
if notDefined('params'),    params = viewGet(view, 'rmParams');     end
if notDefined('whichData'), whichData = 'roi';                      end
if notDefined('preserveCoords'), preserveCoords = 0;                end
if notDefined('scans'),     scans = [];                             end

params.wData = whichData;

if isnumeric(whichData) || isstruct(whichData) % ROI index, coordinates, structure
    params.wData = 'roi';
    view.ROIs = tc_roiStruct(view, whichData);
	view.selectedROI = 1;
    [tSeries, params, coords] = rmLoadData(view, params, 1, [], preserveCoords, scans);
else
    [tSeries, params, coords] = rmLoadData(view, params, [], [], [], scans);    
end


% find the coordinates of the ROI in terms of the view's data
[coordsInd, coords] = roiIndices(view, coords, preserveCoords);
origCoords = coords;

%% ras 03/2009: I believe the statement below is just a duplication of ROI
%% indices (without support for preserving coordinates):
% switch lower(view.viewType),
%     case 'inplane'
%         rsFactor = upSampleFactor(view, 1);
%         if length(rsFactor)==1
%             coords(1:2,:) = round(coords(1:2,:)/rsFactor(1));
%         else
%             coords(1,:) = round(coords(1,:)/rsFactor(1));
%             coords(2,:) = round(coords(2,:)/rsFactor(2));
%         end;
%         coords = unique(coords', 'rows')';
% 
%     case {'volume' 'gray'}
% 		if preserveCoords==0
% 			% standard, fast way: intersect coords with the coordinates
% 			% available in the view
% 			allCoords    = viewGet(view, 'coords');
% 			[coords coordsInd] = intersectCols(allCoords, coords);
% 		else
% 			% slower, more methodical way
% 			
% 		end
%     otherwise
%         error('[%s]:unknown viewType %s', ...
%             mfilename, viewGet(view, 'viewType'));
% end;

if preserveCoords==0
	% restrict the time series to those valid coords
	% (This sorts the coords, but that's already done in the above code)
	[coords keepIndices] = intersectCols(origCoords, coords);
	tSeries = tSeries(:,keepIndices);
    
    % for inplane view, we need to reset the coords, because the call to
    % interserctCols reorders them. for volume/gray view, this happens in
    % the lines below in a call to rmSet
    params.roi.coords = coords;
else
	% there may be an error if the coordinates include points outside
	% origCoords...
end

if ismember(lower(view.viewType), {'volume' 'gray'})
	% we actually want the indices in this case
	params = rmSet(params, 'ROIcoords', view.coords(:,coordsInd));
	coords = coordsInd(:)';
end

if size(tSeries, 2) ~= size(coords, 2)
	% this shouldn't happen, but I'm not sure the above code guarantees it.
	error('Time series not matching coords!');
end



return;
