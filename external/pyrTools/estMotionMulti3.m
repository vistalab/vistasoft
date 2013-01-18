function M = estMotionMulti3(vol1,vol2,iters,Minitial,rotFlag,robustFlag,CB,SC)
%
% function  M = estMotionMulti3(vol1,vol2,iters,Minitial,rotFlag,robustFlag)
%
% vol1 and vol2 are volumes, 3d arrays
% iters is vector of number of iterations to run at each
%   successive scale. default is: [3] that runs 3 iterations at
%   the base scale.
% Minitial is initial guess for M.  Default is 4x4 identity matrix.
% 
% This function calls itself recursively.
%
% M is 4x4 translation+rotation transform matrix (in homogeneous coordinates)
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
  Minitial=eye(4);
elseif isempty(Minitial)
  Minitial=eye(4);
end
M=Minitial;

numSlices=size(vol1,3);

if (length(iters)>1)
  % reduce images
  newdims=size(reduce(vol1(:,:,1)));
  vol1small=zeros(newdims(1),newdims(2),numSlices);
  vol2small=zeros(newdims(1),newdims(2),numSlices);
  for z=1:numSlices
    vol1small(:,:,z)=reduce(vol1(:,:,z));
    vol2small(:,:,z)=reduce(vol2(:,:,z));
  end
  % reduce  matrix
  M(1:2,4)=M(1:2,4)/2;
  % estimate M for reduced images
  M=estMotionMulti3(vol1small,vol2small,iters(2:length(iters)),M,rotFlag,robustFlag,CB,SC);
  % expand estimated transformation matrix
  M(1:2,4)=M(1:2,4)*2;
end

% Iterate, warping and refining estimates
if (iters(1) > 0)
  M=estMotionIter3(vol1,vol2,iters(1),M,rotFlag,robustFlag,CB,SC);
end

return;

%%%%%%%%%
% Debug %
%%%%%%%%%

% input
filter = [0.03504 0.24878 0.43234 0.24878 0.03504];
in = convXYsep(convZ(rand(68,88,14),filter),filter,filter);

% Test translation
% translation
A1=[1 0 0 1;
    0 1 0 1.5;
    0 0 1 0.3
    0 0 0 1];
A2=inv(A1);
vol1=warpAffine3(in,A1);
vol2=warpAffine3(in,A2);
vol1=vol1(:,:,2:9);
vol2=vol2(:,:,2:9);
A=A1*A1;
% One-scale only fails
% default - rot and LS
ArotLS = estMotionIter3(vol1,vol2,3);
% rot and robust
%ArotRob = estMotionIter3(vol1,vol2,3,[],1,1);
% affine and LS
AaffLS = estMotionIter3(vol1,vol2,3,[],0,0);
% affine and robust
%AaffRob = estMotionIter3(vol1,vol2,3,[],0,1);

% Multiscale wins
% default - rot and LS
ArotLSM = estMotionMulti3(vol1,vol2,[3,3,3]);
% rot and robust
%ArotRobM = estMotionMulti3(vol1,vol2,[3,3,3],[],1,1);
% affine and LS
AaffLSM = estMotionMulti3(vol1,vol2,[3,3,3],[],0,0);
% affine and robust
%AaffRobM = estMotionMulti3(vol1,vol2,[3,3,3],[],0,1);
A
[ArotLS zeros(4,1) ArotLSM]
%[ArotRob zeros(4,1) ArotRobM]
[AaffLS zeros(4,1) AaffLSM]
%[AaffRob zeros(4,1) AaffRobM]

% Test rotation
% rotation in x,y
theta=.06;
A1=[cos(theta) sin(theta) 0 0;
    -sin(theta) cos(theta) 0 0;
    0 0 1 0
    0 0 0 1];
A2=inv(A1);
vol1=warpAffine3(in,A1);
vol2=warpAffine3(in,A2);
vol1=vol1(:,:,2:9);
vol2=vol2(:,:,2:9);
A=A1*A1;
% One-scale only fails
% default - rot and LS
ArotLS = estMotionIter3(vol1,vol2,3);
% rot and robust
%ArotRob = estMotionIter3(vol1,vol2,3,[],1,1);
% affine and LS
AaffLS = estMotionIter3(vol1,vol2,3,[],0,0);
% affine and robust
%AaffRob = estMotionIter3(vol1,vol2,3,[],0,1);

