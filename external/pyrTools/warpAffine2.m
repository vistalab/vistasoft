function result = warpAffine2(im,A,interpMethod)
%
% function result = warpAffine2(im,A,[interpMethod])
%
% im: input image
% A: 2x3 affine transform matrix or a 3x3 matrix with [0 0 1]
% for the last row.
% if a transformed point is outside of the volume, NaN is used
% interpMethod (defaults to linear)- passed directly to interp2- do
%    help interp2 to see options (eg. nearest, linear, cubic, spline)
%
% result: output image, same size as im
%
% Author: David Heeger
%
% 8/13/97  dhb  Deleted extra 0 in comment above.
% 7/23/02  rfd  Added optional interpMethod.

if (size(A,1)>2)
  A=A(1:2,:);
end
if(~exist('interpMethod','var') | isempty(interpMethod))
    interpMethod = 'linear';
end

% Compute coordinates corresponding to input 
% and transformed coordinates for result
[x,y]=meshgrid(1:size(im,2),1:size(im,1));
coords=[x(:)'; y(:)'];
homogeneousCoords=[coords; ones(1,prod(size(im)))];
warpedCoords=A*homogeneousCoords;
xprime=warpedCoords(1,:)';
yprime=warpedCoords(2,:)';

result = interp2(x,y,im,xprime,yprime,interpMethod);
result = reshape(result,size(im));

return;

%%% Debug

im=[1 2 3; 4 5 6; 7 8 9]';

A= [1 0 .5;
    0 1 0;
    0 0 1];

A= [1 0 0;
    0 1 .5;
    0 0 1];

A= [1 0 .5;
    0 1 .5;
    0 0 1];

res=warpAffine2(im,A)


