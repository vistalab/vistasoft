function mask = findInternal(Y);
%
% mask = findInternal(Y);
%
% Given a data matrix Y, return a logical mask of the same size, with 1
% labeling internal points (points surrounded in the matrix grid by the
% same value) and 0 elsewhere.
%
% ras, 05/2006.
if nargin<1, help(mfilename); error('Not enough args.'); return
    
sz = size(Y);

% my approach is to treat the 1D, 2D, and 3D cases separately. In general, 
% I construct two difference vectors for each dimension. The (i,j)th value
% of each of these vectors represents the difference between Y(i,j) and its
% neighbor in a given direction. An internal element is defined as one for
% which the total difference in any given direction is zero.
switch ndims(Y)
    case 1, 
        % 1-dimensional case
        Y = Y(:)';
        right = [diff(Y) 1];
        left  = [1 fliplr(diff(fliplr(Y)))];
        mask = (left+right==0);
        mask = reshape(mask, sz);
        
    case 2,
        % 2-dimensional case
        up = [diff(Y, 1, 1); ones(1, sz(2))];
        down = [ones(1, sz(2)); flipup(diff(flipud(Y), 1, 2))];
        right = [diff(Y, 1, 1) ones(sz(1), 1)];
        left = [ones(sz(1), 1) fliplr(diff(fliplr(Y), 1, 2))];
        mask = (left+right+up+down==0);
        
    case 3, 
        % 3-dimensional case
        up = cat(1, diff(Y,1,1), ones(1,sz(2),sz(3)));
        
        tmp = flipdim(diff(flipdim(Y, 1),1,1), 1);
        down = cat(1, ones(1,sz(2),sz(3)), tmp);

        right = cat(2, diff(Y,1,2), ones(sz(1),1,sz(3)));
        
        tmp = flipdim(diff(flipdim(Y, 2),1,2), 2);
        left = cat(2, ones(sz(1),1,sz(3)), tmp);
        
        in = cat(3, diff(Y,1,3), ones(sz(1),sz(2),1));
        
        tmp = flipdim(diff(flipdim(Y, 3),1,3), 3);
        out = cat(3, ones(sz(1),sz(2),1)), tmp);
        
        mask = (left+right+up+down+in+out==0);
        
    otherwise, 
        error('findInternal only works on 1D, 2D, or 3D matrices.');
end

return
