function M = estMotionMulti2(im1,im2,iters,Minitial,rotFlag,robustFlag,CB,SC)
%
% function  M = estMotionMulti2(im1,im2,iters,Minitial,rotFlag,robustFlag)
%
% im1 and im2 are input images
% iters is vector of number of iterations to run at each
%   successive scale. default is: [3] that runs 3 iterations at
%   the base scale.
% Minitial is initial guess for M.  Default is 3x3 identity matrix.
% 
% This function calls itself recursively.
%
% M is 3x3 translation+rotation transform matrix (in homogeneous coordinates)
%          or affine transform matrix
%
% Uses least-squares or robust M-estimation depending on robustFlag
%
% Bugs and limitations:
% - should check that images are big enough for requested number
%   of levels. 
%
% Author: David Heeger
%
% 7/30/97  dhb, eah  Special case iters(1) == 0 to allow 
%                    specification of not doing finest scales.

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

if ~exist('iters')
  iters=[3];
elseif isempty(iters)
  iters=[3];
end
if ~exist('Minitial')
  Minitial=eye(3);
elseif isempty(Minitial)
  Minitial=eye(3);
end

if (length(iters)>1)
  % reduce images
  im1Small=reduce(im1);
  im2Small=reduce(im2);

  % reduce inital affine matrix
  M=Minitial;
  M(1:2,3)=M(1:2,3)/2;

  % estimate M for reduced images
  M=estMotionMulti2(im1Small,im2Small,iters(2:length(iters)),M,rotFlag,robustFlag,CB,SC);

  % expand estimated affine matrix
  M(1:2,3)=M(1:2,3)*2;
  Minitial=M;
end

% Iterate, warping and refining estimates
if (iters(1) > 0)
  M=estMotionIter2(im1,im2,iters(1),Minitial,rotFlag,robustFlag,CB,SC);
end

return;

%%%%%%%%%
% Debug %
%%%%%%%%%

% Test translation
dims=[128 128];
in=rand(dims);
A1=[1 0 2;
    0 1 2;
    0 0 1];
A2=inv(A1);
im1=warpAffine2(in,A1);
im2=warpAffine2(in,A2);
A=A1*A1
% One-scale only fails
% default - rot and LS
ArotLS = estMotionIter2(im1,im2,3);
% rot and robust
ArotRob = estMotionIter2(im1,im2,3,[],1,1);
% affine and LS
AaffLS = estMotionIter2(im1,im2,3,[],0,0);
% affine and robust
AaffRob = estMotionIter2(im1,im2,3,[],0,1);

% Multiscale wins
% default - rot and LS
ArotLSM = estMotionMulti2(im1,im2,[3,1,1]);
% rot and robust
ArotRobM = estMotionMulti2(im1,im2,[3,1,1],[],1,1);
% affine and LS
AaffLSM = estMotionMulti2(im1,im2,[3,1,1],[],0,0);
% affine and robust
AaffRobM = estMotionMulti2(im1,im2,[3,1,1],[],0,1);
A
[ArotLS zeros(3,1) ArotLSM]
[ArotRob zeros(3,1) ArotRobM]
[AaffLS zeros(3,1) AaffLSM]
[AaffRob zeros(3,1) AaffRobM]

% Test rotation
dims=[256 128];
in=rand(dims);
theta=4*atan2(1,max(dims));
A1=[cos(theta) sin(theta) 0;
    -sin(theta) cos(theta) 0;
    0 0 1];
A2=inv(A1);
im1=warpAffine2(in,A1);
im2=warpAffine2(in,A2);
A=A1*A1
% One-scale only fails
% default - rot and LS
ArotLS = estMotionIter2(im1,im2,3);
% rot and robust
ArotRob = estMotionIter2(im1,im2,3,[],1,1);
% affine and LS
AaffLS = estMotionIter2(im1,im2,3,[],0,0);
% affine and robust
AaffRob = estMotionIter2(im1,im2,3,[],0,1);

% Multiscale wins
% default - rot and LS
ArotLSM = estMotionMulti2(im1,im2,[3,2,2]);
% rot and robust
ArotRobM = estMotionMulti2(im1,im2,[3,2,2],[],1,1);
% affine and LS
AaffLSM = estMotionMulti2(im1,im2,[3,2,2],[],0,0);
% affine and robust
AaffRobM = estMotionMulti2(im1,im2,[3,2,2],[],0,1);
A
[ArotLS zeros(3,1) ArotLSM]
[ArotRob zeros(3,1) ArotRobM]
[AaffLS zeros(3,1) AaffLSM]
[AaffRob zeros(3,1) AaffRobM]


% Test expansion
dims=[128 128];
in=rand(dims);
s=1.05
A1=[s 0 0;
    0 s 0;
    0 0 1];
A2=inv(A1);
im1=warpAffine2(in,A1);
im2=warpAffine2(in,A2);
A=A1*A1
% One-scale only
% default - rot and LS
ArotLS = estMotionIter2(im1,im2,3);
% rot and robust
ArotRob = estMotionIter2(im1,im2,3,[],1,1);
% affine and LS
AaffLS = estMotionIter2(im1,im2,3,[],0,0);
% affine and robust
AaffRob = estMotionIter2(im1,im2,3,[],0,1);

% Multiscale
% default - rot and LS
ArotLSM = estMotionMulti2(im1,im2,[3,2,2]);
% rot and robust
ArotRobM = estMotionMulti2(im1,im2,[3,2,2],[],1,1);
% affine and LS
AaffLSM = estMotionMulti2(im1,im2,[3,2,2],[],0,0);
% affine and robust
AaffRobM = estMotionMulti2(im1,im2,[3,2,2],[],0,1);
A
[ArotLS zeros(3,1) ArotLSM]
[ArotRob zeros(3,1) ArotRobM]
[AaffLS zeros(3,1) AaffLSM]
[AaffRob zeros(3,1) AaffRobM]


%%%%%%%%%%%%%%%%%%%%
% test with outliers
%%%%%%%%%%%%%%%%%%%%

% Test rotation
dims=[256 128];
in=rand(dims);
theta=4*atan2(1,max(dims));
A1=[cos(theta) sin(theta) 0;
    -sin(theta) cos(theta) 0;
    0 0 1];
A2=inv(A1);
im1=warpAffine2(in,A1);
im2=warpAffine2(in,A2);
% putting inconsistent information in upper left corner of im2
Nc=3;
im2(1:round(dims(1)/Nc), 1:round(dims(2)/Nc)) = rand(round(dims(1)/Nc), round(dims(2)/Nc));
A=A1*A1
% One-scale only fails
% default - rot and LS
ArotLS = estMotionIter2(im1,im2,3);
% rot and robust
ArotRob = estMotionIter2(im1,im2,3,[],1,1);
% affine and LS
AaffLS = estMotionIter2(im1,im2,3,[],0,0);
% affine and robust
AaffRob = estMotionIter2(im1,im2,3,[],0,1);

% Multiscale wins
% default - rot and LS
ArotLSM = estMotionMulti2(im1,im2,[3,2,2]);
% rot and robust
ArotRobM = estMotionMulti2(im1,im2,[3,2,2],[],1,1);
% affine and LS
AaffLSM = estMotionMulti2(im1,im2,[3,2,2],[],0,0);
% affine and robust
AaffRobM = estMotionMulti2(im1,im2,[3,2,2],[],0,1);
A
[ArotLS zeros(3,1) ArotLSM]
[ArotRob zeros(3,1) ArotRobM]
[AaffLS zeros(3,1) AaffLSM]
[AaffRob zeros(3,1) AaffRobM]

