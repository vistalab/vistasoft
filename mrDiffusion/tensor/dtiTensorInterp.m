function dt6 = dtiTensorInterp(dt6, coords, voxDims, scale, origin, derivs)
%
% dt6 = dtiTensorInterp(dt6, coords, voxDims, [scale], [origin], [derivs])
%
% Implements Pajevic's B-spline tensor interpolation function as described
% in S. Pajevic, A. Aldroubi, and P.J. Basser, "A Continuous Tensor Field
% Approximation of Discrete DT-MRI Data for Extracting Microstructural and
% Architectural Features of Tissue", vol. 154, pp. 85-100, 2002.
%
% dt6_interp = dtiTensorInterp_Pajevic(dt6, coords, voxDims, ...
%                   [scale], [origin], [derivs])
%
% dt6_interp    Nx6 list of interpolated tensors at N required locations
% dt6           XxYxZx6 reference tensor array (Dxx, Dyy, Dzz, Dxy, Dxz, Dyz)
% coords        Nx3 list of required locations (x, y, z) in mm with respect
%               to origin (0, 0, 0)
% voxDims       1x3 array of voxel dimensions in mm (Vx, Vy, Vz)
% scale         If 1 (default), produces interpolation
%               If in (0, 1), produces least-squares approximation
% origin        1x3 array - origin of coordinate system. Default: (Vx/2, Vy/2,
%               Vz/2) so that (0, 0, 0) is in the center of the first voxel.
% derivs        1x3 array - degree of the derivate with respect to x, y and z
%               desired for the output. Default: (0, 0, 0) (no derivates)
%

if(~exist('scale','var') | isempty(scale))
    scale = 1;
end
if(~exist('origin','var') | isempty(origin))
    origin = voxDims./2;
end
if(~exist('derivs','var') | isempty(derivs))
    derivs = [0,0,0];
end

old = pwd;
cd(fileparts(which('dtiTensorInterp_Pajevic')));
dt6 = dtiTensorInterp_Pajevic(dt6, coords, voxDims, scale, origin, derivs);
cd(old);
return;