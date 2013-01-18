function [M, rng] = intRescale(M, type);
%
% [M, rng] = intRescale(M, <type = int16>);
%
% Take a double or other numeric matrix,
% rescale to the range of the specified
% data type (by default 'int16') and return 
% M in that type, as well as the range
% [min max] in M before scaling. This
% is intended to be used for dealing
% with large data sets (e.g., time series
% from many scans) which take up tons of 
% memory as doubles.
%
% To convert M back to its double form,
% use:
%       M = normalize(M, rng(1), rng(2));
%
% Note that this will introduce slight inaccuracies
% in the reconstructed matrix (see example below). These
% are usually ~1/1000 of the actual values, and if the
% stored numbers are integers, rounding will resolve this.
% But, it can be an issue for applications which require
% great precision (greater than the number of integers in 
% the int16 type).
%
% EXAMPLE:
%   [new, rng]  = intRescale(1:10);
%   old = normalize(new, rng(1), rng(2));
%
% ras, 06/05.
if ~exist('type','var') | isempty(type),
    type = 'int16';
end

rng = double([min(M(:)) max(M(:))]);

% get rescaled min/max, based on data type:
% there are functions for this in ML7, but 
% in earlier matlab we have to kludge it:
v = version;
if str2num(v(1))>7
    resMin = intmin(type);
    resMax = intmax(type);
else
    resMin = -32768;
    resMax = 32768;
end

if diff(rng)==0
    % if the requested range is 0 (min==max), then we just need to remove the
    % current offset (=rng(1), which also =rng(2)) and apply the new scale
    % and offset.
    M = round((M-rng(1)) * (resMax-resMin) + resMin);
else
    M = round( (M-rng(1)) ./ diff(rng) * (resMax-resMin) + resMin );
end

cmd = sprintf('M = %s(M);',type);
eval(cmd);


return
