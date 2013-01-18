function C = ndfunm(funtype, A, r)
%NDFUNM Matrix operations on N-D matrices
%   NDFUN treats an N-D matrix of double precision values as a set of pages
%   of 2D matrices, and performs various matrix operations on those pages.
%   It acts by performing an eigendecomposition of each page, applyting the
%   function to the eigenvalues and recomputing the matrix.
%   Available commands are:
%
%   C = NDFUNM('expm', A)
%   C = NDFUNM('logm', A)
%   C = NDFUNM('sqrtm', A)
%   C = NDFUNM('powerm', A, r)
%   C = NDFUNM('det', A)
%
%   The operations are equivalent to:
%       for i=1:N
%           C(:,:,i) = expm(A(:,:,i));
%       end
%
%   Any number of dimensions is supported, but operations are performed on
%   the first two dimensions.
%
%   See also:
%       ndfun, expm, logm, sqrtm, funm, det, ndsym2vec
%
%
%   HISTORY:
%       2004.01.22 ASH (armins@stanford.edu) wrote it
%       2008.01.31 ASH (armins$hsph.harvard.edu) added determinant option
%
%   NOTES:
%       Relies on NDFUN, which has a copyright by Peter Boettcher (2002)

sz = size(A);
ndim = length(sz);
if ((ndim > 1) & (sz(1) ~= sz(2))), disp('matrix is not square'), return, end
if (ndim > 2),
    A = reshape(A, [sz(1:2), prod(sz(3:end))]);
end
p = sz(1);

[V, D] = ndfun('eig', A);
D = ndsym2vec(D);

if strmatch(funtype,'det'),
    C = prod(D(1:p,:), 1);
    if (ndim > 2),
        C = reshape(C, [1 sz(3:end)]);
    end
else
    Dnew = zeros(size(D));
    switch funtype,
    case 'expm',
        Dnew(1:p,:) = exp(D(1:p,:));
    case 'logm',
        Dnew(1:p,:) = log(D(1:p,:));
    case 'sqrtm',
        Dnew(1:p,:) = sqrt(D(1:p,:));
    case 'powerm',
        Dnew(1:p,:) = D(1:p,:).^r;
    end
    Dnew = ndvec2sym(Dnew);
    C = ndmult(V, ndmult(Dnew, permute(conj(V), [2,1,3:ndim])));
    C = reshape(C, sz);
end

