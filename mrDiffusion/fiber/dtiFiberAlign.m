function fg = dtiFiberAlign(fg, alignCoord, minDist, clipPts)
%
% fgAligned = dtiFiberAlign(fg, alignCoord, minDist, [clipPts=[]])
%
% Takes a fiber group (fg) and aligns all the fibers. This function
% only makes sense for fiber groups that are mostly comprised of a tight
% bundle of fibers. 
%
% alignCoord specifies the anatomical point to which all the fibers should
% be aligned. This must be a 1x3 with two NaNs and one value. The non-NaN
% value specifes the plane ([LR,AP,SI]) and the position in that plane (the
% actual value) to which all the fibers will be aligned. 
%
% The aligned fibers are then cleaned so that any fibers whos endpoints
% are less than minDist from the reference point are discarded. The ends
% are also clipped so that all remaining fibers will contain the same
% number of points (equal to minDist*2-1).
%
% If clipPts is not empty, then an additional cleaning step is applied where
% any fiber who's endpoints don't reach one of the two clipPts will be
% removed.
%
% HISTORY:
% 2007.02.02 RFD: wrote it, loosely based on code from
% dtiAnalyzeFiberTractProperties.

if(~exist('clipPts','var')) clipPts = []; end

ax = find(~isnan(alignCoord));
sl = alignCoord(ax);
if(length(ax)~=1) error('Specify just one alignment axis!'); end

nfg = length(fg.fibers);

% Remove fibers that are not part of the bundle
if(~isempty(clipPts))
    goodFibers = ones(1,nfg)==1;
    for(ii=1:nfg)
        endPt = [fg.fibers{ii}(ax,1) fg.fibers{ii}(ax,end)];
        goodFibers(ii) = min(endPt)<clipPts(1) & max(endPt)>clipPts(2);
    end
    fg.fibers = fg.fibers(goodFibers);
    nfg = length(fg.fibers);
end

% Align all the fibers
goodFibers = ones(1,nfg)==1;
for(ii=1:nfg)
    d = abs(fg.fibers{ii}(ax,:)-sl);
    nearInd = find(d==min(d));
    if(nearInd-minDist<=1 | nearInd+minDist>=length(fg.fibers{ii}))
        goodFibers(ii) = 0;
    else
        fDir = fg.fibers{ii}(ax,[nearInd-1,nearInd+1]);
        inds = [nearInd-minDist:nearInd+minDist];
        if(fDir(2)<fDir(1)) inds = fliplr(inds); end
        %goodInds = inds>1 & inds<length(d);
        fg.fibers{ii} = fg.fibers{ii}(:,inds);
    end
end
fg.fibers = fg.fibers(goodFibers);
return;

