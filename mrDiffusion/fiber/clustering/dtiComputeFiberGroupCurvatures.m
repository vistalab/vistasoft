function [fibercurvatures, curves]=dtiComputeFiberGroupCurvatures(fg)

%For fibers within a fibergroup fg computes their curvature values, returning an array of curvatures. Useful if
%feeding this function resampled fg and then computing correlations between
%these curves. 
%Works only  if all the fibers are the same length -- use
%dtiFiberCurvature for prosessing individual fibers otherwise

%ER 04/2008

nfibers=size(fg.fibers, 1);
numNodes=size(fg.fibers{1}, 2);
curves=zeros(3, numNodes, nfibers);

for i=1:nfibers
    %Compute curvature representations
    fibercurvatures(i, :)=dtiFiberCurvature(fg.fibers{i}); %fiber_curvature_vals=fiber_curvature(fiber);
    curves(:, :, i)=fg.fibers{i};
end
