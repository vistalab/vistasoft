function M = estMotionIter2(im1,im2,numIters,Minitial,rotFlag,robustFlag,CB,SC)
%
% function M = estMotionIter2(im1,im2,numIters,Minitial,rotFlag,robustFlag)
%
% im1 and im2 are input images
% numIters is number of iterations to run
% Minitial is initial guess for M.  Default is 3x3 identity matrix.
%
% M is 3x3 translation+rotation or affine transform matrix: X' = M X
% where X=(x,y,1) is starting position in homogeneous coords
% and X'=(x',y'',1) is ending position
%
% Each iteration warps the images according to the previous
% estimate, and estimates the residual motion.
%
% robustFlag is passed to estMotion2 (if activated, uses robust M-estimator)
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

if ~exist('numIters')
  numIters=3;
elseif isempty(numIters)
  numIters=3;
end

if ~exist('Minitial')
  M=estMotion2(im1,im2,rotFlag,robustFlag,CB,SC);
elseif isempty(Minitial)
  M=estMotion2(im1,im2,rotFlag,robustFlag,CB,SC);
else
  M=Minitial;
end
%disp(['iter=0']);
%disp(M);

for iter=1:numIters
  Mhalf2=real(sqrtm(M));
  Mhalf2=Mhalf2(1:3,:);
  Mhalf1=real(sqrtm(inv(M)));
  Mhalf1=Mhalf1(1:3,:);
  imWarp1=warpAffine2(im1,Mhalf1);
  imWarp2=warpAffine2(im2,Mhalf2);
  deltaM=estMotion2(imWarp1,imWarp2,rotFlag,robustFlag,CB,SC);
  M=deltaM*M;
  %disp(['iter=',num2str(iter)]);
  %disp(M);
end

return;

%%%%%%%%%
% Debug %
%%%%%%%%%
Niter=3;

dims=[256 96];
in=rand(dims);
theta=atan2(1,max(dims));
A1=[cos(theta) sin(theta) 0;
    -sin(theta) cos(theta) 0;
    0 0 1];
A2=inv(A1);
im1=warpAffine2(in,A1);
im2=warpAffine2(in,A2);
A=A1*A1
% default - rot and LS
ArotLS = estMotionIter2(im1,im2,Niter);
% rot and robust
ArotRob = estMotionIter2(im1,im2,Niter,[],1,1);
% affine and LS
AaffLS = estMotionIter2(im1,im2,Niter,[],0,0);
% affine and robust
AaffRob = estMotionIter2(im1,im2,Niter,[],0,1);
A
ArotLS
ArotRob
AaffLS
AaffRob

%%%%%%%%%%%%%%%%%%%%
% test with outliers
%%%%%%%%%%%%%%%%%%%%

dims=[256 96];
in=rand(dims);
theta=atan2(1,max(dims));
A1=[cos(theta) sin(theta) 0;
    -sin(theta) cos(theta) 0;
    0 0 1];
A2=inv(A1);
im1=warpAffine2(in,A1);
im2=warpAffine2(in,A2);
A1*A1
% putting inconsistent information in upper left corner of im2
Nc=3;
im2(1:round(dims(1)/Nc), 1:round(dims(2)/Nc)) = rand(round(dims(1)/Nc), round(dims(2)/Nc));
A=A1*A1
% default - rot and LS
ArotLS = estMotionIter2(im1,im2,Niter);
% rot and robust
ArotRob = estMotionIter2(im1,im2,Niter,[],1,1);
% affine and LS
AaffLS = estMotionIter2(im1,im2,Niter,[],0,0);
% affine and robust
AaffRob = estMotionIter2(im1,im2,Niter,[],0,1);
A
ArotLS
ArotRob
AaffLS
AaffRob

