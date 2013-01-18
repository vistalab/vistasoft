function fiber_r=dtiFiberResample(fiber, value, flag)
%Resamples a fiber forcing a given number of nodes or a given step length.
%
% function fiber_r=dtiFiberResample(fiber, value, [flag = 'N'])
%
% Input: flag=='N'
%        Will resample the fiber to the number of points specified by
%        variable 'value' flag=='L' Will resample the fiber to the
%        intervals of length specified by variable 'value'
% Resampling is performed using interpolation with splines.
%
% Example:
%     fiber=fg.fibers{1}; fiber_r=dtiFiberResample(fiber, 10, 'N');
%     plot3(fiber_r(1,:),fiber_r(2,:),fiber_r(3,:),'bx-', ...
%     fiber(1,:),fiber(2,:),fiber(3,:),'ro--');
%     legend('Resampled', 'Original'); 
%
% See Also: dtiResampleFiberGroup
%
% (c) Vistalab

% HISTORY:
%  2007 ER wrote it 
%  2010 ER fixed a bug: resampling of a fiber with
%  seriously unevenly spaced out breakpoints will now return a fiber with
%  evenly spaced ones.

if ~exist('flag', 'var') || isempty(flag)
    flag='N';
end

fiberNoNan=fiber(~isnan(fiber(:, :)));
sizeI=3; sizeJ=size(fiberNoNan, 1)/3;
fiberNoNan=reshape(fiberNoNan, sizeI, sizeJ);

%This block deals with issues a) all NaNs b) oNly one point is not NaN c)
%npoints=1 TODO: revise this block
if(strcmp(flag, 'N') && value==1)||(sizeJ==0) || (sizeJ==1)
    %fiber_r=mean(fiberNoNan, 2);
    error('All NANs, only one point is not NAN, or npoints==1');
end

%Regularize the nodes: Renumerate the nodes by distance from 1st
node2nodedist = squareform(pdist(fiber'));
archcumdist = cumsum(diag(node2nodedist, 1));

F = spline([0 archcumdist'], fiberNoNan);

switch flag
    case 'N'
        % Trajectory
        stepP = archcumdist(end)/(value-1);
        
    case 'L'
        stepP = value;
    otherwise
        error('Flag should be either L or N');
end

t = 0:stepP:archcumdist(end);
fiber_r=ppval(F,t);
return