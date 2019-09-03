function nearpoints
%
% [indices, bestSqDist] = nearpoints(src, dest)
% 
% For each point in one set, find the nearest point in another.
%
%- src is a 3xM array of points
%- dest is a 3xN array of points
%- indices is a 1xM vector, in which each element tells which point
%  in dest is closest to the corresponding point in src.  For
%  example, dest[indices[i]] is near src[i].
%- bestSqDist is a 1xM array of the squared distance between
%  dest[indices[i]] and src[i].
%
% Compile the mex function with something like:
%   mex -O nearpoints.cxx
%
% HISTORY:
%  2004.05.01 Dan Merget wrote it.

disp('To compile, try:');
disp(['cd ' fileparts(which(mfilename)) '; mex -O ' mfilename '.c']);
error('This function must be compiled!');