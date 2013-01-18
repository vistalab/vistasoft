function newFGs = dtiSplitByFunctional(handles, grayView, fg, bins, whichLR, distThresh)
%
% newFGs = dtiSplitByFunctional(handles, grayView, [fg], [bins], [whichLR], [distThresh])
% 
% Splits the source fiber group (fg) into a new set of mutually
% exclusive fiber groups (newFGs) using the current data in grayView. Only
% the fiber endpoints are considered and the gray data are binned according
% to the 'bins' vector (eg. [0.0 0.25; 0.25 0.5; 0.5 0.75; 0.75 1.0] will create four bins at
% (0, 0.25], (0.25, 0.5], etc.). If not specified, the user will be
% prompted for the binning specifics.
%
% If fg is not specified, then the current fiber group will be used.
%
% The output fiber groups will be colored based on the current data
% colormap (using the bin centers).
%
% HISTORY:
% 2004.10.18 RFD (bob@white.stanford.edu) wrote it.

requireBothEnds = 0;
if(~exist('fg','var') | isempty(fg))
    fg = dtiGet(handles,'currentFG');
end
if(~exist('whichLR','var') | isempty(whichLR))
    whichLR = 'Both';
end
if(~exist('distThresh','var') | isempty(distThresh))
    distThresh = 4;
end
if(~exist('bins','var') | isempty(bins))
    nBins = 8;
    dataRange = grayView.ui.cbarRange;
    bins(:,1) = linspace(dataRange(1), dataRange(2)*((nBins-1)/nBins), nBins)';
    bins(:,2) = bins(:,1) + dataRange(2)*(1/nBins);
    bins(end,2) = bins(end,2)+dataRange(2)*0.01;
    answer = inputdlg({'Bins:','Which endpoint (Left, Right, Both):'}, 'Specify bins', 10, {num2str(bins), whichLR});
    if(isempty(answer))
        return;
    else
        bins = str2num(answer{1});
        whichLR = answer{2};
    end
end
binCenters = bins(:,1)+diff(bins')'/2;
whichLR = lower(whichLR(1));

% get the bin-center colors
cmap = viewGet(grayView, 'curCmap');
binColors = cmap(:,round((binCenters-min(bins(:,1)))/max(bins(:,2)-min(bins(:,1)))*size(cmap,2)));

% The following will tell us which grayCoords contain valid data. It takes into
% account all the data masking sliders.
dataMaskIndices = meshCODM(grayView);
grayData =  viewGet(grayView, 'curScanData');

distSqThresh = distThresh.^2;

coords = zeros(length(fg.fibers)*2, 3);
for(ii=1:length(fg.fibers))
    % We only look at fiber endpoints (first and last point)
    coords((ii-1)*2+1,:) = fg.fibers{ii}(:,1)';
    coords((ii-1)*2+2,:) = fg.fibers{ii}(:,end)';
end
if(whichLR~='b')
    % This logic is a bit tricky, but works. It generates an array which
    % tells us which of the two endpoints is leftmost.
    firstIsLeft = coords(1:2:end,1) < coords(2:2:end,1);
    leftMost = [firstIsLeft, ~firstIsLeft]';
    leftMost = leftMost(:);
    if(whichLR=='l')
        % keep only left endpoints
        disp('using leftmost endpoints...');
        coords(~leftMost,1) = 99999;
    else
        % keep only the right
        disp('using rightmost endpoints...');
        coords(leftMost,1) = 99999;
    end
end

coords = mrAnatXformCoords(inv(handles.xformVAnatToAcpc), coords);
[nearestGrayNode, bestSqDist] = nearpoints(coords', grayView.coords);
% Exclude those that are too far from a gray node
badInds = bestSqDist>distSqThresh;
% FIXME: we should restrict to layer 1.
%badInds(ismember(indices,find(grayView.nodes(6,:)~=1))) = 1;
% If requested, exclude those that don't have both endpoints of a fiber
if(requireBothEnds)
    notBoth = badInds(1:2:end)|badInds(2:2:end);
    badInds = repmat(notBoth,2,1);
    badInds = badInds(:)';
end

dataTypeName = viewGet(grayView, 'displayMode');
for(ii=1:size(bins,1))
    fgName = [fg.name '_' dataTypeName num2str(binCenters(ii),'%0.1f')];
    newFGs(ii) = dtiNewFiberGroup(fgName, binColors(:,ii)');
    curFiberInds = grayData(nearestGrayNode)>=bins(ii,1) & grayData(nearestGrayNode)<bins(ii,2) & ~badInds;
    % the following trick recovers the original fiber index. It works
    % because we extracted exactly two points from each fiber (the two
    % endpoints). We will include a fiber in the current bin if either of
    % its endpoints qualifies. There is a subtlety here- the bins are not
    % really mutually exclusive. The same fiber might fall into two bins,
    % one corresponding to each of its endpoints. We should consider
    % dealing with this case differently.
    newFGs(ii).fibers = fg.fibers(curFiberInds(1:2:end) | curFiberInds(2:2:end));
end

return;
