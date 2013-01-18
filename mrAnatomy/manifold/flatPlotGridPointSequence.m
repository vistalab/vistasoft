function flatPlotGridPointSequence(gridPoints,pos,locs2d,mxDist)
%
%  flatPlotGridPointSequence(gridPoints,pos,locs2d,mxDist)
%
% Author: Wandell
% Purpose:
%    Show the sequence of flat positions in the grid points.
%

figure(100);

for ii=1:length(gridPoints)
    loc(ii,:) = gridPoints(ii).loc;
    idx(ii) = gridPoints(ii).idx;
    plot(locs2d(idx,1),locs2d(idx,2),'b.'); grid on;
    set(gca,'xlim',[-1.6,1.6]*mxDist,'ylim',[-1.6,1.6]*mxDist); 
    axis equal
    hold on;
    plot(locs2d(idx(end),1),locs2d(idx(end),2),'ro'); 
    title(sprintf('%.1f %.1f',pos(ii,1),pos(ii,2)));
    hold off
    pause(0.5);
end

return;