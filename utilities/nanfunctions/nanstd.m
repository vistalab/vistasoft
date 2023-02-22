function y = nanstd(varargin)
%Replacement for Matlab NANSTD Standard deviation, ignoring NaNs.
%

y = sqrt(nanvar(varargin{:}));

return;
