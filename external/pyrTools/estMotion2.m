function [M,w2d] = estMotion2(im1,im2,rotFlag,robustFlag,CB,SC)
%
% function [M,w] = estMotion2(im1,im2,rotFlag,robustFlag)
%
% im1 and im2 are images
%
% M is 3x3 transform matrix: X' = M X
% where X=(x,y,1) is starting position in homogeneous coords
% and X'=(x',y',1) is ending position
%
% If rotFlag is activated (~=0), then M is a rotation+translation,
% otherwise, is a general affine transform
%
% Solves fs^t theta + ft = 0
% where theta = B p is image velocity at each pixel
%       B is 2x3 (2x6 if affine) matrix that depends on image positions
%       p is vector of trans+rot (or affine) motion parameters
%       fs is vector of spatial derivatives at each pixel
%       ft is temporal derivative at each pixel
% Mulitplying fs^t B gives a 1x3 (1x6 if affine) vector for each pixel.  Piling
% these on top of one another gives A, an Nx3 (Nx6 if affine) matrix, where N is
% the number of pixels.  Solve M p = ft where ft is now an Nx1
% vector of the the temporal derivatives at every pixel.
%
% If robustFlag is activated (~=0) then uses a robust M-estimator instead of
% conventional Least Squares
%

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

[fx,fy,ft]=computeDerivatives2(im1,im2);
[xgrid,ygrid]=meshgrid(1:size(im1,2),1:size(im1,1));

% subsample
dims=size(fx);
fx=fx([1:2:dims(1)],[1:2:dims(2)]);
fy=fy([1:2:dims(1)],[1:2:dims(2)]);
ft=ft([1:2:dims(1)],[1:2:dims(2)]);
% *** Assumes that the filters have 5 taps!
xgrid=xgrid([3:2:dims(1)+2],[3:2:dims(2)+2]);
ygrid=ygrid([3:2:dims(1)+2],[3:2:dims(2)+2]);

dimsS=size(fx);
pts=find(~isnan(fx));
pts=find((~isnan(fx))&(~isnan(fy))&(~isnan(ft)));
fx = fx(pts);
fy = fy(pts);
ft = ft(pts);
xgrid = xgrid(pts);
ygrid = ygrid(pts);

if rotFlag
	A= [ fx(:), fy(:), xgrid(:).*fy(:)-ygrid(:).*fx(:)];
else
	A= [xgrid(:).*fx(:), ygrid(:).*fx(:), fx(:),...
    	    xgrid(:).*fy(:), ygrid(:).*fy(:), fy(:)];
end
b = -ft(:);

if robustFlag
	[p w] = robustMest(A,b,CB,SC);
	w2d = zeros(dimsS);
	w2d(pts)=w;	
else
	p = A\b;
	w2d = [];
end

if rotFlag
	M= [cos(p(3))  -sin(p(3)) p(1);
    	    sin(p(3))  cos(p(3))  p(2);
    	    0     0    1];
else
	M= [1+p(1) p(2)   p(3);
    	    p(4)   1+p(5) p(6);
    	    0      0      1];
end

return;

%%%%%%%%%
% Debug %
%%%%%%%%%

% test with translation
dims=[64 64];
im1=rand(dims);
im2=circularShift(im1,1,0);
% default - rot and LS
estMotion2(im1,im2)
% rot and robust
estMotion2(im1,im2,1,1)
% affine and LS
estMotion2(im1,im2,0,0)
% affine and robust
estMotion2(im1,im2,0,1)

dims=[64 64];
im1=rand(dims);
A= [1 0 .5;
    0 1 .5;
    0 0 1];
im2=warpAffine2(im1,A);
% default - rot and LS
estMotion2(im1,im2)
% rot and robust
estMotion2(im1,im2,1,1)
% affine and LS
estMotion2(im1,im2,0,0)
% affine and robust
estMotion2(im1,im2,0,1)

% test with rotation
dims=[64 64];
in=rand(dims);
theta=atan2(1,max(dims));
A1=[cos(theta) sin(theta) 0;
    -sin(theta) cos(theta) 0;
    0 0 1];
A2=inv(A1);
im1=warpAffine2(in,A1);
im2=warpAffine2(in,A2);
A1*A1
% default - rot and LS
estMotion2(im1,im2)
% rot and robust
estMotion2(im1,im2,1,1)
% affine and LS
estMotion2(im1,im2,0,0)
% affine and robust
estMotion2(im1,im2,0,1)


dims=[64 64];
im1=rand(dims);
A= [1 0 .5;
    0 1 .5;
    0 0 1];
im2=warpAffine2(im1,A);
% default - rot and LS
estMotion2(im1,im2)
% rot and robust
estMotion2(im1,im2,1,1)
% affine and LS
estMotion2(im1,im2,0,0)
% affine and robust
estMotion2(im1,im2,0,1)

%%%%%%%%%%%%%%%%%%%%
% test with outliers
%%%%%%%%%%%%%%%%%%%%

% translation
dims=[64 64];
im1=rand(dims);
A= [1 0 .5;
    0 1 .5;
    0 0 1];
im2=warpAffine2(im1,A);
% putting inconsistent information in upper left corner of im2
Nc=3;
im2(1:round(dims(1)/Nc), 1:round(dims(2)/Nc)) = rand(round(dims(1)/Nc), round(dims(2)/Nc));
% default - rot and LS
ArotLS = estMotion2(im1,im2);
% rot and robust
[ArotRob wr] = estMotion2(im1,im2,1,1);
% affine and LS
AaffLS = estMotion2(im1,im2,0,0);
% affine and robust
[AaffRob wa] = estMotion2(im1,im2,0,1);
ArotLS
ArotRob
AaffLS
AaffRob
imagesc([wr wa]); colormap(gray);axis('image');axis('off')

% test with rotation
dims=[64 64];
in=rand(dims);
theta=atan2(1,max(dims));
A1=[cos(theta) sin(theta) 0;
    -sin(theta) cos(theta) 0;
    0 0 1];
A2=inv(A1);
im1=warpAffine2(in,A1);
im2=warpAffine2(in,A2);
% putting inconsistent information in upper left corner of im2
Nc=3;
im2(1:round(dims(1)/Nc), 1:round(dims(2)/Nc)) = rand(round(dims(1)/Nc), round(dims(2)/Nc));
% default - rot and LS
ArotLS = estMotion2(im1,im2);
% rot and robust
[ArotRob wr] = estMotion2(im1,im2,1,1);
% affine and LS
AaffLS = estMotion2(im1,im2,0,0);
% affine and robust
[AaffRob wa] = estMotion2(im1,im2,0,1);
A=A1*A1
ArotLS
ArotRob
AaffLS
AaffRob
imagesc([wr wa]); colormap(gray);axis('image');axis('off')




