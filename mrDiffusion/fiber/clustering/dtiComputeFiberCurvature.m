function [fibercurvature] = dtiComputeFiberCurvature(fg)
%
% [fibercurvature] = dtiComputeFiberCurvature(fg)
%
% Compute the curvature of individual fibers and make a cell-array output
% of curvatures in each node.
% 
% % INPUTS:
% fibers   = A fiber group.
%  
% % OUTPUTS:
% fibercurvature = A cell array of fiber curvarture. 
%
% This code is an updated version of dtiComputeFiberGroupCurvatures.m 
% 
% (C) Hiromasa Takemura, Stanford VISTA team, 2014

if notDefined('fg'), error('Fiber group required'); end

nfibers=size(fg.fibers, 1);

for i=1:nfibers
    
    numNodes(i) =size(fg.fibers{i}, 2);

    %Compute curvature representations
    fibercurvature{i}=dtiFiberCurvature(fg.fibers{i}); 
end