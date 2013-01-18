function [M,w3d] = estMotion3(vol1,vol2,rotFlag,robustFlag,CB,SC)
%
% function [M,w] = estMotion3(vol1,vol2,rotFlag,robustFlag)
%
% vol1 and vol2 are volumes, 3d arrays
%
% M is 4x4 (rotation+translation) transform matrix: X' = M X
% where X=(x,y,z,1) is starting position in homogeneous coords
% and X'=(x',y',z',1) is ending position
%
% If rotFlag is activated (~=0), then M is a rotation+translation,
% otherwise, is a general affine transform
%
% Solves fs^t theta + ft = 0
% where theta = B p is image velocity at each pixel
%       B is 3x6 (3x12 if affine) matrix that depends on image positions
%       p is vector of trans+rot (or affine) motion parameters
%       fs is vector of spatial derivatives at each pixel
%       ft is temporal derivative at each pixel
% Mulitplying fs^t B gives a 1x6 (1x12 if affine) vector for each pixel.  Piling
% these on top of one another gives A, an Nx6 (Nx12 if affine) matrix, where N is
% the number of pixels.  Solve M p = -ftVol where ftVol is an Nx1
% vector of the the temporal derivatives at every pixel.
%
% If robustFlag is activated (~=0) then uses a robust M-estimator instead of
% conventional Least Squares
%

% ON 08/00 - modified to permit registration of complex valued volumes

% default values
if ~exist('robustFlag')
  robustFlag = 0;
end
if ~exist('rotFlag')
  rotFlag = 1;
end
if ~exist('CB')
  CB = [];
end
if ~exist('SC')
  SC = [];
end

[fxVol,fyVol,fzVol,ftVol]=computeDerivatives3(vol1,vol2);
numSlices=size(fxVol,3);
[xgrid,ygrid,zgrid]=meshgrid(1:size(vol1,2),1:size(vol1,1),1:size(vol1,3));

% subsample
dims=size(fxVol);
fxVol=fxVol([1:2:dims(1)],[1:2:dims(2)],:);
fyVol=fyVol([1:2:dims(1)],[1:2:dims(2)],:);
fzVol=fzVol([1:2:dims(1)],[1:2:dims(2)],:);
ftVol=ftVol([1:2:dims(1)],[1:2:dims(2)],:);
% *** Assumes that the filters have 5 taps!
xgrid=xgrid([3:2:dims(1)+2],[3:2:dims(2)+2],[3:dims(3)+2]);
ygrid=ygrid([3:2:dims(1)+2],[3:2:dims(2)+2],[3:dims(3)+2]);
zgrid=zgrid([3:2:dims(1)+2],[3:2:dims(2)+2],[3:dims(3)+2]);

dimsS=size(fxVol);
pts=find((~isnan(fxVol))&(~isnan(fyVol))&(~isnan(fzVol))&(~isnan(ftVol)));
%disp(['numPts=',num2str(length(pts))]);
fxVol = fxVol(pts);
fyVol = fyVol(pts);
fzVol = fzVol(pts);
ftVol = ftVol(pts);
xVol=xgrid(pts);
yVol=ygrid(pts);
zVol=zgrid(pts);

if rotFlag
	A = [fxVol(:),  fyVol(:), fzVol(:),...
	     fzVol(:).*yVol(:)-fyVol(:).*zVol(:) ...
             fxVol(:).*zVol(:)-fzVol(:).*xVol(:)...
	     fyVol(:).*xVol(:)-fxVol(:).*yVol(:)];
else
	A= [xVol(:).*fxVol(:), yVol(:).*fxVol(:), zVol(:).*fxVol(:), fxVol(:),...
    	    xVol(:).*fyVol(:), yVol(:).*fyVol(:), zVol(:).*fyVol(:), fyVol(:),...
    	    xVol(:).*fzVol(:), yVol(:).*fzVol(:), zVol(:).*fzVol(:), fzVol(:)];
end

b = -ftVol(:);

% this modification allows to solve for complex valued volumes
% because the motion parameters must be real, it is equivalent to consider
% that the imaginary part is adding new constraints
complexFlag = (~isreal(A))|(~isreal(b));
if complexFlag
   A = [real(A); imag(A)];
   b = [real(b); imag(b)];
end

if robustFlag
   [p w] = robustMest(A,b,CB,SC);
   if complexFlag
      % rearrange the weights and return them in complex form
      w = w(1:length(w)/2) + sqrt(-1) * w(length(w)/2+1:end);
   end
   w3d = zeros(dimsS);
	w3d(pts)=w;	
