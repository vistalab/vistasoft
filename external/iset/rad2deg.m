function deg = rad2deg(rad);
%
%  deg = rad2deg(rad);
%
% Convert numeric vectors specifying radians of
% angle into degrees.
%
% ras 02/05. Apparently this isn't in new versions of matlab?

% convert to radians
deg =  360 .* rad ./ (2*pi);

% wrap around 360
deg = mod(deg,360);

return