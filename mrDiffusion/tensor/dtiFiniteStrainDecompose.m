function [rigidXform,deformXform] = dtiFiniteStrainDecompose(xform)
%
% Decomposes the non-affine portion of the 4x4 affine xform into the
% the rigid rotation component and the deformation component, according to
% the Finite Strain method, as described in Alexander et al (2001). IEEE
% Transactions on Medical Imaging, v20-11.
%
% 2004.08.06 RFD & ASH wrote it.

F = xform(1:3,1:3);

% R = (F*F')^-1/2 * F
rigidXform = inv(sqrtm((F*F'))) * F;
deformXform = inv(rigidXform) * F;

return;