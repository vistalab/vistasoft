% [N,X] = histo(MTX, NBINS_OR_BINSIZE, BIN_CENTER);
%
% Compute a histogram of (all) elements of MTX.  N contains the histogram
% counts, X is a vector containg the centers of the histogram bins.
%
% NBINS_OR_BINSIZE (optional, default = 101) specifies either
% the number of histogram bins, or the negative of the binsize.
%
% BIN_CENTER (optional, default = mean2(MTX)) specifies a center position
% for (any one of) the histogram bins.
%
% How does this differ from MatLab's HIST function?  This function:
%   - allows uniformly spaced bins only.
%   +/- operates on all elements of MTX, instead of columnwise.
%   + is much faster (approximately a factor of 80 on my machine).
%   + allows specification of number of bins OR binsize.  Default=101 bins.
%   + allows (optional) specification of BIN_CENTER.

% Eero Simoncelli, 3/97.

function [N, X] = histo(mtx, nbins, bin_ctr)

%% NOTE: THIS CODE IS NOT ACTUALLY USED! (MEX FILE IS CALLED INSTEAD)

% fprintf(1,'WARNING: You should compile the MEX code for "histo", found in the MEX subdirectory.  It is MUCH faster.\n');

mtx = mtx(:);

%------------------------------------------------------------
%% OPTIONAL ARGS:

if (exist('nbins') == 1) 
  if (nbins < 0)
    [mn,mx] = range2(mtx);
    nbins = ceil((mx-mn)/(-nbins));
  else
    nbins = round(nbins);
  end
else
  nbins = 101;
end

if (exist('bin_ctr') == 1) 
  warning('Ignoring BIN_CENTER argument...');
end

[N, X] = hist(mtx, nbins);
