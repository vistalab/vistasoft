function outDt6 = dtiXformTensorsPPD(dt6,F,invDef)
% outDt6 = dtiXformTensorsPPD(inDt6,F,invDef)
%   Reorients DTIs using Preservation of Principal Direction (PPD) method.
%   See: Alexander et al, IEEE Trans Medical Imaging, Vol 20, No. 11, Nov 2001
%
% INPUT:
%   inDt6   XxYxZx6 dt6 array
%   F       A single 3x3 deformation matrix or a XxYxZx3x3 field of deformation
%           matrices or a XxYxZx3 matrix of voxel-by-voxel deformation field. 
%           If the matrix includes an affine portion in the 4th column
%           (i.e. 4x4 instead of 3x3) then the 4th column is ignored.
%   invDef  If set to 1, applies inverse of rotation matrices calculated
%           (default 0 - applies rotation matricies normally)
%
% OUTPUT:
%   outDt6  XxYxZx6 field of output DTs.
%
% HISTORY:
% 2004.08.06 RFD & ASH wrote it based on code from Mathias Bolten
% 2004.09.10 ASH vectorized function for speed
% 2004.09.15 ASH rewrote code entirely using Rodrigues' formula
%            See: http://mathworld.wolfram.com/RodriguesRotationFormula.html
% 2005.01.24 GSM added code to accept deformation fields and automatically
%            reorient tensors

% Debugging:
% dt = dtiLoadTensorSubjects('c', 'dt6')
% dt6 = dt.dt6(:,:,:,:,4);
% F = eye(3); F(1:2,1:2) = [cos(0.5) -sin(0.5); sin(0.5) cos(0.5)];

%--------------------------------------------------------------------------
% Process input
if(~exist('invDef','var'))
    invDef = 0;
end
dt6(isnan(dt6)) = 0;
F(isnan(F)) = 0;
[nx,ny,nz,n6] = size(dt6);
if (n6~=6), error('Wrong dt6 input format'), end

if (ndims(F) == 4) %Means F passed in is a deformation field --< convert to XxYxZx3x3 matrix
    delV = jacobian(F);
    dimDelV = size(delV);
    identity = zeros(dimDelV);
    identity(:,:,:,1,1) = 1;identity(:,:,:,2,2) = 1;identity(:,:,:,3,3) = 1;
    F = identity + delV; 
end

if (ndims(F)>2)
    F = permute(F, [4 5 1:3]);
elseif (ndims(F)~=2),
    error('Wrong F input format')
end

if(size(F,1)>3)
    F = F(1:3,1:3,:);
end
[eigVec, eigVal] = dtiSplitTensor(dt6);
A = permute(dti6to33(dt6), [4 5 1:3]);

% Apply PPD method
e1 = permute(eigVec(:,:,:,:,1), [4 5 1:3]);
e2 = permute(eigVec(:,:,:,:,2), [4 5 1:3]);
n1 = ndfun('mult', F, e1);
n1 = unitnorm(n1);
n2 = ndfun('mult', F,e2);
n2 = unitnorm(n2);
costheta1 = dot(e1, n1, 1);
costheta1(abs(costheta1) > 1) = 1;  % saturation just in case precision overflow
theta1 = acos(costheta1);
r = cross(e1, n1, 1);
r = unitnorm(r);
R1 = rodrigues(r, theta1);

Pn2 = n2 - repmat(dot(n2, n1, 1), [3 1 1 1 1]) .* n1;
Pn2 = unitnorm(Pn2);
R1e2 = ndfun('mult', R1, e2);
costheta2 = dot(R1e2, Pn2, 1);
costheta2(abs(costheta2) > 1) = 1;  % saturation just in case precision overflow
theta2 = acos(costheta2);
r = cross(R1e2, Pn2, 1);
r = unitnorm(r);
R2 = rodrigues(r, theta2);

R = ndfun('mult', R2, R1);
if (invDef == 1)
    invR = ndfun('inv',R);
    A = ndfun('mult', ndfun('mult', invR, A), permute(invR,[2 1 3:5]));
else
    A = ndfun('mult', ndfun('mult', R, A), permute(R,[2 1 3:5]));
end
outDt6 = dti33to6(permute(A,[3:5 1 2]));

return

%--------------------------------------------------------------------------
function u = unitnorm(x)

normx = sqrt(sum(abs(x).^2));
normx(normx == 0) = 1;          % avoid divison by zero
u = x ./ repmat(normx, [3 1]);

return

%--------------------------------------------------------------------------
function R = rodrigues(r, theta)

o = zeros(size(theta));
W = [o              -r(3,1,:,:,:)   r(2,1,:,:,:);
     r(3,1,:,:,:)   o               -r(1,1,:,:,:);
     -r(2,1,:,:,:)  r(1,1,:,:,:)    o           ];
R = repmat(eye(3), size(theta)) + W.*repmat(sin(theta),[3 3]) + ...
    ndfun('mult', W, W).*repmat(1-cos(theta), [3 3]);

return

%--------------------------------------------------------------------------
function J = jacobian(vectorField)
%Approximates Jacobian of a vector field - each voxel has an associated 3x3 jacobian
dim = size(vectorField);
J = zeros(dim(1),dim(2),dim(3),3,3);
for i = 1:3 %Approximates gradients one tensor value at a time
    [gradX,gradY,gradZ] = gradient(vectorField(:,:,:,i),1);  
    J(:,:,:,i,1) = gradY; 
    J(:,:,:,i,2) = gradX; 
    J(:,:,:,i,3) = gradZ;
end
return