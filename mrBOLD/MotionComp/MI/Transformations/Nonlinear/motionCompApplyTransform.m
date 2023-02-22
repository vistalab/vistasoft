function Tnew = motionCompApplyTransform(T, deformX, deformY, deformZ)
%
%    newImg = motionCompApplyTransform(T, deformX, deformY, deformZ)
%
% gb 02/09/05
% 
% Apply the transformation deformField to the image T

% Size of T
[m,n,o,c] = size(T);

% Sets size of pad
pad = 25;

% Initializes T and the Deformfation Field with pad
TLuebeck = zeros(m + 2*pad,n + 2*pad,o + 2*pad,c);
ux       = zeros(m + 2*pad,n + 2*pad,o + 2*pad);
uy       = zeros(m + 2*pad,n + 2*pad,o + 2*pad);
uz       = zeros(m + 2*pad,n + 2*pad,o + 2*pad);

% Extracts the components of the Deformation Field
ux(1 + pad:m + pad,1 + pad:n + pad,1 + pad:o + pad) = deformX;
uy(1 + pad:m + pad,1 + pad:n + pad,1 + pad:o + pad) = deformY;
uz(1 + pad:m + pad,1 + pad:n + pad,1 + pad:o + pad) = deformZ;

% Converts data
if size(T,4) == 6
    TLuebeck(1 + pad:m + pad,1 + pad:n + pad,1 + pad:o + pad,:) = dti3dStanford2dti3d(T);
else
    TLuebeck(1 + pad:m + pad,1 + pad:n + pad,1 + pad:o + pad,:) = T;
end

% Applies tranformation
% Linear version
% TnewLuebeck = trilin(TLuebeck,ux,uy,uz);

% spline interpolation order 7
TnewLuebeck = motionCompInterpolate(TLuebeck,ux,uy,uz,7);

% Converts data
if c == 6
    Tnew = dti3d2dti3dStanford(TnewLuebeck(1 + pad:m + pad,1 + pad:n + pad,1 + pad:o + pad,:));
else
    Tnew = TnewLuebeck(1 + pad:m + pad,1 + pad:n + pad,1 + pad:o + pad,:);
end