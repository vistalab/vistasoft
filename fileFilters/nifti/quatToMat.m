function R = quatToMat(b, c, d, qx, qy, qz, qfac, pixdim)
%
% R = quatToMat(qb, qc, qd, qx, qy, qz, qfac, pixdim)
%
% Convert a quaternion to a 4x4 rotation/scaling/translation matrix. Based on the
% nifti1 spec implemented in nifti1_io.c.
%
% 2008.10.01 RFD: wrote it.
%

if(isstruct(b))
    c = b.quatern_c;
    d = b.quatern_d;
    qx = b.quatern_x;
    qy = b.quatern_y;
    qz = b.quatern_z;
    qfac = b.qfac;
    pixdim = [b.dx b.dy b.dz];
    b = b.quatern_b;
end

R = zeros(4);

R(4,:) = [0 0 0 1];

% compute a from b,c,d
a = 1.0 - (b*b + c*c + d*d);
if( a < 1.e-7 )                     % special case
     a = 1.0 / sqrt(b*b+c*c+d*d);
     b = b*a; c = c*a; d = d*a;     % normalize (b,c,d) vector
     a = 0.0;                       % a = 0 ==> 180 degree rotation
else
     a = sqrt(a);                   % angle = 2*arccos(a)
end

% build rotation matrix, including scaling factors for voxel sizes
if length(pixdim) == 3 
    xd = pixdim(1); yd = pixdim(2); zd = pixdim(3);
else
    xd = pixdim(1); yd = pixdim(2); zd = 1;
end
if(xd<=0.0), xd = 1.0; end
if(yd<=0.0), yd = 1.0; end
if(zd<=0.0), zd = 1.0; end

if(qfac < 0.0), zd = -zd; end       % left handedness?

R(1,1) =       (a*a+b*b-c*c-d*d) * xd ;
R(1,2) = 2.0 * (b*c-a*d        ) * yd ;
R(1,3) = 2.0 * (b*d+a*c        ) * zd ;
R(2,1) = 2.0 * (b*c+a*d        ) * xd ;
R(2,2) =       (a*a+c*c-b*b-d*d) * yd ;
R(2,3) = 2.0 * (c*d-a*b        ) * zd ;
R(3,1) = 2.0 * (b*d-a*c        ) * xd ;
R(3,2) = 2.0 * (c*d+a*b        ) * yd ;
R(3,3) =       (a*a+d*d-c*c-b*b) * zd ;

% load offsets

R(1:3,4) = [qx;qy;qz];

return;
