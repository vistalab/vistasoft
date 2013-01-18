function [b0vector b0angle] = getB0direction(vw)
% Return the direction of the b0 field from a scan as (1) a unit vector and
% (2) an angle in degrees
%
%   [b0vector b0angle]  = getB0direction([vw])
%
% Examples: 
%   b0vector = getB0direction(vw)
%   [b0vector b0angle] = getB0direction
%
% vw can be INPLANE, GRAY, or VOLUME

mrGlobals

if ~exist('vw', 'var'), vw = getCurView; end

% get the scanner xform (image coords => mm coords)
scannerXform = viewGet(vw, 'scannerXform');

% Define a unit vector in the z-direction in scanner space. This is the B0
% direction (by definition).
origin = [0 0 0]; z = [0 0 1];

% Transform the vector into INPLANE image space
b0ip = scannerXform \ [origin 1; z 1]';
b0ip = b0ip(1:3,2) - b0ip(1:3,1);

% Make it a unit vector
b0ip = 1/norm(b0ip) * b0ip;

% xform the b0 vector to the appropriate view type
switch lower(viewGet(vw, 'viewType'))
    case 'inplane'
        % done
        b0vector = b0ip;
    case {'gray' 'volume'}
        xform = mrSESSION.alignment;
        b0Vol = xform * [[0 0 0 1]' [b0ip; 1]];
        % make it a vector of norm 1
        b0vector = b0Vol(1:3,2) - b0Vol(1:3,1);
        b0vector = 1/norm(b0vector) * b0vector;
        % xform to xyz
        b0vector = [-b0vector(3) b0vector(2) -b0vector(1)];
    otherwise
        error('Can''t get B0 direction in %s vw', viewGet(vw, 'viewType'))
end

% convert b0 vector into angle. This is the angle between z-vector in image
% space and and z-vector in scanner space.
costheta    = dot(b0vector, z)/norm(b0vector)*norm(z);
theta       = acos(costheta);
b0angle     = theta  / pi * 180;
        