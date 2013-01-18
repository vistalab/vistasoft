function result = conv2sep(im,rowfilt,colfilt,shape)
% CONV2SEP: Separable convolution using conv2.
% 
%      result=conv2sep(im,rowfilt,colfilt,shape)
%
%      im - input image.
%      rowfilt - 1d filter applied to the rows
%      colfilt - 1d filter applied to the cols
%      shape - 'full', 'same', or 'valid' (see doc for conv2).
%
% Example: foo=conv2sep(im,[1 4 6 4 1],[-1 0 1],'valid');
%
% DJH '96

if ~exist('shape')
  shape='full';
end

rowfilt=rowfilt(:)';
colfilt=colfilt(:);

tmp = conv2(im,rowfilt,shape);
result = conv2(tmp,colfilt,shape);
