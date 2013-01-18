function [indices, bestSqDist] = nearpoints2d(src, dst)
%
% [indices, bestSqDist] = nearpoints2d(src, dest)
% 
% For each point in one set, find the nearest point in another.
%
%- src is a 2xM array of points
%- dest is a 2xN array of points
%- indices is a 1xM vector, in which each element tells which point
%  in dest is closest to the corresponding point in src.  For
%  example, dest[indices[i]] is near src[i].
%- bestSqDist is a 1xM array of the squared distance between
%  dest[indices[i]] and src[i].
%
% SEE ALSO: nearpoints
% 
% HISTORY:
%  2006.05.05 RFD wrote it.

if(size(src,1)~=2) src = src'; end
if(size(dst,1)~=2) dst = dst'; end

if(size(src,1)~=2 || size(dst,1)~=2)
    error('arrays must be 2xN and 2xM!');
end

src = [src; zeros(size(src(1,:)))];
dst = [dst; zeros(size(dst(1,:)))];
[indices, bestSqDist] = nearpoints(src, dst);
return;