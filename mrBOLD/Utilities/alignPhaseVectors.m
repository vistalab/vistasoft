function [a b] = alignPhaseVectors(a, b, rng);
% Circular shift one phase vector to optimally align to another phase
% vector.
%
% [a b] = alignPhaseVectors(a, b, <rng=[0 2*pi]>);
%
% PROBLEM: You have two vectors of phasic data -- e.g., the values wrap
% around a range such as [0, 2*pi], like polar angle measurements.
% Correlating these vectors may roduce bad correlations, because one or
% both vectors "wrap around", producing clusters of measurements at the
% max and min values.
%
% SOLUTION: use this to rotate one of the vectors (a) to optimally
% correlate to b. Note that you need to be careful; it has to be
% justifiable that the high correlation results from fixing the wrap-around
% problem. I developed this for comparing retinotopy measurements of polar
% angle across fMRI voxels, which I think fixes that problem. 
%
% Though this returns the vector b, it does not modify it.
%
% rng should be a 2-vector with the upper and lower bounds of the circular
% range. By default this is [0, 2*pi].
%
% ras, 11/2007.
if notDefined('rng'),		rng = [0 2*pi];			end

% all additions and subtractions should be modulo this number:
N = diff(rng);  

% mean shift to match a to b
delta = mean( mod([a-b], N) + rng(1) );

% adjust a
a = mod(a - delta, N) + rng(1);

return
