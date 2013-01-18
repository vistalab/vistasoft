function [nrows ncols] = subplotSz(n)
% [nrows ncols] = subplotSz(n)
%
% Choose the size, rows x cols, of a subplot. Make it as small as possible
% and as close to square as possible. 
%
% Example:
%
% [nrows, ncols] = subplotSz(19)


if nargin < 1, 
    help subplotSz
    return
end

nrows = round(sqrt(n));
ncols = ceil(n/nrows);

end