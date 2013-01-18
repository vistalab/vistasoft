function Xvec = ndsym2vec(Xsym, dim)

% Xvec = ndsym2vec(Xsym, [DIM])
% 
% Converts the dimensions DIM and DIM+1 from a symmetric matrix
% to a vector.
% The rest of the coordinates are untouched but shifted accordingly.
% The elements of the matrix are taken diagonal first and then
% off diagonals by rows and columns.
% The number of elements size(Xvec, DIM) is equal to p*(p+1)/2,
% where the symmetric matrix is p by p.
% If DIM is unspecified, it defaults to DIM = 1.
% If Xsym is square but not symmetric, then the input is changed to the symmetric part (Xsym+Xsym')/2.
%
% Example:
%   dt6 = ndsym2vec(dt33, 4);
%
% If size(dt33) = [nx ny nz 3 3 N] then size(dt6) = [nx ny nz 6 N]
% where, if each 3x3 matrix has the format
%   [[X1 X4 X5]
%    [X4 X2 X6]
%    [X5 X6 X3]]
% then each 6-vector has the format [X1 X2 X3 X4 X5 X6],
% 
% See also:
%   ndvec2sym
%
% HISTORY:
%   2004.02.13 ASH (armins@stanford.edu) wrote it.
%

if ~exist('dim'),
    dim = 1;
end
sz = size(Xsym);
ndim = length(sz);
if (dim > ndim-1),
    disp('dim exceeds number of dimensions')
    return
end
if ((ndim > dim) & (sz(dim) ~= sz(dim+1))), disp('matrix is not square'), return, end
p = sz(dim);   % size of symmetric matrix
k = p*(p+1)/2;

dims = setdiff([1:ndim], [dim, dim+1]);
Xsym = permute(Xsym, [dim, dim+1, dims]);
Xvec = zeros([k, 1, sz(dims)]);

m = p+1;
for i = 1:p-1,
    Xvec(i,1,:) = Xsym(i,i,:);
    Xvec(m:m+p-i-1,:) = (Xsym(i+1:p,i,:) + permute(Xsym(i,i+1:p,:), [2 1 3:ndim]))/2;
    m = m+p-i;
end
Xvec(p,1,:) = Xsym(p,p,:);

% back to original
Xvec = ipermute(Xvec, [dim, dim+1, dims]);

% Remove extra dimension
Xvec = permute(Xvec, [1:dim, (dim+2):ndim, dim+1]);
