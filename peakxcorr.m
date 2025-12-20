function C = peakxcorr(T, M)
% peakxcorr  Peak normalized cross-correlation and lag between T and many series.
%   C = peakxcorr(T, M)
%   - T is a vector (Nt x 1 or 1 x Nt).
%   - M can be:
%       * Nt x nSeries  (each column is a series)
%       * nRows x nCols x Nt  (grid of series along 3rd dim)
%   - C has the same spatial layout as M but with an extra last dim of size 2:
%       C(...,1) = max cross-correlation (normalized, in [-1,1])
%       C(...,2) = lag (samples) at max (positive => M leads T)

T = T(:);
NtT = numel(T);
T = T - mean(T);    % subtract mean from template

if ismatrix(M) && size(M,1) == NtT        % Nt x nSeries
    nSeries = size(M,2);
    peaks = zeros(nSeries,1);
    lags  = zeros(nSeries,1);
    for k = 1:nSeries
        x = M(:,k);
        x = x(:) - mean(x);              % subtract mean for each series
        [r,lg] = xcorr(x, T, 'coeff');   % normalized to [-1,1]
        [m,idx] = max(r);
        peaks(k) = m;
        lags(k)  = lg(idx);
    end
    C = [peaks, lags];                  % nSeries x 2

elseif ndims(M) == 3 && size(M,3) == NtT  % nRows x nCols x Nt
    [nR,nC,~] = size(M);
    peaks = zeros(nR,nC);
    lags  = zeros(nR,nC);
    for i = 1:nR
        for j = 1:nC
            x = squeeze(M(i,j,:));
            x = x(:) - mean(x);          % subtract mean
            [r,lg] = xcorr(x, T, 'coeff');
            [m,idx] = max(r);
            peaks(i,j) = m;
            lags(i,j)  = lg(idx);
        end
    end
    C = cat(3, peaks, lags);            % nR x nC x 2

else
    error('Unsupported M shape. Use Nt x nSeries or nRows x nCols x Nt (time on first or third dim).');
end
end
