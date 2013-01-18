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
P         = [A(1:3,4)' 0 0 0  diag(C)'  0 0 0];
if det(R)<0, P(7)=-P(7);end % Fix for -ve determinants

% Shears
%-----------------------------------------------------------------------
C         = diag(diag(C))\C;
P(10:12)  = C([4 7 8]);
R0        = affineBuild([0 0 0], [0 0 0], P(7:9), P(10:12));
R0        = R0(1:3,1:3);
R1        = R/R0;

% This just leaves rotations in matrix R1
%-----------------------------------------------------------------------
%[          c5*c6,           c5*s6, s5]
%[-s4*s5*c6-c4*s6, -s4*s5*s6+c4*c6, s4*c5]
%[-c4*s5*c6+s4*s6, -c4*s5*s6-s4*c6, c4*c5]

P(5) = asin(rang(R1(1,3)));
if (abs(P(5))-pi/2).^2 < 1e-9,
	P(4) = 0;
	P(6) = atan2(-rang(R1(2,1)), rang(-R1(3,1)/R1(1,3)));
else,
	c    = cos(P(5));
	P(4) = atan2(rang(R1(2,3)/c), rang(R1(3,3)/c));
	P(6) = atan2(rang(R1(1,2)/c), rang(R1(1,1)/c));
end;
trans = P(1:3);
rot = P(4:6);
scale = P(7:9);
skew = P(10:12);
return;

% There may be slight rounding errors making b>1 or b<-1.
function a = rang(b)
a = min(max(b, -1), 1);
return;
