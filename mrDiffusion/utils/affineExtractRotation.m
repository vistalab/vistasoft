function rot = affineExtractRotation(A)
%
% rot = affineExtractRotation(A)
%
% Extracts the rotation component from an affine transform matrix.
% Returns the 3x3 rotation matrix. To get the three Euler angles, use
% affineDecompose.
%
% (See also affineBuild, affineDecompose.)
%
% HISTORY:
%   2007.05.11 RFD (bob@white.stanford.edu) wrote it.

% Extract 3x3 rotation/scale/skew component
rot = A(1:3,1:3);
C = chol(rot'*rot);
s = diag(C)';
if det(rot)<0, s(1) = -s(1); end % Fix negative determinants

% Remove skews and scales, leaving just the rotations
C = diag(diag(C))\C;
k = C([4,7,8]);
sk = [ s(1)  0    0;
         0   s(2)  0;
         0    0   s(3)] ...
     *[  1   k(1) k(2);
         0   1    k(3);
         0   0     1  ];
rot = rot/sk;

end