else
	p = A\b;
	w3d = [];
end

if rotFlag
        M = [quatR2mat(quatrot(p(4:6))) p(1:3); 0 0 0 1];
else
	M= [1+p(1)  p(2)   p(3)   p(4);
	    p(5)   1+p(6)  p(7)   p(8);
	    p(9)    p(10) 1+p(11) p(12);
	     0       0     0      1];
end

return;

%%%%%%%%%
% Debug %
%%%%%%%%%

% test with translation
vol1=rand(16,16,9);
%theta=[1 0 0];
%theta=[0 1 0];
theta=[0 0 1];
vol2=circularShift3(vol1,theta);
% default - rot and LS
estMotion3(vol1,vol2)
% rot and robust
estMotion3(vol1,vol2,1,1)
% affine and LS
estMotion3(vol1,vol2,0,0)
% affine and robust
estMotion3(vol1,vol2,0,1)

in=rand(30,32,9);
A= [1 0 0 .2;
    0 1 0 .3;
    0 0 1 .4;
    0 0 0 1];
vol1=warpAffine3(in,A);
vol2=warpAffine3(in,inv(A));
A*A
% default - rot and LS
estMotion3(vol1,vol2)
% rot and robust
estMotion3(vol1,vol2,1,1)
% affine and LS
estMotion3(vol1,vol2,0,0)
% affine and robust
estMotion3(vol1,vol2,0,1)

% test with rotation
in=rand(30,32,9);
theta=.02;
A1=[cos(theta) sin(theta) 0 0;
    -sin(theta) cos(theta) 0 0;
    0 0 1 0;
    0 0 0 1];
A2=inv(A1);
vol1=warpAffine3(in,A1);
vol2=warpAffine3(in,A2);
A1*A1
% default - rot and LS
estMotion3(vol1,vol2)
% rot and robust
estMotion3(vol1,vol2,1,1)
% affine and LS
estMotion3(vol1,vol2,0,0)
% affine and robust
estMotion3(vol1,vol2,0,1)


%%%%%%%%%%%%%%%%%%%%
% test with outliers
%%%%%%%%%%%%%%%%%%%%

% translation
dims=[30,32,9];
in=rand(dims);
A= [1 0 0 .2;
    0 1 0 .3;
    0 0 1 .4;
    0 0 0 1];
vol1=warpAffine3(in,A);
vol2=warpAffine3(in,inv(A));
% putting inconsistent information in upper left corner of vol2
Nc=3;
vol2(1:round(dims(1)/Nc), 1:round(dims(2)/Nc), :) = ...
			rand(round(dims(1)/Nc), round(dims(2)/Nc), dims(3));
% default - rot and LS
ArotLS = estMotion3(vol1,vol2);
% rot and robust
[ArotRob wr] = estMotion3(vol1,vol2,1,1);
% affine and LS
AaffLS = estMotion3(vol1,vol2,0,0);
% affine and robust
[AaffRob wa] = estMotion3(vol1,vol2,0,1);
ArotLS
ArotRob
AaffLS
AaffRob
dimw = size(wr);
imagesc([reshape(wr,[dimw(1) dimw(2)*dimw(3)]); reshape(wa,[dimw(1) dimw(2)*dimw(3)])]);
colormap(gray);axis('image');axis('off')

% test with rotation
dims = [30, 32, 9];
in=rand(dims);
theta=.02;
A1=[cos(theta) sin(theta) 0 0;
    -sin(theta) cos(theta) 0 0;
    0 0 1 0;
    0 0 0 1];
A2=inv(A1);
vol1=warpAffine3(in,A1);
vol2=warpAffine3(in,A2);
% putting inconsistent information in upper left corner of vol2
Nc=3;
vol2(1:round(dims(1)/Nc), 1:round(dims(2)/Nc), :) = ...
			rand(round(dims(1)/Nc), round(dims(2)/Nc), dims(3));
% default - rot and LS
ArotLS = estMotion3(vol1,vol2);
% rot and robust
[ArotRob wr] = estMotion3(vol1,vol2,1,1);
% affine and LS
AaffLS = estMotion3(vol1,vol2,0,0);
% affine and robust
[AaffRob wa] = estMotion3(vol1,vol2,0,1);
A1*A1
ArotLS
ArotRob
AaffLS
AaffRob
dimw = size(wr);
imagesc([reshape(wr,[dimw(1) dimw(2)*dimw(3)]); reshape(wa,[dimw(1) dimw(2)*dimw(3)])]);
colormap(gray);axis('image');axis('off')
