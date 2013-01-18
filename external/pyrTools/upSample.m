function out = upSample(im, nLevels, filt)
% out = upSample(im, nLevels, [filt])
%
% Upsamples the image im by the integer nLevels.
% The upsampled image is blurred and edges are 
% dealt with by zero-padding.
%
% The blurring is done with the filter kernel specified by filt
% (default = [.125 .5 .75 .5 .125]'), which should be a vector 
% (applied separably as a 1D convolution kernel in X and Y), 
% or a matrix (applied as a 2D convolution kernel)
%
% 99.08.16 RFD wrote it, based on upBlur (and helpful
%				comments from DJH)

if nLevels ~= fix(nLevels)
   error('nLevels must be an integer!!!');
end

if ~exist('filt', 'var')
	% default filter for post-upsample convolution
	filt = sqrt(2)*namedFilter('binom5');
end

% use a little recursion to deal with upsample steps > 2
if nLevels > 1
  im = upSample(im, nLevels-1);
end
if (nLevels >= 1)
   if (any(size(im)==1))
      if (size(im,1)==1)
         filt = filt';
      end
      out = upConv(im, filt, 'zero',(size(im)~=1)+1);
   else
      % First, upsample and blur down cols...
      out = upConv(im, filt, 'zero', [2 1]);
		% Then, upsample and blur across rows...
      out = upConv(out, filt', 'zero', [1 2]);
   end
else
   out = im;
end

return

%%% Debug/test
