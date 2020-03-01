function [fgOut,contentiousFibers, keep, keepID] = dtiIntersectFibersWithRoi(handles, options, minDist, roi, fg)
% New fiber group restricted to those that intersect with an ROI
%
% [fgOut,contentiousFibers, keep] = ...
%  dtiIntersectFibersWithRoi(handles, options,[minDist], [roi], [fg])
% 
% Creates a new fiber group that includes only fibers that pass through
% the specified ROI (AND) or only those that do not (NOT). 
% 
% Note that if you pass all the other required arguments, you can
% leave handles empty.
%
% NOTE! IF THE FIBERS ARE SPARSELY SAMPLED (ie. >1mm step size), THIS WILL
% NOT WORK WELL!
%
% If N rois are passed in, then:
%   * AND, NOT, SPLIT: the ROI coords are merged and treated as one big ROI
%   * DIVIDE: the fibers are divided between the N ROIs, producing N fiber
%   groups. Contentious fibers are marked by a 'contention' param.
%
%  * roi defaults to the current ROI
%  * minDist defaults to 0.87 mm (1mm cube center-to-corner distance).
%  * options: a cell array of strings with option flags:
%      'and': returns those fibers that intersect (the default).
%      'not': returns those fibers that do NOT intersect.
%      'split': returns 2 fiber groups (or N, if N rois are passed in) //'div': returns n fiber groups for N rois
%      'endpoints': only look at fiber endpoints
%      'both_endpoints': same as 'endpoints' however both, not any, endpoints have to satisfy
%
% NOTE! IF THE FIBERS ARE SPARSELY SAMPLED (ie. >1mm step size), THIS WILL NOT
% WORK WELL.
% The following algorithm is a (very efficient) hack. It simply finds those
% fibers who have a point within minDist of any ROI point. work well. In
% that case, you should do something like fit a spline through the fiber
% points and test to see if the spline intersects the ROI voxels.
%
% HISTORY:
% 2004.08.27 RFD: pulled code out of dtiFiberUI and modified the basic
% algorithm. I've made it more general purpose and we now use nearpoints to
% allow a user-specified 'tolerance'.
% 2005.09.26 RFD: removed the unecessary xform to raw image
% space. We now do everything in ac-pc space (as we should!).
% 2009.04.25 ER added the option 'both_points'
%
% The following code is confusing. This is due to the vectorization
% necessary for computational efficiency. 
%
% The output variables keep and keepID vectors for "not" option are
% counterintuitive: they mark fibers that DO intersect the ROI and that are
% exluded from the output FG. 
%
% (c) Stanford VISTA Team

if(~exist('fg','var') || isempty(fg))
    fg = handles.fiberGroups(handles.curFiberGroup);
end
if(~exist('roi','var') || isempty(roi))
    roi = handles.rois(handles.curRoi);
end
if(~exist('minDist','var') || isempty(minDist))
    minDist = 0.87; % cube center-to-corner distance (sqrt(3)/2)
end
if(exist('xform','var'))
    warning([mfilename ': xform is no longer needed or used! Please update your code.']);
end

if(~exist('options','var')) options = {}; end

doThis = 'a';
if(strmatch('not', lower(options))) doThis = 'n'; end
if(strmatch('split', lower(options))) doThis = 's'; end
if(strmatch('div', lower(options))) doThis = 'd'; end

if(~isempty(strmatch('endpoints', lower(options))) || ...
        ~isempty(strmatch('both_endpoints', lower(options)))), endptFlag = 1;
else endptFlag = 0; end

if(strmatch('both_endpoints', lower(options))), both_endptFlag = 1;
else both_endptFlag = 0; end

contentiousFibers = 0;

if(length(roi)>1 && doThis=='d')
    % If we are dividing up the fibers, then we need to keep track of eack
    % ROI's coords separately.
    roiCoords = cell(1,length(roi));
    for ii=1:length(roi)
        roiCoords{ii} = roi(ii).coords;
    end
else
    % If we are not dividing up the fibers, then we can glom all the ROI
    % coords into one big list.
    roiCoords{1} = vertcat(roi(:).coords);
end

if(doThis=='n' || doThis=='a')
    nOutFGs = 1;
else 
    % split and divide operators produce one fiber group for each ROI, plus
    % one (the 'leftovers').
    nOutFGs = length(roiCoords)+1;
end

for ii=1:nOutFGs
    fgOut(ii) = fg;
    fgOut(ii).visible = 1;
    fgOut(ii).seeds = [];
    fgOut(ii).fibers = {};
    if(doThis=='n')
        % invert the color for 'not'
        fgOut(ii).colorRgb = 255-fgOut(ii).colorRgb;
        fgOut(ii).name = [fg.name '-' [roi(:).name] ''];
    elseif(doThis=='a')
        fgOut(ii).name = [fg.name '+' [roi(:).name] ''];
    elseif((doThis=='s'||doThis=='d') && ii<=length(roiCoords))
        fgOut(ii).name = [fg.name '+' roi(ii).name ''];
        if(doThis=='d')
            rgb= roiToFiberColor(roi(ii).color);
            if(~isempty(rgb))
                fgOut(ii).colorRgb = rgb;
            end
        end
    elseif((doThis=='s'||doThis=='d') && ii>length(roiCoords))
        fgOut(ii).colorRgb = 255-fgOut(ii).colorRgb;
        fgOut(ii).name = [fg.name '-' [roi(:).name] ''];
    else
        error('Unknown state!');
    end
end

