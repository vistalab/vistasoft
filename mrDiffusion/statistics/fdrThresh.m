function thr = fdrThresh(fdrCurve, x, level, sgn)

% thr = fdrThresh(fdrCurve, x, level, [SGN])
%
% Computes the FDR threshold for a given level.
% The FDR curve is fdrCurve as a function of x.
% SGN is +1 (default) or -1, for upper or lower tail thresholds, respectively.
%
% The function assumes the curve tends to decrease in the direction SGN,
% i.e. left to right if SGN = 1, right to left if SGN = -1.
% It searches in the direction SGN for the first value of t where
% fdrCurve is lower than level and then adjusts the level crossing by
% linear interpolation between adjacent values of t.
%
% Copyright by Armin Schwartzman, 2005
%
% HISTORY:
%   2005.09.30 ASH (armins@hsph.harvard.edu) wrote it.
%

sgn = sign(sgn);
if (sgn==0),
    error('SGN should be 1 or -1')
end

I = find(fdrCurve(isfinite(fdrCurve)) < level);
if isempty(I),
    thr = NaN;
    warning('FDR curve does not cross level line.')
else
    k = sgn*min(sgn*I);
    if ((k-sgn < 1) | (k-sgn > length(fdrCurve))),
        thr = x(k);
    else
        thr = interp1(fdrCurve([k-sgn,k]), x([k-sgn,k]), level);
    end
end

return
