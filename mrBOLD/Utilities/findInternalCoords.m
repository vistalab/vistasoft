function [internalCoords, I] = findInternalCoords(C, sz);
%
% [internalCoords, I] = findInternalCoords(coords, <sz>);
%
% For a 2xN or 3xN list of coordinates, return those columns specifying
% coords lying 'internally' in a 6-connected cartesian sense: coords whose
% neighbors above, below, left, right, in, out, are the same value. 
%
% sz: size of the putative matrix which the coords reference. <default:
% guess by bounds of coords>
%
% I: if requested, returns an index of those columns of coords which are
% internal.
%
% ras, 5/2006.

 % pad to 3xN if <3 dims specified
if (size(C, 1)<3),  C = [C; ones(3-size(C,1), size(C,2))];  end

if nargin<2, sz = abs(max(C,1,2) - min(C,1,2)); end

mask = logical(ones(sz));

ind = sub2ind(sz, C(1,:), C(2,:), C(3,:));
mask(ind) = 1;

inMask = findInternal(mask);

[ii jj kk] = find(inMask);
internalCoords = [ii; jj; kk];

if nargout>1   
    [ignore I] = intersectCols(C, internalCoords);
end

return
