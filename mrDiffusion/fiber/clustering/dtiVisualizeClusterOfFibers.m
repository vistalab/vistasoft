function dtiVisualizeClusterOfFibers(clusterID, clusterlabels, fg)
%Display a group of fibers from fg.
%dtiVisualizeClusterOfFibers(clusterID, clusterlabels, fg)
%e.g., dtiVisualizeClusterOfFibers(1, fg.subgroup, fg)
%clusterlabels is a vector denoting, for each fiber, which cluster the
%fiber belongs to. 
%clusterID is which cluster we want to visualize. 
%ER 11/2007
if length(clusterlabels)~=1
    clusterlabels=clusterlabels'; 
end

figure; 
for fbindex = find(clusterlabels==clusterID)'
curve=fg.fibers{fbindex};

tubeplot(curve(1, :), curve(2, :), curve(3, :), 1); 
hold on; 
end
axis([ -80    80  -120    90   -60    90]); xlabel('L<->R'); ylabel('P<->A'); zlabel('I<->S'); grid on;  
