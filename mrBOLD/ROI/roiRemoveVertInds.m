function vw = roiRemoveVertInds(vw, roi)
% Clear the field 'roiVertInds' from all ROIs. The pupose of the field is
% to store the mesh vertex values needed to show the ROIs on the mesh. The
% advantage of storing them is that they don't need to be computed each
% time the mesh is updated with a new map. The reason why you might want to
% clear the field is (1) you don't want to save the values, (2) you change
% one or more ROIs (so that the vertex mapping also changes), (3) you
% prefer to caluclate stuff than to store stuff.
%
% vw = roiRemoveVertInds([vw], [roi])
%
% See roiSetVertInds.m 
%
% Example: vw = roiRemoveVertInds(vw, 1);
%
% 8/2009: JW

% check for the view struct
if ~exist('vw', 'var'),  vw = getCurView; end

% get the ROIs
ROIs = viewGet(vw, 'ROIs');

% if roiVertInds doesn't exist, nothing to do
if ~isfield(ROIs,'roiVertInds'), return; end

if notDefined('roi')
    % if no input arg for roi, assume all ROIs
    ROIs = rmfield(ROIs, 'roiVertInds');
else
    % otherwise clear the field for the requested ROIs
    if ~iscell(roi), roi = {roi}; end
    for ii = 1:length(roi)
        thisROI = ROIs(roi{ii});
        thisROI.roiVertInds = []; 
        ROIs(roi{ii}) = thisROI;
    end
end

% set the view with the cleaned ROI struct
vw = viewSet(vw, 'ROIs', ROIs);

% done
return