function [trans,rot,scale,skew] = affineDecompose(A)
%
% [trans,rot,scale,skew] = affineDecompose(A)
%
% Decomposes an affine (orthogonal linear) transformation matrix into its
% four componets: translations, rotations scales and skews.
%
% (See affineBuild for more info.)
%
% HISTORY:
%   2004.03.12 RFD (bob@white.stanford.edu) shamelessly copied the core
%   algorithm from spm99's spm_imatrix.m.
%   2005.07.08 ras (sayres at stanford edu) imported into mrVista 2.0

% Translations and zooms
%-----------------------------------------------------------------------
R         = A(1:3,1:3);
C         = chol(R'*R);
if(size(A,2)>3)
    trans = A(1:3,4)';
else
    trans = [0 0 0];
end
scale = diag(C)';
if det(R)<0, scale(1)=-scale(1);end % Fix for -ve determinants

% Shears
%-----------------------------------------------------------------------
C         = diag(diag(C))\C;
skew      = C([4 7 8]);
R0        = affineBuild([0 0 0], [0 0 0], scale, skew);
R0        = R0(1:3,1:3);
R1        = R/R0;

% This just leaves rotations in matrix R1
%-----------------------------------------------------------------------
%[          c5*c6,           c5*s6, s5]
%[-s4*s5*c6-c4*s6, -s4*s5*s6+c4*c6, s4*c5]
%[-c4*s5*c6+s4*s6, -c4*s5*s6-s4*c6, c4*c5]

rot(2) = asin(rang(R1(1,3)));
if (abs(rot(2))-pi/2).^2 < 1e-9,
	rot(1) = 0;
	rot(3) = atan2(-rang(R1(2,1)), rang(-R1(3,1)/R1(1,3)));
else,
	c    = cos(rot(2));
	rot(1) = atan2(rang(R1(2,3)/c), rang(R1(3,3)/c));
	rot(3) = atan2(rang(R1(1,2)/c), rang(R1(1,1)/c));
end;

return;

% There may be slight rounding errors making b>1 or b<-1.
function a = rang(b)
a = min(max(b, -1), 1);
return;
