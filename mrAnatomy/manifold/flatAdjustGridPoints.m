function gridPoints = flatAdjustGridPoints(pos,D,gridPoints)
%
%   gridPoints = flatAdjustGridPoints(pos,D,gridPoints)
%
% Author: Wandell
% Purpose:
%    Using the connection matrix, D, and the positions in pos, adjust the
%    current gridPoints taking into account all of the data.
%    This follows the initial call to flatAddGridPoints, which builds up
%    the list.  In this case, we have a tentative first list, and we are
%    refining it so that every point is positioned with respect to every
%    other point.


if ieNotDefined('gridPoints'), error('Grid points required.'); end
if ieNotDefined('D'),          error('Connection matrix distances required.'); end
if ieNotDefined('pos'),        error('Positions required.'); end
if size(pos,1) ~= length(gridPoints)
    error('There should be as many positions as gridpoints.'); 
end

for ii=1:length(pos)
    
    [idx,err] = flatFindPointAtPosition([pos(ii,1),pos(ii,2)],gridPoints);
    
    gridPoints(ii).loc = [pos(ii,1),pos(ii,2)];
    gridPoints(ii).idx = idx;
    gridPoints(ii).dist = dijkstra(D,idx)';
    gridPoints(ii).err = err;
    
%     for jj=1:(ii+2), tmp(jj) = gridPoints(jj).idx; end
%     clf
%     plot(locs2d(tmp,1),locs2d(tmp,2),'.'); grid on;
%     set(gca,'xlim',[-15,15],'ylim',[-15,15]); axis equal
%     hold on;
%     set(gca,'xlim',[-mxDist, mxDist]*1.5);
%     plot(locs2d(tmp(end),1),locs2d(tmp(end),2),'ro'); 
%     title(sprintf('%.1f %.1f',pos(ii,1),pos(ii,2)));
%     hold off
%     pause;

end

return;