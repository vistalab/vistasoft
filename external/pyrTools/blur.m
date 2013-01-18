function result = blur(im,levels,filt)
% Blurs an image by blurring and subsampling repeatedly, followed by
% upsampling and blurring.
%
%      result=blur(im,[levels],[filt])
%
%  im     -  input image.
%  levels -  number of times to blur and subsample (default is 1).
%  filt   -  blurring 1d filter to be applied separably to the rows and
%            cols of im (default ='binom5').
%
% HISTORY:
%
% DJH '96
% update 12/97 to conform to Eero's updated pyrTools
%
% I don't think we should use this any more.  Why not just use Matlab's
% convolution or blurring or filtering? (BW)
% Because this is routine *much* faster than convolution. (RFD)
%
% 2007.05.03 RFD: fixed non-double class support.

% warning('This function calls very old mex files that might not work. Try imblur instead.');

if ~exist('levels','var'), levels=1; end
if ~exist('filt','var'),   filt = 'binom5'; end
if ischar(filt),           filt = namedFilter(filt); end  

% ras 03/07: enforce double-precision data type
% (the compiled corrDn functions need double)
if ~isa(im, 'double'), type = class(im); im = double(im); end
tmp = blurDn(im,levels,filt);

% save upBlurDEBUG tmp levels filt
result = upBlur(tmp,levels,filt);

% Make sure its the same size as the input image
result = result((1:size(im,1)),(1:size(im,2)));

if exist('type', 'var')
	% we had a non-double matrix, convert back
	result = feval(type, result);
end

return;
