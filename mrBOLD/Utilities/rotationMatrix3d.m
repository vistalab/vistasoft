function rotMat=rotationMatrix3d(angleList, scale)
% Returns a 3x3 rotation matrix, possibly with a scale factor
%
% rotMat=rotationMatrix3d(angleList, [scale])
%
% PURPOSE: Returns a 3x3 rotation matrix
% corresponding to the angular rotations
% around the x,y,z axes (in that order) specified in
% angleList. Optionally applies a scale factor, either 
% a global scale (if 'scale' is a scalar), or separate 
% X, Y and Z scales if 'scale' is 1x3.
%
% http://www.euclideanspace.com/maths/algebra/matrix/orthogonal/rotation/
%
% Rotation about z axis is: Rz =  	
% cos(a) 	-sin(a) 	0
% sin(a) 	cos(a) 	0
% 0 	0 	1
% 
% Similarly with rotation about y axis:
% Rotation about y axis is: Ry = 	
% cos(a) 	0 	-sin(a)
% 0 	1 	0
% sin(a) 	0 	cos(a)
% 
% And rotation about x axis:
% Rotation about x axis is: Rx = 	
% 1 	0 	0
% 0 	cos(a) 	-sin(a)
% 0 	sin(a) 	cos(a)
%
% AUTHOR: Wade 091603
%         2003.09.16 Dougherty added scale
% (c) Stanford VISTA Team

angleList=angleList(:);
if (length(angleList)~=3)
    error('Must have 3 angles in the angle list');
end
if(~exist('scale','var') || isempty(scale))
    scale = 1;
end
if(length(scale)==1)
    scale = eye(3)*scale;
elseif(length(scale)==3)
    scale = [scale(1) 0 0; 0 scale(2) 0; 0 0 scale(3)];
else
    error('Scale must be a scalar or 1x3.');
end

tx=angleList(1);
ty=angleList(2);
tz=angleList(3);

% Compute the individual matrices for clarity
RotX=[ 1 	0 	0;...
        0 	cos(tx) 	-sin(tx);...
        0 	sin(tx) 	cos(tx)];
    
RotY=[ cos(ty) 	0 	-sin(ty);...
        0       1   0;...
        sin(ty) 0 cos(ty)];

RotZ=[cos(tz)  -sin(tz)  0;...
      sin(tz)  cos(tz)  0;...
      0     0  1];
  
rotMat=RotX*RotY*RotZ*scale;

return