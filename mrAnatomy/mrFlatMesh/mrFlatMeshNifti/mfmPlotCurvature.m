function mfmPlotCurvature(gLocs2d,numNodes,mRange,layerCurvature)
%
%
%
%
%

[y x] = meshgrid(mRange);

warning off MATLAB:griddata:DuplicateDataPoints;
fl = griddata(gLocs2d(1:numNodes(1),1),gLocs2d(1:numNodes(1),2),layerCurvature{1},x,y);
warning on MATLAB:griddata:DuplicateDataPoints;

figure;
imagesc((rot90(fl))); colormap gray; title('Curvature map'); axis image

return;