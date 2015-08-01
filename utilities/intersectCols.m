function [c,ia,ib] = intersectCols(a,b)
%
% function [c,ia,ib] = intersectCols(a,b)
%
% c is returned as the values of columns that match between matrices a and b.
%
% ia, ib are returned as a vector of indices for the columns where a match
% was found.
% 
% intersect builtin can only operate on rows, so intersectCols transposes
% input using intersect(a',b','rows') to find matching values.
%
% example:
% a = [1 2 3; 3 2 1; 1 2 3]
% b = [3 2 1; 1 2 1; 3 2 1]
% c = intersectCols(a,b) 
%
% See also UNIONCOLS, INTERSECT
%
% djh, 8/4/99

if verLessThan('matlab', '8.2'), 
    [cTrans,ia,ib] = intersect(a',b','rows');
else
    [cTrans,ia,ib] = intersect(a',b','rows', 'legacy');
end

c = cTrans';

return
