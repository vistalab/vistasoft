function q = matToQuat(R)
%
% quat = matToQuat(R)
%
% Convert a 4x4 rotation/scaling/translation matrix to a quaternion. Based
% on the nifti1 spec implemented in nifti1_io.c.
%
% From the nifti1_io docs:
%      - If the 3 input matrix columns are NOT orthogonal, they will be
%        orthogonalized prior to calculating the parameters, using
%        the polar decomposition to find the orthogonal matrix closest
%        to the column-normalized input matrix.
%      - However, if the 3 input matrix columns are NOT orthogonal, then
%        the matrix produced by nifti_quatern_to_mat44 WILL have orthogonal
%        columns, so it won't be the same as the matrix input here.
%        This "feature" is because the NIFTI 'qform' transform is
%        deliberately not fully general -- it is intended to model a volume
%        with perpendicular axes.
%      - If the 3 input matrix columns are not even linearly independent,
%        you'll just have to take your luck, won't you?
%
%    \see "QUATERNION REPRESENTATION OF ROTATION MATRIX" in nifti1.h
% 
%
% 2010.01.26 RFD: wrote it to replace the mex file fo the same name.
%

% Initialize output struct
q.quatern_b = 0;
q.quatern_c = 0;
q.quatern_d = 0;
q.quatern_x = 0;
q.quatern_y = 0;
q.quatern_z = 0;
q.dx = 0;
q.dy = 0;
q.dz = 0;
q.qfac = 0;

% offset outputs are copied directly from input matrix

%ASSIF(qx,R.m[0][3]) ; ASSIF(qy,R.m[1][3]) ; ASSIF(qz,R.m[2][3]) ;
q.quatern_x = R(1,4);
q.quatern_y = R(2,4);
q.quatern_z = R(3,4);

% compute lengths of each column; these determine grid spacings
q.dx = sqrt( R(1,1)*R(1,1) + R(2,1)*R(2,1) + R(3,1)*R(3,1) );
q.dy = sqrt( R(1,2)*R(1,2) + R(2,2)*R(2,2) + R(3,2)*R(3,2) );
q.dz = sqrt( R(1,3)*R(1,3) + R(2,3)*R(2,3) + R(3,3)*R(3,3) );

% if a column length is zero, patch the trouble

if( q.dx == 0.0 )
    R(1,1) = 1.0; R(2,1) = 0.0; R(3,1) = 0.0; q.dx = 1.0;
end
if( q.dy == 0.0 )
    R(2,2) = 1.0; R(1,2) = 0.0; R(3,2) = 0.0; q.dy = 1.0;
end
if( q.dz == 0.0 )
    R(3,3) = 1.0; R(1,3) = 0.0; R(2,3) = 0.0; q.dz = 1.0;
end

% normalize the columns

R(1,1) = R(1,1) / q.dx ; R(2,1) = R(2,1) / q.dx ; R(3,1) = R(3,1) / q.dx ;
R(1,2) = R(1,2) / q.dy ; R(2,2) = R(2,2) / q.dy ; R(3,2) = R(3,2) / q.dy ;
R(1,3) = R(1,3) / q.dz ; R(2,3) = R(2,3) / q.dz ; R(3,3) = R(3,3) / q.dz ;

% At this point, the matrix has normal columns, but we have to allow
% for the fact that the hideous user may not have given us a matrix
% with orthogonal columns.
%
% So, now find the orthogonal matrix closest to the current matrix.
%
% One reason for using the polar decomposition to get this
% orthogonal matrix, rather than just directly orthogonalizing
% the columns, is so that inputting the inverse matrix to R
% will result in the inverse orthogonal matrix at this point.
% If we just orthogonalized the columns, this wouldn't necessarily hold

%    Q.m[0][0] = r11 ; Q.m[0][1] = r12 ; Q.m[0][2] = r13 ;
%    Q.m[1][0] = r21 ; Q.m[1][1] = r22 ; Q.m[1][2] = r23 ;
%    Q.m[2][0] = r31 ; Q.m[2][1] = r32 ; Q.m[2][2] = r33 ;
%
%    P = nifti_mat33_polar(Q) ;  /* P is orthog matrix closest to Q */
%
%    r11 = P.m[0][0] ; r12 = P.m[0][1] ; r13 = P.m[0][2] ; /* unload */
%    r21 = P.m[1][0] ; r22 = P.m[1][1] ; r23 = P.m[1][2] ;
%    r31 = P.m[2][0] ; r32 = P.m[2][1] ; r33 = P.m[2][2] ;

% We'll use SVD to get the closest orthogonal matrix:
[U , S, V] = svd(R(1:3,1:3));
R(1:3,1:3) = U*V';

% at this point, the matrix R(1:3,1:3) is orthogonal
% compute the determinant to determine if it is proper
% zd = R(1,1)*R(2,2)*R(3,3)-R(1,1)*R(3,2)*R(2,3)-R(2,1)*R(1,2)*R(3,3)+R(2,1)*R(3,2)*R(1,3)+R(3,1)*R(1,2)*R(2,3)-R(3,1)*R(2,2)*R(1,3) ;  % should be -1 or 1

if( det(R(1:3,1:3)) > 0 )   % proper
    q.qfac = 1.0;
else                        % improper ==> flip 3rd column
    q.qfac = -1.0;
    R(1,3) = -R(1,3) ; R(2,3) = -R(2,3) ; R(3,3) = -R(3,3) ;
end

% now, compute quaternion parameters

qa = R(1,1) + R(2,2) + R(3,3) + 1.0;

if( qa > 0.5 )               % simplest case
    qa = 0.5 * sqrt(qa) ;
    q.quatern_b = 0.25 * (R(3,2)-R(2,3)) / qa ;
    q.quatern_c = 0.25 * (R(1,3)-R(3,1)) / qa ;
    q.quatern_d = 0.25 * (R(2,1)-R(1,2)) / qa ;
else                         % trickier case
    xd = 1.0 + R(1,1) - (R(2,2)+R(3,3)) ;  % 4*b*b
    yd = 1.0 + R(2,2) - (R(1,1)+R(3,3)) ;  % 4*c*c
    zd = 1.0 + R(3,3) - (R(1,1)+R(2,2)) ;  % 4*d*d
    if( xd > 1.0 )
        q.quatern_b = 0.5 * sqrt(xd) ;
        q.quatern_c = 0.25* (R(1,2)+R(2,1)) / q.quatern_b ;
        q.quatern_d = 0.25* (R(1,3)+R(3,1)) / q.quatern_b ;
        qa          = 0.25* (R(3,2)-R(2,3)) / q.quatern_b ;
    elseif( yd > 1.0 )
        q.quatern_c = 0.5 * sqrt(yd) ;
        q.quatern_b = 0.25* (R(1,2)+R(2,1)) / q.quatern_c ;
        q.quatern_d = 0.25* (R(2,3)+R(3,2)) / q.quatern_c ;
        qa          = 0.25* (R(1,3)-R(3,1)) / q.quatern_c ;
    else
        q.quatern_d = 0.5 * sqrt(zd) ;
        q.quatern_b = 0.25* (R(1,3)+R(3,1)) / q.quatern_d ;
        q.quatern_c = 0.25* (R(2,3)+R(3,2)) / q.quatern_d ;
        qa          = 0.25* (R(2,1)-R(1,2)) / q.quatern_d ;
    end
    if( qa < 0.0 ) q.quatern_b=-q.quatern_b ; q.quatern_c=-q.quatern_c ; q.quatern_d=-q.quatern_d; qa=-qa; end
end

return
