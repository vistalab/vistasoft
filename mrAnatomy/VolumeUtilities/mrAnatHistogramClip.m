function [img, clipVals] = mrAnatHistogramClip(img, lowerClip, upperClip, rescaleFlag)
%
% [img, clipVals] = mrAnatHistogramClip(img, ...
%       [lowerClipLevel=0.4], [upperClipLevel=0.99], [rescaleFlag=true])
%
% Clips the input array values (img) so that the range of values will be
% between the pixel-count proportions specified by lowerClip and upperClip.
%
% Rescale - if true, the intensities will be scaled to 0-1. Otherwise, the
% original (but clipped) intensity range will be preserved.
%
% Example: If lowerClip = 0.20 and upperClip = 0.98, then the values in img
% will be clipped so that the lowest value is that of the 20th percentile
% of the original values and the upper value is that of the 98th
% percentile.
%
% HISTORY:
% 2004.11.05 RFD: wrote it.

if(~exist('rescaleFlag','var') || isempty(rescaleFlag))
    rescaleFlag = true;
end
if(~exist('lowerClip','var')||isempty(lowerClip))
    lowerClip = 0.4;
end
if(~exist('upperClip','var')||isempty(upperClip))
    upperClip = 0.99;
end
if(~isfloat(img))
    img = double(img);
end
if(upperClip>1)
  % assume that these are real image-intensity clip vals
  lowerClipVal = lowerClip;
  upperClipVal = upperClip;
else
  [count,value] = hist(double(img(:)),256);
  upperClipVal = value(min(find(cumsum(count)./sum(count)>=upperClip)));
  lowerClipVal = value(max(find(cumsum(count)./sum(count)<=lowerClip)));
  if(isempty(lowerClipVal)) lowerClipVal = value(1); end
end
img(img>upperClipVal) = upperClipVal;
img(img<lowerClipVal) = lowerClipVal;
if(rescaleFlag)
  img = img-lowerClipVal;
  img = img./(upperClipVal-lowerClipVal);
end

clipVals = [lowerClipVal upperClipVal];

return
