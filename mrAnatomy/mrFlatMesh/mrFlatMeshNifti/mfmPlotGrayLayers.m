function mfmPlotGrayLayers(numGrayLayers,layerGlocs2d)
%
%
%
%
%

nFigsAcross=ceil(sqrt(numGrayLayers));
nFigsDown=ceil(sqrt(numGrayLayers));
for t=1:numGrayLayers
    if (t<=numGrayLayers)
        subplot(nFigsDown,nFigsAcross,t);

        plot(layerGlocs2d{t}(:,1),layerGlocs2d{t}(:,2),'.');
        axis equal;
    end % end check on current layer index
end % Next image

return;