% Multiscale wins
% default - rot and LS
ArotLSM = estMotionMulti3(vol1,vol2,[3,2,2]);
% rot and robust
%ArotRobM = estMotionMulti3(vol1,vol2,[3,2,2],[],1,1);
% affine and LS
AaffLSM = estMotionMulti3(vol1,vol2,[3,2,2],[],0,0);
% affine and robust
%AaffRobM = estMotionMulti3(vol1,vol2,[3,2,2],[],0,1);
A
[ArotLS zeros(4,1) ArotLSM]
%[ArotRob zeros(4,1) ArotRobM]
[AaffLS zeros(4,1) AaffLSM]
%[AaffRob zeros(4,1) AaffRobM]

% rotation in x,z
theta=.06;
A1=[cos(theta) 0 sin(theta) 0;
    0 1 0 0;
    -sin(theta) 0 cos(theta) 0;
    0 0 0 1];
A2=inv(A1);
vol1=warpAffine3(in,A1);
vol2=warpAffine3(in,A2);
vol1=vol1(:,:,2:9);
vol2=vol2(:,:,2:9);
A=A1*A1;
% One-scale only fails
% default - rot and LS
ArotLS = estMotionIter3(vol1,vol2,3);
% rot and robust
%ArotRob = estMotionIter3(vol1,vol2,3,[],1,1);
% affine and LS
AaffLS = estMotionIter3(vol1,vol2,3,[],0,0);
% affine and robust
%AaffRob = estMotionIter3(vol1,vol2,3,[],0,1);

% Multiscale wins
% default - rot and LS
ArotLSM = estMotionMulti3(vol1,vol2,[3,2,2]);
% rot and robust
%ArotRobM = estMotionMulti3(vol1,vol2,[3,2,2],[],1,1);
% affine and LS
AaffLSM = estMotionMulti3(vol1,vol2,[3,2,2],[],0,0);
% affine and robust
%AaffRobM = estMotionMulti3(vol1,vol2,[3,2,2],[],0,1);
A
[ArotLS zeros(4,1) ArotLSM]
%[ArotRob zeros(4,1) ArotRobM]
[AaffLS zeros(4,1) AaffLSM]
%[AaffRob zeros(4,1) AaffRobM]

% Test expansion
s=1.05;
A1=[s 0 0 0;
    0 s 0 0;
    0 0 1/s 0;
    0 0 0 1];
A2=inv(A1);
vol1=warpAffine3(in,A1);
vol2=warpAffine3(in,A2);
vol1=vol1(:,:,2:9);
vol2=vol2(:,:,2:9);
A=A1*A1
% One-scale only fails
% default - rot and LS
ArotLS = estMotionIter3(vol1,vol2,3);
% rot and robust
%ArotRob = estMotionIter3(vol1,vol2,3,[],1,1);
% affine and LS
AaffLS = estMotionIter3(vol1,vol2,3,[],0,0);
% affine and robust
%AaffRob = estMotionIter3(vol1,vol2,3,[],0,1);

% Multiscale wins
% default - rot and LS
ArotLSM = estMotionMulti3(vol1,vol2,[3,2,2]);
% rot and robust
%ArotRobM = estMotionMulti3(vol1,vol2,[3,2,2],[],1,1);
% affine and LS
AaffLSM = estMotionMulti3(vol1,vol2,[3,2,2],[],0,0);
% affine and robust
%AaffRobM = estMotionMulti3(vol1,vol2,[3,2,2],[],0,1);
A
[ArotLS zeros(4,1) ArotLSM]
%[ArotRob zeros(4,1) ArotRobM]
[AaffLS zeros(4,1) AaffLSM]
%[AaffRob zeros(4,1) AaffRobM]

%%%%%%%%%%%%%%%%%%%%
% test with outliers
%%%%%%%%%%%%%%%%%%%%

% rotation in x,y
theta=.06;
A1=[cos(theta) sin(theta) 0 0;
    -sin(theta) cos(theta) 0 0;
    0 0 1 0
    0 0 0 1];
A2=inv(A1);
vol1=warpAffine3(in,A1);
vol2=warpAffine3(in,A2);
vol1=vol1(:,:,2:9);
vol2=vol2(:,:,2:9);
% putting inconsistent information in upper left corner of vol2
Nc=2.5;
dims=size(vol2);
vol2(1:round(dims(1)/Nc), 1:round(dims(2)/Nc), :) = ...
			rand(round(dims(1)/Nc), round(dims(2)/Nc), dims(3));
A=A1*A1;
% default - rot and LS
ArotLSM = estMotionMulti3(vol1,vol2,[3,2,2]);
% rot and robust
ArotRobM = estMotionMulti3(vol1,vol2,[3,2,2],[],1,1);
% affine and LS
AaffLSM = estMotionMulti3(vol1,vol2,[3,2,2],[],0,0);
% affine and robust
AaffRobM = estMotionMulti3(vol1,vol2,[3,2,2],[],0,1);
A
ArotLSM
ArotRobM
AaffLSM
AaffRobM
