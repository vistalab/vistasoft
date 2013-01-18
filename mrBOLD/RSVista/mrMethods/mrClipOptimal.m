function [img, lowerClip, upperClip] = mrClipOptimal(img, figNum)
%Determines optimal clip values for the input image and applies them.
%
% [img, lowerClip, upperClip] = mrmClipOptimal(img, [figNum=0])
%
% The resulting image will also be rescaled to values between 0 and 1.
%
% If figNum is non-zero, then  the histogram and clip values are displayed
% in that figNum.
%
% HISTORY:
% 2005.02.10 RFD: wrote it.
% 2005.07.08 ras: imported into mrVista 2.0, and shortened the 
% name (from mrAnatHistogramClipOptimal; now using it for mr data
% not restricted to anatomicals).
if(~exist('figNum','var') | isempty(figNum))
    figNum = 0;
end

img = double(img);
% Deciding on the number of bins is a bit tricky. In general, ~100 bins is
% optimal for most of our images. But, some data with a a very large right
% tail benefit from a higher-resoltuion histogram.
nbins = 100;
m = max(img(:));
if(m>10000)
    nbins = nbins + round((m-10000)/100);
end

% Ensure nbins is even
nbins = nbins-mod(nbins,2);
[count,value] = mrHistogramSmooth(img, nbins, 0.001);

% derivative of the thresholded derivative gives us the locations where a
% rising or falling trend begins. In general, we can just take the first
% rising trend (ie. just after the background noise) to find the brain.
% We then back off from that by 10% (an empirically determined heuristic).
firstDeriv = [0 diff(count)];

% +1 because diff returns n-1 values.
peakStart = find(diff(firstDeriv>0)>0)+1;

% Heuristic to skip the 'air' noise peak, which sometimes rises and
% sometimes just starts out very high.
if(peakStart(1)<=3)
    startFirstPeak = peakStart(2);
else
    startFirstPeak = peakStart(1);
end
lowerClip = value(startFirstPeak);
lowerClip = lowerClip.*0.90;

% For the upper clip, find where the last major peak ends. This one is
% harder, because the last peak usually doesn't end abruptly, but rather
% asymptotes. We want to find the last "major" inflection- ie, just after
% it drops sharply. The following heuristic usually does that.
firstDeriv(1:startFirstPeak) = 0; % squash noise peak
firstDeriv(firstDeriv>0) = 0;  % squash rising trends

% the derivs left now indicate falling trends beyond the first peak. The
% minimum of this derivative is where the falling trend tapers off. There
% are often several, so we pick the last 'substantial' one (ie. the last
% one that is >= 20% the size of the largest).
% We go 10% beyond that for good measure.
endLastPeak = find(firstDeriv<min(firstDeriv)*.2);
upperClip = value(endLastPeak(end)) .* 1.10;
if(figNum>0)
    figure(figNum); 
    set(figNum,'Name','Optimal histogram clipping');
    subplot(2,1,1);
    title('Optimal histogram clip-range guess:');
    plot(value,count);
    line([lowerClip,upperClip], [max(count)/2, max(count)/2], 'Color', 'r', 'LineWidth', 2);
    subplot(2,1,2);
    title('Histogram-clipped image:');
    n = size(img,3);
    sl = round(linspace(ceil(n/15), n-n/15, min(12,n)));
    im = makeMontage(img, sl, [], 6);
    im(im<lowerClip) = lowerClip; im(im>upperClip) = upperClip;
    im = im-lowerClip; im = uint8(im./(upperClip-lowerClip)*255);
    image(im); axis equal off tight; colormap(gray(256));
    pause(0.1);
end

img(img>upperClip) = upperClip;
img(img<lowerClip) = lowerClip;
img = img-lowerClip;
img = img./(upperClip-lowerClip);

return