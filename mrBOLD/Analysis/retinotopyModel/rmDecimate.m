function y=rmDecimate(x,r)
% rmDecimate - decimate the signal by factor (r) along first dimension.
%
%  y=rmDecimate(x,r);
%
% 2007/01 SOD: wrapper for matlab's decimate

% input check
if ~exist('x','var') || isempty(x),
    disp('Need x');
    return;
end

% no decimation if: r is not given, empty or smaller than 2.
if ~exist('r','var') || isempty(r) || r<2,
    y=x;
    return;
end

% get size of x
[s1, s2] = size(x);

% sometimes we input single precision
convert_back_to_single = false;
if isa(x,'single')
    convert_back_to_single = true;
    x=double(x);
end

% filter along first dimension, i should really vectorize this....
y = zeros(ceil(s1./r),s2);
for ii=1:s2
    % The function decimate appears to be gone from later versions of
    % Matlab.  Check what's going on here ...
    y(:,ii) = decimate(x(:,ii),r);
end

if convert_back_to_single,
    y = single(y);
end

return