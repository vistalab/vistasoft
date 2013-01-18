function dtiVisualizeFiberClusters(fgfile, clusterlabels, fibergroupsvector)

%Quick visualization of several fibergroups from fibergroupsvector
%fgfile: file with original fibers; clusterlabels: vector of labels for the
%fibers from fgfile; fibergroupsvector: (vector) list of labels to be displayed. 

fg=dtiLoadFiberGroup(fgfile); 
%[fibercurvatures, curves]=dtiComputeFiberGroupCurvatures(dtiResampleFiberGroup(fg, 15));

fg=dtiResampleFiberGroup(fg, 15);
curves=zeros(3, 15,length(fg.fibers)); 
for fID=1:length(fibers)
curves(:,  :, fID)=fg.fibers{fID}; 
end



%figure; 
nfibergroups=length(fibergroupsvector);
vecofcolor=int16(colormap(hsv(nfibergroups)));
iteration=0; %iterations;

for fibergroupIndex=fibergroupsvector
    
hold on; iteration=iteration+1;
colorRgb=vecofcolor(iteration, :); 
plot3(permute(curves(1, :, clusterlabels== fibergroupIndex), [2 3 1]), permute(curves(2, :, clusterlabels== fibergroupIndex), [2 3 1]), permute(curves(3, :, clusterlabels== fibergroupIndex), [2 3 1]), 'Color', colorRgb);
end