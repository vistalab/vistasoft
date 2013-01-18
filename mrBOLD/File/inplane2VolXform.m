function Xform = inplane2VolXform(rot,trans,scaleFac)
%
% Xform = inplane2VolXform(rot,trans,scaleFac)
%
% Returns 4x4 homogeneous tranform that tranforms from inplane to
% volume.
%
% djh/gmb, '97
%
% Modification:
% - Flip first 2 rows and cols so that it deals with
% (y,x,z) coords instead of (x,y,z).  DJH, 7/98.

A=diag(scaleFac(2,:))*rot*diag(1./scaleFac(1,:));
b = (scaleFac(2,:).*trans)';

Xform = zeros(4,4);
Xform(1:3,1:3)=A;
Xform(1:3,4)=b;
Xform(4,4)=1;

Xform([1 2],:) = Xform([2 1],:);
Xform(:,[1 2]) = Xform(:,[2 1]);
    
    
