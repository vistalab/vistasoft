function fgOut = dtiClipFiberGroupToROIs(fg,ROI1,ROI2, minDist)
%Clips input fiber groups to the two ROIs provided. 
%
% dtiClipFiberGroupToROIs(fg,roi1,roi2, mindist)
%
% Reorders fibers so that the first point intersects with ROI1 and last
% point intersects with ROI2.  Only the two endpoints will connect to the
% ROIs.  If there are multiple path segments that loop between the ROIs the
% segment closest to the start of the path will be chosen.
%
% TODO: Choose the shortest connecting segment between the ROIs.
%
% fg - Fiber group to be clipped.
% ROI* - Regions of Interest to clip fibers between
%
% HISTORY:
% 2008.04.08 Written by Anthony Sherbondy
%
% (c) Stanford Vista Team 2008

if ~exist('minDist', 'var')|| isempty(minDist), minDist=.87; end
    

[fgAnd1, foo, keep1, keep1ID] = dtiIntersectFibersWithRoi([], {'and'}, minDist, ROI1, fg);
[fgAnd2, foo, keep2, keep2ID] = dtiIntersectFibersWithRoi([], {'and'}, minDist, ROI2, fg);
intList = find(keep1&keep2);
fgOut = dtiNewFiberGroup;
fOutCount = 1;
for ii=1:length(intList)
    origI = intList(ii);
    curFiber = fg.fibers{origI};
    if keep1ID(origI) > keep2ID(origI)
         idvec = keep1ID(origI):-1:keep2ID(origI); %Nice! This is the way to reorient the fibers such that endpoints keep together, and start points together. 
    else
        idvec = keep1ID(origI):keep2ID(origI);
    end
    % Only store valid length paths
    if( length(idvec) > 1 )
        fgOut.fibers{fOutCount,1} = curFiber(:,idvec);
        fOutCount = fOutCount+1;
    end
end

% Check to see if this was empty
% if isempty(fgOut.fibers)
%     disp('WARNING! No fibers survived the clipping.');
% end

return;

%% Example Code
subjDir = 'C:\cygwin\home\sherbond\data\aab050307'; %#ok<UNRCH>
fg = dtiReadFibers(fullfile( subjDir,'fibers','conTrack','or_clean','LOR_meyer_final.mat'));
ROI1 = dtiReadRoi(fullfile(subjDir,'ROIs','llgn_tony.mat'));
ROI2 = dtiReadRoi(fullfile(subjDir,'ROIs','lv1.mat'));
fgOut = dtiClipFiberGroupToROIs(fg,ROI1,ROI2);

