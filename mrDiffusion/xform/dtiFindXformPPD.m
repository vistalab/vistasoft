function R = dtiXformTensorsPPD2(img,V) %Current iteration image (img) and displacements (V)
% R = dtiXformTensorsPPD2(img,V)
% 
% Implementation of Alexander's preservation of principle direction algorithm. 
% Eg: Spatial Transformations of Diffusion Tensor Magnetic Resonance Images
% Alexander, et. al. IEEE Trans. Med. Imag 20:11 1131-1139(2001).
%
%
% INPUTS:
% img: Diffusion tensor image in DT6 format, size XxYxZx6
% V: Deformation field of voxel displacements 
%
% RETURNS:
% R: Rotation matricies for voxel-by-voxel to preserve principle directions
%
% NOTE: Use dtiXformTensorsPPD to apply transforms
%
% 
% HISTORY:
%   2004.11.10 GSM (gmulye@stanford.edu) wrote it.
delV = jacobian(V);
dimDelV = size(delV);
identity = zeros(dimDelV);
identity(:,:,:,1,1) = 1;identity(:,:,:,2,2) = 1;identity(:,:,:,3,3) = 1;
F = identity + delV; %F = I + Jv - use F to find our n1, n2  %%%IDENTITY OR ONES MATRIX???
[imgEigVec imgEigVal] = dtiSplitTensor(img); %Eigenvectors/values of image (v)

%NOTE: v1 = imgEigVec(:,:,:,:,1) and v2 = imgEigVec(:,:,:,:,2)
%n1 = F*v1 
n1 = zeros([dimDelV(1:3),3]);
n1(:,:,:,1) = F(:,:,:,1,1).*imgEigVec(:,:,:,1,1) + F(:,:,:,1,2).*imgEigVec(:,:,:,2,1) + F(:,:,:,1,3).*imgEigVec(:,:,:,3,1);
n1(:,:,:,2) = F(:,:,:,2,1).*imgEigVec(:,:,:,1,1) + F(:,:,:,2,2).*imgEigVec(:,:,:,2,1) + F(:,:,:,2,3).*imgEigVec(:,:,:,3,1); 
n1(:,:,:,3) = F(:,:,:,3,1).*imgEigVec(:,:,:,1,1) + F(:,:,:,3,2).*imgEigVec(:,:,:,2,1) + F(:,:,:,3,3).*imgEigVec(:,:,:,3,1); 
%norm(n1)
normN1 = sqrt(n1(:,:,:,1).^2 + n1(:,:,:,2).^2 + n1(:,:,:,3).^2);
normN1 = normN1 + (normN1 == 0);
n1(:,:,:,1) = n1(:,:,:,1)./normN1;
n1(:,:,:,2) = n1(:,:,:,2)./normN1;
n1(:,:,:,3) = n1(:,:,:,3)./normN1;

%n2 = F*v2
n2 = zeros([dimDelV(1:3),3]);
n2(:,:,:,1) = F(:,:,:,1,1).*imgEigVec(:,:,:,1,2) + F(:,:,:,1,2).*imgEigVec(:,:,:,2,2) + F(:,:,:,1,3).*imgEigVec(:,:,:,3,2);
n2(:,:,:,2) = F(:,:,:,2,1).*imgEigVec(:,:,:,1,2) + F(:,:,:,2,2).*imgEigVec(:,:,:,2,2) + F(:,:,:,2,3).*imgEigVec(:,:,:,3,2); 
n2(:,:,:,3) = F(:,:,:,3,1).*imgEigVec(:,:,:,1,2) + F(:,:,:,3,2).*imgEigVec(:,:,:,2,2) + F(:,:,:,3,3).*imgEigVec(:,:,:,3,2); 

%DERIVING ROTATION MATRIX 1 (R1)
%r = vector product of v1 and n1
r = cross(imgEigVec(:,:,:,:,1),n1); 
%Normalizing r --> r = r/norm(r)
normR = sqrt(r(:,:,:,1).^2 + r(:,:,:,2).^2 + r(:,:,:,3).^2);
normR = normR + (normR == 0);
x = r(:,:,:,1) ./ normR;
y = r(:,:,:,2) ./ normR;
z = r(:,:,:,3) ./ normR;

