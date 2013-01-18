function fg = dtiCleanFibers(fg, clipPlanes, maxLen, minLen)
%
% fg = dtiCleanFibers(fg, clipPlanes, maxLen, minLen)
%
% removes fibers that cross the mid-sagittal plane more than once. Can also
% remove any fibers that penetrate the clip planes (a 1x3 set of L-R, A-P,
% S-I coordinates that define the 3 planes- set a coord to NaN to not clip
% in that plane).
%
%
% HISTORY:
%  2005.01.27 RFD wrote it.

if(~exist('clipPlanes','var') || isempty(clipPlanes))
    clipPlanes = [NaN NaN NaN];
end
if(~exist('maxLen','var') || isempty(maxLen))
    maxLen = NaN;
end
if(~exist('minLen','var') || isempty(minLen))
    minLen = NaN;
end

midSagThresh = 5;
n = length(fg.fibers);
keep = true(n,1);
nClip = 0;
for(ii=1:n)
    % remove fibers that cross the mid-sagittal plane more than once
    leftPoints = fg.fibers{ii}(1,:)<-midSagThresh;
    rightPoints = fg.fibers{ii}(1,:)>midSagThresh;
    midSagCross = -leftPoints+rightPoints;
    midSagCross = midSagCross(midSagCross~=0);
    if(sum(diff(midSagCross)~=0)>1)
        keep(ii) = false;
    end
    if(~isnan(maxLen) && length(fg.fibers{ii})>maxLen)
        keep(ii) = false;
    end
    if(~isnan(minLen) && length(fg.fibers{ii})<minLen)
        keep(ii) = false;
    end
    for(jj=1:3)
        if(~isnan(clipPlanes(jj)))
            if(any(fg.fibers{ii}(jj,:) < clipPlanes(jj)) && any(fg.fibers{ii}(jj,:) > clipPlanes(jj)))
                keep(ii) = false;
            end
        end
    end
    % remove aberrant points
    % find the distance between each fiber point and its neighbor
    dist = [0 diff(fg.fibers{ii}(1,:)).^2 + diff(fg.fibers{ii}(2,:)).^2 + diff(fg.fibers{ii}(3,:)).^2];
    % find neighbors that are too far apart
    tooFar = find(dist>median(dist)*3);
    if(~isempty(tooFar))
        % guess which segment to remove
        if(tooFar(1)>size(fg.fibers{ii},2)/2+1)
            fg.fibers{ii} = fg.fibers{ii}(:,1:tooFar(1)-1);
            nClip = nClip+1;
        elseif(tooFar(end)<size(fg.fibers{ii},2)/2-1)
            fg.fibers{ii} = fg.fibers{ii}(:,tooFar(end):end);
            nClip = nClip+1;
        else
            warning(sprintf('Fiber %d: Found aberrant fiber points, but coulnd decide which segment to remove.',ii));
        end
    end
end
disp(sprintf('%s: Keeping %d out of %d fibers.', mfilename, sum(keep), n));
if(nClip>0)
   disp(sprintf('%s: Clipped %d aberrant fiber segments.', mfilename, nClip)); 
end
fg.fibers = fg.fibers(keep);
if isfield(fg, 'subgroup')&&~isempty(fg.subgroup)
fg.subgroup=fg.subgroup(keep);
end
return;
