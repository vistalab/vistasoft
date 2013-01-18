function [grad, roiCoords, view] = checkSpatialGradMap(view, scan, roi, preserveCoords);
%
% [grad, roiCoords, view] = checkSpatialGradMap(view, [scan=1], [roi], [preserveCoords=0]);
%
% Get a spatial gradient map for detrending purposes, loading and/or
% computing in the view as needed. Returns a gradient matrix (size
% is dataSize(view)) for the selected scan.
%
% If an ROI is specified (see tc_roiStruct for the ways to specify), will
% also return a 3xN set of coordinates into the gradient map corresponding
% to the ROI, appropriate for the current view. The roiCoords are intended
% for use with er_preporcessTSeries.
%
% ras, 02/2007
if notDefined('view'),      view = getCurView;          end
if notDefined('scan'),      scan = view.curScan;        end
if notDefined('preserveCoords'), preserveCoords = 0;    end

grad = [];
roiCoords = [];

if ~isfield(view, 'spatialGrad') | isempty(view.spatialGrad)
    % load and/or compute
    mapPath = fullfile(dataDir(view), 'spatialGrad.mat');
    if ~exist(mapPath, 'file')  % offer to compute it
        q = ['The inomogeity correction flag is set to use the spatial ' ...
             'gradient map (inhomoCorrect=3). This map is not found. ' ...
             'Compute it now? '];
        resp = questdlg(q); 
        if ~isequal(resp, 'Yes')
            error('Aborted--no spatial gradient map.')
        end
        view = computeSpatialGradient(view);
    end
    
    view = loadSpatialGradient(view);
    
    % ensure the loaded spatial grad map propagates back
    % to the base workspace (global variable):
    updateGlobal(view);  
end

grad = view.spatialGrad{scan};

if exist('roi', 'var') & ~isempty(roi)
    % get map coordinates for the ROI
    roi = tc_roiStruct(view, roi);

    if preserveCoords==0
       subCoords = roiSubCoords(view, roi.coords);
    else
       subCoords = roi.coords;
    end
    [indices roiCoords] = roiIndices(view, subCoords, preserveCoords);
    
    % for volume/gray views, we want the indices and not coords
    % for the map (which is size 1 x nIndices). Mock up a 3xN
    % coords array, in which the columns reflec the indices into the map:
    if ismember(view.viewType, {'Volume' 'Gray'})
        roiCoords = ones(3, size(indices,2));
        roiCoords(2,:) = indices;
    end        
end

return
