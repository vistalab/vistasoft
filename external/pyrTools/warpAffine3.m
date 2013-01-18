function result = warpAffine3B(in,A,badVal,B,interpMethod)
%
% function result = warpAffine3B(in,A,badVal,B)
%
% in: input volume, 3D array
% A: 3x4 affine transform matrix or a 4x4 matrix with [0 0 0 1]
%    for the last row.
% badVal: if a transformed point is outside of the volume, badVal is used
% B:  number of voxels to put in the border (default =0, no border)
%
% result: output volume, same size as in
%
% 10/99, on - added Border parameter to permit nearest neighbor interpolation at the edges
%

if ( ~exist('badVal') | isempty(badVal) )
  badVal=NaN;
end

if ( ~exist('B') | isempty(B) )
  B = 0;
end

if(ieNotDefined('interpMethod'))
    interpMethod = '*linear';
end

if (size(A,1)>3)
  A=A(1:3,:);
end

% original size
[NyO NxO NzO] = size(in);

% if B~=0, put a border by replicating edge voxels
if B~=0
  % put border at each slice
  for k =1:size(in,3)
    inB(:,:,k) = putborde(in(:,:,k),B,B,3);
 end
 % repeat the first and last slices
 in = cat(3,repmat(inB(:,:,1),[1 1 B]), inB, repmat(inB(:,:,end),[1 1 B]));
end

% coordinates corresponding to the volume with borders 
[xB,yB,zB]=meshgrid(1-B:size(in,2)-B,1-B:size(in,1)-B,1-B:size(in,3)-B);
 
% Compute coordinates corresponding to input volume
% and transformed coordinates for result
[xgrid,ygrid,zgrid]=meshgrid(1:NxO,1:NyO,1:NzO);
coords=[xgrid(:)'; ygrid(:)'; zgrid(:)'];
homogeneousCoords=[coords; ones(1,size(coords,2))];
warpedCoords=A*homogeneousCoords;

% Compute result using interp3
result = interp3(xB,yB,zB,in,warpedCoords(1,:),warpedCoords(2,:),warpedCoords(3,:),interpMethod);
result = reshape(result,[NyO NxO NzO]);

% replace NaNs with badval
if(~isnan(badVal)) 
  NaNIndices = find(isnan(result));
  result(NaNIndices)=badVal*ones(size(NaNIndices));
end
return;

%%% Debug

slice=[1 2 3; 4 5 6; 7 8 9]';
slice=[1 1 1; 3 3 3; 5 5 5]';
input=ones(3,3,4);
for z=1:4
  input(:,:,z)=slice;
end

A= [1 0 0 .5;
    0 1 0 0;
    0 0 1 0;
    0 0 0 1];

A= [1 0 0 .5;
    0 1 0 .5;
    0 0 1 0];

res=warpAffine3(input,A)
resB=warpAffine3B(input,A,NaN,1)

for z=1:4
  input(:,:,z)=z*ones(3,3);
end
A= [1 0 0 0;
    0 1 0 0;
    0 0 1 .5;
    0 0 0 1];
res=warpAffine3(input,A)
resB=warpAffine3B(input,A,NaN,1)

input=rand(5,5,5);
res=warpAffine3(input,eye(4));
resB=warpAffine3B(input,eye(4),NaN,1);
