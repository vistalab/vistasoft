function mrVistaData = dtiXformGetMrVistaDataForFibers(handles, view, scanNum, fgNum)
%
% mrVistaData = dtiXformGetMrVistaDataForFibers(handles, [view], [scanNum], [fgNum])
%
% Uses the xformVAnatToAcpc (see dtiXformVanatCompute) to convert the specified
% fiber group to mrVista vAnatomy coords and pulls data from the selected
% gray view. Note that only fiber end-points are used, and they are
% projected to the nearest gray-matter coord.
%
% HISTORY:
% 2005.07.28 RFD (bob@white.stanford.edu) wrote it.

if(~exist('view','var') | isempty(view))
    view = getSelectedGray;
end
if(~exist('scanNum','var') | isempty(scanNum))
    scanNum = getCurScan(view);
end
if(~exist('fgNum','var') | isempty(fgNum))
    fgNum = handles.curFiberGroup;
end

% This is in vAnatomy voxels. We should probably scale by mmPerVox.
distThresh = 3;

fg = handles.fiberGroups(fgNum);

% Select only layer 1 for the grayCoords.
grayCoords = view.coords(:,view.nodes(6,:)==1);

distSqThresh = distThresh.^2;
fibNum = 0;
allCoords = [];
requireBothEnds = 1;

% We are only grabbing data for fiber endpoints, so we need num fibers * 2.
% We will apply a 4x4 xform, so we need homogeneous coords (nx4).
coords = zeros(length(fg.fibers)*2, 3);
for(ii=1:length(fg.fibers))
    % Get coords for fiber endpoints (first and last point)
    coords((ii-1)*2+1,:) = fg.fibers{ii}(:,1)';
    coords((ii-1)*2+2,:) = fg.fibers{ii}(:,end)';
end
coords = mrAnatXformCoords(inv(handles.xformVAnatToAcpc), coords);

% Now project endpoint coords to nearest gray matter coord
[indices, bestSqDist] = nearpoints(coords', grayCoords);
tooFarInds = bestSqDist>distSqThresh;
if(requireBothEnds)
    % Sometimes we want to delete fibers that have only one endpoint close
    % enough to the gray matter (eg. if we want to test connectivity).
    notBoth = tooFarInds(1:2:end)|tooFarInds(2:2:end);
    tooFarInds = repmat(notBoth,2,1);
    tooFarInds = tooFarInds(:)';
end
indices(tooFarInds) = [];

%mrVistaData.coords = grayCoords(:,indices);

mrVistaData.co = getCurDataROI(view,'co',scanNum,grayCoords(:,indices));
noData = isnan(mrVistaData.co);
mrVistaData.ph = getCurDataROI(view,'ph',scanNum,grayCoords(:,indices));
mrVistaData.amp = getCurDataROI(view,'amp',scanNum,grayCoords(:,indices));
mrVistaData.co(noData) = [];
mrVistaData.ph(noData) = [];
mrVistaData.amp(noData) = [];
if(~isempty(view.map) && ~isempty(view.map{scanNum}))
    mrVistaData.map = view.map{curScan}(indices);
    mrVistaData.map(noData) = [];
else
    mrVistaData.map = [];
end
mrVistaData.grayInds = indices(~noData);


fibNum = length(indices);

disp([num2str(fibNum) ' fibers had endpoints within ' num2str(sqrt(distSqThresh)) ' units of gray coords.']);
return;



