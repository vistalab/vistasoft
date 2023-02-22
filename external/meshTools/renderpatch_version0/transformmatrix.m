function transm = transformmatrix(s,r,t)
% *** Homogeneous transformation matrix ***
% Function transformmatrix returns transformation matrix from object to image space.
%
% transm = transformmatrix (s,r,t)
%
% inputs,
%   s = Zoom factor
%   r = Rotation vector (rotx,roty,rotz)
%   t = Translation Vector [x,y,z]
%
% transm = Rotation Matrix
%

S=[s 0 0 0;
   0 s 0 0;
   0 0 s 0;
   0 0 0 1];

Rx=[1 0 0 0;
    0 cos(r(1)) -sin(r(1)) 0;
    0 sin(r(1)) cos(r(1)) 0;
    0 0 0 1];

Ry=[cos(r(2)) 0 sin(r(2)) 0;
    0 1 0 0;
    -sin(r(2)) 0 cos(r(2)) 0;
    0 0 0 1];

Rz=[cos(r(3)) -sin(r(3)) 0 0;
    sin(r(3)) cos(r(3)) 0 0;
    0 0 1 0;
    0 0 0 1];

R=Rx*Ry*Rz;

T=[1 0 0 t(1);
   0 1 0 t(2);
   0 0 1 t(3);
   0 0 0 1];

transm = S*R*T;