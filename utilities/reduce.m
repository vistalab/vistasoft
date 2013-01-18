function res = reduce(im,bfilt)
%
% function res = reduce(im,bfilt)
%
% Separable convolution and subsampling by a factor of two
% im: input image
% bfilt: convolution kernel (vector).  
%       Default is: [.0625 .25 .375 .25 .0625]'
% res: result image
%
% res is 1/2 the size of im.  Fills NaNs for invalid pixels near
% edges.

if ~exist('bfilt')
  bfilt=[.0625 .25 .375 .25 .0625]';
end

% Use standard Matlab convolution routines instead for ease of
% distribution, and to set edge values to NaNs
bsize = floor(length(bfilt)/2);
tmp1 = conv2sep(im,bfilt,bfilt,'valid');
tmp2 = NaN*ones(size(im));
tmp2(1+bsize:size(im,1)-bsize,1+bsize:size(im,2)-bsize)=tmp1;
res = tmp2(1:2:size(im,1),1:2:size(im,2));

return;

%%%%%%%%%
% Debug %
%%%%%%%%%

foo=pgmRead('einstein.pgm');
bar=reduce(foo);
bar=replaceValue(bar,NaN,0);
displayImage(bar);

in=ones(7,7)
res=reduce(in)
