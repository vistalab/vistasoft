function sim = scale_im(im, newMin, newMax, oldMin, oldMax)
% scale(Image, newMin, newMax, oldMin, oldMax)
%	Scales an image such that its lowest value attains newMin and
%	its highest value attains newMax.  OldMin and oldMax are not
%	necessary but are useful when you don't want to use the true
%	min or max value.  
%
% Rick Anthony
% 6/23/93

%  find oldMin and oldMax if they aren't specified.	
if (nargin < 4) oldMin = min(min(im)); end
if (nargin < 5) oldMax = max(max(im)); end

% 6/30/97 Lea updated to 5.0
% clarify warnings: divided by zero
% since oldMax may be equal to oldMin

%nargin
%size(im)
%oldMin
%oldMax

if oldMax ~= oldMin
  delta = (newMax-newMin)/(oldMax-oldMin);
  sim = delta*(im-oldMin) + newMin;
else 
  delta = (newMax-newMin)/2;
  sim = delta*im;
end