% The following concatenates all fiber coords into one big array so that we
% can avoid expensive loops when computing the intersection.
if(endptFlag)
    %use the same datatype used to store fg.fibers (if empty.. it doesn't really matter)
    type='single';
    if(~isempty(fg.fibers)) 
        type = class(fg.fibers{1});
    end
    fc = zeros(length(fg.fibers)*2, 3, type);

    for(ii=1:length(fg.fibers))
        fc((ii-1)*2+1,:) = [fg.fibers{ii}(:,1)'];
        fc((ii-1)*2+2,:) = [fg.fibers{ii}(:,end)'];
    end
else
    % This temporarily double the memory usage.. which often pushes it off
    % the limit..
    fc = horzcat(fg.fibers{:})';
end

if(~isempty(fc))
    bestSqDist = cell(length(roiCoords),1);
    keepAll    = cell(length(roiCoords),1);
    for (ii=1:length(roiCoords))
        [~, bestSqDist{ii}] = nearpoints(fc', roiCoords{ii}');
        keepAll{ii}         = bestSqDist{ii}<=minDist^2;
    end
else
    keep = [];
    return;
end

clear fc;
% All fibers in this group have had the intersection computed 
% efficiently in one big array. But now 
% we need to recover the information about which coord belongs to which 
% fiber. That's what this confusing bit of code does. Just remember that
% keepAll is a logical array indicating which fiber coords intersect the
% ROI. 
keep = true(length(fg.fibers),length(roiCoords));
keepID = zeros(length(fg.fibers),length(roiCoords), class(fg.fibers{1}));
dist = zeros(length(fg.fibers),length(roiCoords), class(fg.fibers{1}));
for(ii=1:length(roiCoords))
    fiberCoord = 1;
    if(endptFlag)
        for(jj=1:length(fg.fibers))
            if (both_endptFlag)
                keep(jj,ii) = all(keepAll{ii}(fiberCoord:fiberCoord+1));
            else
            keep(jj,ii) = any(keepAll{ii}(fiberCoord:fiberCoord+1));
            end
            if keep(jj,ii)
                keepID(jj,ii) = find(keepAll{ii}(fiberCoord:fiberCoord+1),1,'first');
            end
            dist(jj,ii) = min(bestSqDist{ii}(fiberCoord:fiberCoord+1));
            fiberCoord = fiberCoord+2;
        end
    else
        for(jj=1:length(fg.fibers))
            fiberLen = size(fg.fibers{jj},2);
            keep(jj,ii) = any(keepAll{ii}(fiberCoord:fiberCoord+fiberLen-1));
            if keep(jj,ii)
                keepID(jj,ii) = find(keepAll{ii}(fiberCoord:fiberCoord+fiberLen-1),1,'first');
            end
            dist(jj,ii) = min(bestSqDist{ii}(fiberCoord:fiberCoord+fiberLen-1));
            fiberCoord = fiberCoord+fiberLen;
        end
    end
    keepAll{ii} = [];
end

% For AND and NOT, there is always only one output FG.
if(doThis=='n')
    fgOut(1).fibers = fg.fibers(~keep(:,1));
    if isfield(fg,'subgroup')&& ~isempty(fg.subgroup)
        fgOut(1).subgroup=fgOut(1).subgroup(~keep);
        fgOut(1).subgroupNames=fg.subgroupNames;
    end
elseif(doThis=='a')
    fgOut(1).fibers = fg.fibers(keep(:,1));
    if isfield(fg, 'subgroup')&&~isempty(fg.subgroup)
        fgOut(1).subgroup=fgOut(1).subgroup(keep);
        fgOut(1).subgroupNames=fg.subgroupNames;
    end
elseif(doThis=='s')
    fgOut(1).fibers = fg.fibers(keep(:,1));
    fgOut(2).fibers = fg.fibers(~keep(:,1));
    if isfield(fg, 'subgroup')&&~isempty(fg.subgroup)
    fgOut(1).subgroup = fg.subgroup(keep);
    fgOut(2).subgroup = fg.subgroup(~keep);
    end
elseif(doThis=='d')
    % We divide up the fibers between the ROIs, assigning any
    % contentious fibers to the ROI that it is closest to.
    % NOTE: the code below defines 'closest' as that ROI with a point
    % that is closer to any fiber point than any other ROI. We might
    % consider using the ROI's center-of-mass, or some other slightly
    % more robust metric.
    
    % Sort each row so that the all the smallest dists end up in the
    % first column.
    [~,nearestInd] = sort(dist,2);
    assignToRoi = nearestInd(:,1);
    for(ii=1:length(roiCoords))
        fgOut(ii).fibers = fg.fibers(keep(:,ii)&(assignToRoi==ii));
    end
    % This will catch all the other fibers- those not assigned to any ROI.
    fgOut(end).fibers = fg.fibers(sum(keep,2)==0);
    contentiousFibers = sum(keep,2)>1;
end

return;

% ---
function rgb = roiToFiberColor(roiColor)
if(ischar(roiColor))
    switch(lower(roiColor(1)))
        case 'y', rgb = [200 200  20];
        case 'm', rgb = [200  20 200];
        case 'c', rgb = [ 20 200 200];
        case 'r', rgb = [200  20  20];
        case 'g', rgb = [ 20 200  20];
        case 'b', rgb = [ 20  20 200];
        case 'w', rgb = [200 200 200];  
        otherwise, rgb = [];
    end
elseif(isnumeric(roiColor) && length(roiColor)==3)
    if(any(roiColor>1)), rgb = roiColor;
    else rgb = round(roiColor*255); end
else
    warning('Can''t parse ROI color field.');
    rgb = [];
end

return;
