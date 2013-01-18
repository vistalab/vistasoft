function dtiSaveFiberClusters(clusterlabels, fibergroupsvector, FiberGroup, versionNum, coordinateSpace)
% Save fibergroups (clusters of fibers)
%  
%   dtiSaveFiberClusters(clusterlabels, fibergroupsvector, FiberGroup,versionNum, coordinateSpace)
%
%Save fibergroups (clusters of fibers) specified as a vector with cluster numbers -- in the
%cluster structure clusterlabels. FG is the original (clustered eventually) set of fibers.
%E.g., saveFiberClusters(clusterlabels, [4 93 87], fibergroup1, versionNum, coordinateSpace)
%
%To form fibergroupsvector use something like this:
% fibergroupsvector=[]
%for clust=1:max(clusterlabels)
% if size(find(clusterlabels==clust), 1)>10
% fibergroupsvector=[fibergroupsvector clust]
% end
% end

%ER 2007 SCSNL; edited 02/2008

%Figure out span for colors 
nfibergroups=length(fibergroupsvector);
%Form vectors of colors:
vecofcolor=int16(colormap(hsv(nfibergroups))*255);
iteration=0; %iterations;

for fibergroupIndex=fibergroupsvector

iteration=iteration+1;
fg.name=['Fibergroup' num2str(fibergroupIndex)];
fg.colorRgb=vecofcolor(iteration, :); 

fg.thickness=FiberGroup.thickness;
fg.visible=FiberGroup.visible;
if ~isempty(FiberGroup.seeds)
    fg.seeds=FiberGroup.seeds(clusterlabels==fibergroupIndex, :);
end
    fg.seedRadius=FiberGroup.seedRadius;
fg.seedVoxelOffsets=FiberGroup.seedVoxelOffsets;
fg.params=FiberGroup.params;

fg.fibers=FiberGroup.fibers(clusterlabels==fibergroupIndex);



filename=['Fibergroup' num2str(fibergroupIndex)];
save(filename, 'fg', 'coordinateSpace', 'versionNum');

end
