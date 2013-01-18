function A = affineBuild(trans, rot, scale, skew)
%
% A = affineBuild(trans, rot, scale, skew)
%
% Builds an affine (orthogonal linear) transformation matrix from the four
% componets: translations, rotations scales and skews.
%
% trans, rot, scale, skew should all be 1x3 vectors specifying x,y,z.
% Rotations are in radians, and can be described as pitch (x-rotation),
% roll (y-rotation) and yaw (z-rotation).
%
% The transformations are applied in the following order:
%
% 1) translations
% 2) rotations
% 3) scaling
% 4) skews
%
% The form of the transform assumes a PRE-multiplication format:
% Y = A*X where X and Y are 4 x n arrays of n coordinates.
%
% HISTORY:
%   2004.03.12 RFD (bob@white.stanford.edu) shamelessly copied the core
%   algorithm from spm99's spm_matrix.m.
%   2005.07.08 ras (sayres at stanford edu) imported into mrVista 2.0
%   2005.07.28 ras enorces double class for inputs
if ~exist('skew','var') | isempty(skew), skew = [0 0 0];    end
if ~exist('scale','var') | isempty(scale), scale = [1 1 1]; end
if ~exist('rot','var') | isempty(rot), rot = [0 0 0];       end
if ~exist('trans','var') | isempty(trans), trans = [0 0 0]; end
if ~isa(trans,'double'), trans = double(trans);             end
if ~isa(rot,'double'), rot = double(rot);                   end
if ~isa(scale,'double'), scale = double(scale);             end
if ~isa(skew,'double'), skew = double(skew);                end

A  = eye(4);

A  = A*[1 	0 	0  trans(1);
        0 	1 	0  trans(2);
        0 	0 	1  trans(3);
        0 	0 	0  1];

A  = A*[1   0            0            0;
        0   cos(rot(1))  sin(rot(1))  0;
        0  -sin(rot(1))  cos(rot(1))  0;
        0   0    	      0           1];

A  = A*[cos(rot(2))  0  sin(rot(2))  0;
        0    	     1  0            0;
       -sin(rot(2))  0  cos(rot(2))  0;
        0            0  0            1];

A  = A*[cos(rot(3))  sin(rot(3))  0  0;
       -sin(rot(3))  cos(rot(3))  0  0;
        0            0            1  0;
        0     	     0    	      0  1];

A  = A*[scale(1) 0         0         0;
        0        scale(2)  0         0;
        0        0         scale(3)  0;
        0        0         0         1];

A  = A*[1  skew(1)  skew(2)  0;
        0  1        skew(3)  0;
        0  0        1        0;
        0  0        0        1];
    
return;
