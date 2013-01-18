function view = dtiXformFibersToMrVistaGray(handles, view, fgNum, separateRoiFlag)
%
% view = dtiXformFibersToMrVistaGray(handles, view, [fiberGroupNum], [separateRoiFlag])
%
% Uses the xformVAnatToAcpc (see dtiXformVanatCompute) to convert the specified
% fiber group to mrVista vAnatomy coords and sends them to the selected
% gray view. Note that only fiber end-points are sent, and they are
% projected to the nearest gray-matter coord.
%
% HISTORY:
% 2004.05.03 RFD (bob@white.stanford.edu) wrote it.

if(~exist('fgNum','var') | isempty(fgNum))
    fgNum = handles.curFiberGroup;
end
if(~exist('separateRoiFlag','var') | isempty(separateRoiFlag))
    separateRoiFlag = 0;
end

% This is in vAnatomy voxels. We should really scale by mmPerVox.
distThresh = 4;

fg = handles.fiberGroups(fgNum);
% if(~isempty(fg.seeds))
%     seeds = mrAnatXformCoords(inv(handles.xformVAnatToAcpc), fg.seeds);
%     seeds = unique(round(seeds),'rows')';
%     view = newROI(view, ['dti_' fg.name '_seeds'], 1);
%     view.ROIs(view.selectedROI).coords = seeds;
% end

% Select only layer 1 for the grayCoords.
grayCoords = view.coords(:,view.nodes(6,:)==1);

distSqThresh = distThresh.^2;
fibNum = 0;
allCoords = [];
requireBothEnds = 1;

if(separateRoiFlag)
    for(ii=1:length(fg.fibers))
        % We only look at fiber endpoints (first and last point)
        coords = fg.fibers{ii}(:,[1,end])';
	coords = mrAnatXformCoords(inv(handles.xformVAnatToAcpc), coords);
        [indices, bestSqDist] = nearpoints(coords', grayCoords);
        indices(bestSqDist>distSqThresh) = [];
        if(~isempty(indices))
            fibNum = fibNum+1;
            view = newROI(view, ['dti_' fg.name '_' num2str(fibNum,'%04d')], 1, [0 0 0]);
            view.ROIs(view.selectedROI).coords = grayCoords(:,indices);
        end
    end
else
    coords = zeros(length(fg.fibers)*2, 3);
    for(ii=1:length(fg.fibers))
        % We only look at fiber endpoints (first and last point)
        coords((ii-1)*2+1,:) = fg.fibers{ii}(:,1)';
        coords((ii-1)*2+2,:) = fg.fibers{ii}(:,end)';
    end
    coords = mrAnatXformCoords(inv(handles.xformVAnatToAcpc), coords);
    [indices, bestSqDist] = nearpoints(coords', grayCoords);
    tooFarInds = bestSqDist>distSqThresh;
    if(requireBothEnds)
        notBoth = tooFarInds(1:2:end)|tooFarInds(2:2:end);
        tooFarInds = repmat(notBoth,2,1);
        tooFarInds = tooFarInds(:)';
    end
    indices(tooFarInds) = [];
    if(~isempty(indices))
        coords = grayCoords(:,indices);
    end
    fibNum = length(indices);
    view = newROI(view, ['dti_' fg.name], 1, [0 0 0]);
    view.ROIs(view.selectedROI).coords = coords;
end
disp([num2str(fibNum) ' fibers had endpoints within ' num2str(sqrt(distSqThresh)) ' units of gray coords.']);
return;
