function H = fdrHist(X, dx, POS, rng)

% H = fdrHist(X, dx, [POS], [RANGE])
%
% Creates a structure H with fields 'x' and 'hist'.
% H.hist contains the histogram of the vector X at bins H.x spaced by dx.
% The histogram uses actual counts. Divide by sum(H.hist) to normalize.
% The bin centers H.x are computed so that one bin center is exactly 0.
% If POS = 1, dx/2 is added to the bin centers, e.g. if X is a positive RV.
% If RANGE = [xmin xmax] is not specified, then xmin = min(X) and xmax = max(X).
%
% See also:
%       fdrTheoNull, fdrEmpNull

% HISTORY:
%   2005.09.28 ASH (armins@stanford.edu) wrote it.

if ~exist('POS'),
    POS = 0;
elseif (POS ~= 0) & (POS ~= 1),
    error('The flag POS should be 0 or 1');
end
if ~exist('rng'),
    rng(1) = dx * round(min(X) / dx);
    rng(2) = dx * round(max(X) / dx);
end

% Bins
H.x = (rng(1)+POS*dx/2):dx:rng(2);
H.x = H.x';

% Histogram
H.hist = hist(X, H.x);
H.hist = H.hist';
