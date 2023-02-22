function volume = estimateTissueVolume(curvature, thickness, surfaceArea)
%
% volume = estimateTissueVolume(curvature, thickness, surfaceArea)
%
% * curvature is an array of curvature estimates for each mesh triangle
% * thickness is the estimated tissue thickness
% * surfaceArea is the actual surface area of each triangle (on the plane)
%
% To estimate the volume, if the curvature is zero we can just multiply the
% single surface area of the triangle by the thickness of the tissue. But,
% if the local curvature is not zero, then the surface area at the white
% matter boundary differs from the surface area thickness millimeters away.
% So, we can 't just multiply a single area by the thickness.  Instead, we
% have to measure the volume by taking the difference between two spheres
% that define the inner and outer radius of the local curvature at the two
% boundaries of the gray matter.
%
% This routine measures the volume between these two surfaces rather than
% assuming there is a single surface area and multiplying by the thickness.
%
% Estimates the volume of tissue of a given thickness on a surface with the
% specified mean curvature. The algorithm simply estimates the tissue
% volume on a sphere of radius 1/curvature and radius + thickness.  It
% takes the local volume estimate as the surfaceArea/sphereSurfaceArea 
% proportion of the total volume between these spheres.
%
% HISTORY: RFD (bob@white.stanford.edu) wrote it.
%

if(~exist('curvature','var') | isempty(curvature))
    help(mfilename);
    return;
end

curvature(curvature==0) = 0.0000001;
r = 1./curvature;

sphereSurfaceArea = 4*pi*r.^2;
innerV = (4*pi/3).*(r.^3);
outerV = (4*pi/3).*(r + thickness).^3;
totalTissueVolume = outerV - innerV;

volume = totalTissueVolume.*(surfaceArea./sphereSurfaceArea);

return;