function domeC = sphere2flat(bvecs,twodStyle)
% Compute two angle coordinates for the upper dome of a set of b-vectors
%
%  domeC = sphere2flat(bvecs,[twodStyle])
%
% This routine is used to represent DWI values.  It provides a way to
% visualize the data from a set of bvecs in a planar representation.  The
% idea is to project the upper half of the bvec directions onto the XY
% plane.
%
% The calculated is basically as follows.
%
%  * The bvecs vectors are Nx3
%  * The bvecs are made unit length.
%  * All bvecs are reflected through the origin to point to the upper
% dome (Z dimension is positive). 
%  * We compute a planar position. By default (twodStyle - 'xy') we project
%  each point on the sphere down onto the XY plane, as if you were looking
%  straight down from the top of the sphere
% 
% twodStyle options:
%
%   'xy'    - default
%   'azel'  - azimuth and elevation of each point
%   'polar' - eccentricity and angle
%   'domeC' - returns the 3D coordinates after flipping to upper position
%
% Example
%   [X,Y,Z] = sphere; bvecs = [X(:),Y(:),Z(:)];
%   plot3(X(:),Y(:),Z(:),'o'); axis equal
%
%   domeC = sphere2flat(bvecs,'polar');
%   mrvNewGraphWin; plot(domeC(:,1),domeC(:,2),'o')
%
%   domeC = sphere2flat(bvecs,'azel')
%   mrvNewGraphWin; plot(domeC(:,1),domeC(:,2),'o')
%
%   domeC = sphere2flat(bvecs,'xy')
%   mrvNewGraphWin; plot(domeC(:,1),domeC(:,2),'o')
%
%   domeC = sphere2flat(bvecs,'xy');
%   mrvNewGraphWin; plot(domeC(:,1),domeC(:,2),'o')
%
%   domeC = sphere2flat(bvecs,'half sphere');
%
% (c) Stanford VISTA Team 2012

% Also need bvecs = AE2vec(AE);   % In this case always unit vecs
%

if notDefined('bvecs') || size(bvecs,2) ~= 3
    error('Nx3 vectors are required');
end
if notDefined('twodStyle'), twodStyle = 'xy'; end

%% Set up the bvecs

% Flip bvecs with a Z value < 0 over to positive side of the dome
l = (bvecs(:,3) < 0);
bvecs(l,:) = -1*bvecs(l,:);
% plot3(bvecs(:,1),bvecs(:,2),bvecs(:,3),'o'); grid on

% Make bvecs  unit length
l = sqrt(diag(bvecs*bvecs'));
bvecs = diag(1./l)*bvecs;
% plot3(bvecs(:,1),bvecs(:,2),bvecs(:,3),'o'); grid on

%% Create the coordinate from for the dome coordinates

twodStyle = mrvParamFormat(twodStyle);
switch twodStyle;
    case 'xy'
        
        % Like looking straight down 
        domeC = [bvecs(:,1), bvecs(:,2)];
        
    case 'polar'
        % Polar coordinates in the (x,y) plane
        [theta rho] = cart2pol(bvecs(:,1),bvecs(:,2));
        domeC = [theta(:), rho(:)];
    case 'azel'
        % Azimuth and elevation style
        
        % The first dimension is the angle in the XY plane, where
        %  (1,0)  is 0
        %  (0,1)  is pi/2
        %  (-1,0) is pi
        %  (0,-1) is 3pi/2
        
        % Convert (x,y) to complex and take the angle
        % Then map -pi,pi to 0,2pi
        azimuth = angle(bvecs(:,1).* exp(sqrt(-1)*bvecs(:,2))) + pi;
          
        % The second dimension is the angle between the vector and the Z
        % (3rd) dimension.  This ranges between 0 and pi because we made
        % the 3rd dimension all positive.
        elevation = acos(bvecs(:,3));
        
        domeC = [azimuth,elevation];
    case {'halfsphere','dome'}
        domeC = bvecs;
    otherwise
        error('Unknown 2D style:  %s\n',twodStyle);
end

return

