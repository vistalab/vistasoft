function amps = projamps(A, basis);
%
% amps = projamps(A, basis);
%
% Compute projection amplitude of a set of vectors onto a basis vector(s).
% The projection amplitude is defined as 
%
% (A.basis) / sqrt(basis.basis), 
%
% where . represents the dot product of the vector. Before computing, 
% each vector in A is normalized to have zero mean, as is the basis vector. 
%
% A can be a single vector, or a matrix in which the columns are vectors. 
% Basis can also be a single vector, or a matrix the same size as A. If
% basis is a single vector and A is a matrix, all columns of A will be
% projected onto the single basis vector; if they are both matrices, each
% column in A will be projected on to the corresponding column of basis.
%
% For more info on the uses of these amplitudes, see:
% http://white.stanford.edu/~brian/mrv/BOLDResponseContrast.pdf
%
% ras, 03/06.
if nargin<2, help(mfilename); error('Not enough input args.'); end

if size(A, 1)==1, A = A(:); end

[m n] = size(A);

if size(basis,1)==1 | size(basis,2)==1
    basis = repmat(basis(:), [1 n]);
end

% remove means from each vector
A = A - ones(m,1) * mean(A,1);
basis = basis - ones(m,1) * mean(basis,1);

% set basis to unit contrast
basis = basis ./ [ones(m,1) * (max(basis)-min(basis))];

amps =  dot(A, basis) / sqrt(dot(basis, basis));

return
        