%Scalar product of v1,n1
v1DotN1 = n1(:,:,:,1).*imgEigVec(:,:,:,1,1) + n1(:,:,:,2).*imgEigVec(:,:,:,2,1) + n1(:,:,:,3).*imgEigVec(:,:,:,3,1);

%phi = arccos[v1'*n1/(norm(n1)*norm(v1))]
phi = real(acos(v1DotN1./normN1)); %Need the real part to ignore nonsense small (order of 10^-7) imaginary angles

%Finding R1 using axis r and angle of rotation phi
%http://www.euclideanspace.com/maths/algebra/matrix/orthogonal/rotation/
R1 = zeros([dimDelV(1:3),3,3]);
R1(:,:,:,1,1) = 1+(1-cos(phi)).*(x.*x-1);
R1(:,:,:,1,2) = -z.*sin(phi)+(1-cos(phi)).*x.*y;
R1(:,:,:,1,3) = y.*sin(phi)+(1-cos(phi)).*x.*z;
R1(:,:,:,2,1) = z.*sin(phi)+(1-cos(phi)).*x.*y;
R1(:,:,:,2,2) = 1+(1-cos(phi)).*(y.*y-1); 
R1(:,:,:,2,3) = -x.*sin(phi)+(1-cos(phi)).*y.*z;
R1(:,:,:,3,1) = -y.*sin(phi)+(1-cos(phi)).*x.*z; 
R1(:,:,:,3,2) = x.*sin(phi)+(1-cos(phi)).*y.*z; 
R1(:,:,:,3,3) = 1+(1-cos(phi)).*(z.*z-1);




%DERIVING ROTATION MATRIX 2, R2
%R1v2 = R1*v2
R1v2 = zeros([dimDelV(1:3),3]);
R1v2(:,:,:,1) = R1(:,:,:,1,1).*imgEigVec(:,:,:,1,2) + R1(:,:,:,1,2).*imgEigVec(:,:,:,2,2) + R1(:,:,:,1,3).*imgEigVec(:,:,:,3,2);
R1v2(:,:,:,2) = R1(:,:,:,2,1).*imgEigVec(:,:,:,1,2) + R1(:,:,:,2,2).*imgEigVec(:,:,:,2,2) + R1(:,:,:,2,3).*imgEigVec(:,:,:,3,2); 
R1v2(:,:,:,3) = R1(:,:,:,3,1).*imgEigVec(:,:,:,1,2) + R1(:,:,:,3,2).*imgEigVec(:,:,:,2,2) + R1(:,:,:,3,3).*imgEigVec(:,:,:,3,2); 

%Projecting n2 onto n1-n2 plane: P(n2) = Pn2 = n2 - (n2*n1')*n1
Pn2 = zeros([dimDelV(1:3),3]);
%temp = (n2*n1)*n1, so Pn2 = n2 - temp
tempTemp = n1(:,:,:,1).*n2(:,:,:,1) + n1(:,:,:,2).*n2(:,:,:,2) + n1(:,:,:,3).*n2(:,:,:,3);
temp = zeros([dimDelV(1:3),3]);
temp(:,:,:,1) = tempTemp .* n1(:,:,:,1);
temp(:,:,:,2) = tempTemp .* n1(:,:,:,2);
temp(:,:,:,3) = tempTemp .* n1(:,:,:,3);
Pn2 = n2 - temp;
normPn2 = sqrt(Pn2(:,:,:,1).^2 + Pn2(:,:,:,2).^2 + Pn2(:,:,:,3).^2);
normPn2 = normPn2 + (normPn2 == 0); %If any norm(Pn2) = 0, changes to 1
Pn2(:,:,:,1) = Pn2(:,:,:,1)./normPn2;
Pn2(:,:,:,2) = Pn2(:,:,:,2)./normPn2;
Pn2(:,:,:,3) = Pn2(:,:,:,3)./normPn2;

%Axis of rotation for R1v2 (2nd eigenvector rotated with rot matrix 1) is principle direction of rotated tensor
r2 = n1; 
x = r2(:,:,:,1);
y = r2(:,:,:,2);
z = r2(:,:,:,3);

%phi2 = acos(R1v2'*Pn2/(norm(R1v2)*norm(Pn2))) - angle of rotation using scalar product
%Scalar product of v1,n1
R1v2DotPn2 = R1v2(:,:,:,1).*Pn2(:,:,:,1) + R1v2(:,:,:,2).*Pn2(:,:,:,2) + R1v2(:,:,:,3).*Pn2(:,:,:,3);
phi2 = real(acos(R1v2DotPn2)); %Need the real part to ignore nonsense small (order of 10^-7) imaginary angles

%Finding R2 using axis r2 and angle of rotation phi2
R2 = zeros([dimDelV(1:3),3,3]);
R2(:,:,:,1,1) = 1+(1-cos(phi2)).*(x.*x-1);
R2(:,:,:,1,2) = -z.*sin(phi2)+(1-cos(phi2)).*x.*y;
R2(:,:,:,1,3) = y.*sin(phi2)+(1-cos(phi2)).*x.*z;
R2(:,:,:,2,1) = z.*sin(phi2)+(1-cos(phi2)).*x.*y;
R2(:,:,:,2,2) = 1+(1-cos(phi2)).*(y.*y-1); 
R2(:,:,:,2,3) = -x.*sin(phi2)+(1-cos(phi2)).*y.*z;
R2(:,:,:,3,1) = -y.*sin(phi2)+(1-cos(phi2)).*x.*z; 
R2(:,:,:,3,2) = x.*sin(phi2)+(1-cos(phi2)).*y.*z; 
R2(:,:,:,3,3) = 1+(1-cos(phi2)).*(z.*z-1);


%FINAL ROTATION MATRIX R = R2*R1
R = zeros([dimDelV(1:3),3,3]);
R(:,:,:,1,1) = R2(:,:,:,1,1).*R1(:,:,:,1,1) + R2(:,:,:,1,2).*R1(:,:,:,2,1) + R2(:,:,:,1,3).*R1(:,:,:,3,1);
R(:,:,:,1,2) = R2(:,:,:,1,1).*R1(:,:,:,1,2) + R2(:,:,:,1,2).*R1(:,:,:,2,2) + R2(:,:,:,1,3).*R1(:,:,:,3,2);
R(:,:,:,1,3) = R2(:,:,:,1,1).*R1(:,:,:,1,3) + R2(:,:,:,1,2).*R1(:,:,:,2,3) + R2(:,:,:,1,3).*R1(:,:,:,3,3);
R(:,:,:,2,1) = R2(:,:,:,2,1).*R1(:,:,:,1,1) + R2(:,:,:,2,2).*R1(:,:,:,2,1) + R2(:,:,:,2,3).*R1(:,:,:,3,1);
R(:,:,:,2,2) = R2(:,:,:,2,1).*R1(:,:,:,1,2) + R2(:,:,:,2,2).*R1(:,:,:,2,2) + R2(:,:,:,2,3).*R1(:,:,:,3,2);
R(:,:,:,2,3) = R2(:,:,:,2,1).*R1(:,:,:,1,3) + R2(:,:,:,2,2).*R1(:,:,:,2,3) + R2(:,:,:,2,3).*R1(:,:,:,3,3);
R(:,:,:,3,1) = R2(:,:,:,3,1).*R1(:,:,:,1,1) + R2(:,:,:,3,2).*R1(:,:,:,2,1) + R2(:,:,:,3,3).*R1(:,:,:,3,1);
R(:,:,:,3,2) = R2(:,:,:,3,1).*R1(:,:,:,1,2) + R2(:,:,:,3,2).*R1(:,:,:,2,2) + R2(:,:,:,3,3).*R1(:,:,:,3,2);
R(:,:,:,3,3) = R2(:,:,:,3,1).*R1(:,:,:,1,3) + R2(:,:,:,3,2).*R1(:,:,:,2,3) + R2(:,:,:,3,3).*R1(:,:,:,3,3);

function J = jacobian(vectorField)
%Approximates Jacobian of a vector field - each voxel has an associated 3x3 jacobian
dim = size(vectorField);
J = zeros(dim(1),dim(2),dim(3),3,3);
for i = 1:3 %Approximates gradients one tensor value at a time
    [gradX,gradY,gradZ] = gradient(vectorField(:,:,:,i),1);  
    J(:,:,:,i,1) = -gradY; 
    J(:,:,:,i,2) = -gradX; 
    J(:,:,:,i,3) = -gradZ;
end
return
  
  







