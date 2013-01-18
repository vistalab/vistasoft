function theta = polarAngle(phi, params);
% From corAnal phase data (phi), compute the polar angle in 
% degrees clockise from the 12-o-clock position (theta).
%
%  theta = polarAngle(phi, params);
%
% phi can be any numeric matrix representing phase data. 
% It will be scaled to be in the range [0, 2*pi].
%
% params is a struct describing the design of the polar-angle-mapping
% experiment from which phi is taken. See retinoSetParams for more
% info on this. 
%
% Will output a theta the same size as phi, containing an estimate
% of the polar angle for each voxel in phi.
%
% MODEL: this mapping makes the following assumptions: 
% (1) Phi represents an accurate estimate of the zero-crossing point of
%     the best-fitting sinusoid for a given voxel's time series. This 
%     is what computeCorAnal computes, but the co threshold should be
%     reasonable.
% (2) Phi corresponds to the time when the leading edge of a wedge stimulus
%     just entered the receptive field of neurons within a voxel (and so
%     the neurons just started firing, and the hemodynamic response started
%     rising above the mean). This means the rise time for the hemodynamic
%     response should be about the same time as the rise time of the
%     sinusoid.
% 
% The model is a simple linear model:
%   theta = m*phi + phi_0;  
% where:
%   phi_0 represents the position of the leading edge of the
%   wedge stimulus at the beginning of each cycle -- this is equal
%   to params.startAngle + direction*params.width/2
%   (where direction is +1 for clockwise and -1 for counterclockwise);
%   m is the ratio of change in theta/change in phi -- equal to 
%   params.visualField / (2*pi). 
%
% ras, 01/06.
% ras, 04/09 -- ignores width parameter for now, since it doesn't seem to
% work well in conjunction with the color bar code.
if nargin < 2, help(mfilename); error('Not enough input args.'); end

if isequal(lower(params.direction), 'clockwise')
    direction = 1;
else
    direction = -1;
end

phi_0 = params.startAngle; % + direction*params.width/2;
m = (direction*params.visualField) / (2*pi);
theta = m.*phi + phi_0;

% wrap to be in range [0, 360]
theta = mod(theta, 360);

return
