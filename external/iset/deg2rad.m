function rad = deg2rad(deg);
%
% rad = deg2rad(deg);
%
% Convert numeric vectors specifying degrees of
% angle into radians.
%
% ras 02/05. Apparently this isn't in new versions of matlab?

% wrap around 360
deg = mod(deg,360);

% convert to radians
rad =  (2*pi) .* deg ./ 360;

return