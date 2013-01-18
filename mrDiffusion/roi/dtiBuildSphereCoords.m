function coords = dtiBuildSphereCoords(centerCoord, radius)
%
% coords = dtiBuildSphereCoords(centerCoord, radius)
%
% centerCoord: 1x3 coordinate defining the sphere center.
% radius: scalar defining the radius, in voxel units
%
% If centerCoord is a 1x2, then we do a 2d version.
%
% RETURNS:
%  coords: an Nx3 list of the coordinates that intersect the sphere.
%  (Or Nx2 if the 2d option is selected by passing in a 1x2.)
%
% HISTORY:
% 2003.12.01 RFD (bob@white.stanford.edu) wrote it.
% 2006.09.12 RFD: added 2d option.

if(radius>0)
    if(size(centerCoord,2)==2)
        [X,Y] = meshgrid([-radius:+radius],...
            [-radius:+radius]);
        dSq = X.^2+Y.^2;
        keep = dSq(:) < radius.^2;
        coords = [X(keep)+centerCoord(1), Y(keep)+centerCoord(2)];
    else
        [X,Y,Z] = meshgrid([-radius:+radius],...
            [-radius:+radius],...
            [-radius:+radius]);
        dSq = X.^2+Y.^2+Z.^2;
        keep = dSq(:) < radius.^2;
        coords = [X(keep)+centerCoord(1), Y(keep)+centerCoord(2), Z(keep)+centerCoord(3)];
    end
else
    coords = centerCoord;
end
return;