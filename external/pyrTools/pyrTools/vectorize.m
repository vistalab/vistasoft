% [VEC] = vectorize(MTX)
% 
% Pack elements of MTX into a column vector.  Same as VEC = MTX(:)

function vec = vectorize(mtx)

vec = mtx(:);
