function im = imblur(im,ntaps)
% Blurs an image by convolution with a binomial filter of size ntaps.
%
%  result = imblur(im,[ntaps=5])
%
% HISTORY:
% 2007.09.24 RFD: built this replacement for 'blur' that does not use the
% pyrTools mex files, since they are now too old to recompile easily. Note
% that the algorithm below is NOT an exact replacement for 'blur'.

persistent Pntaps;
persistent filt;
if(~exist('ntaps','var')||isempty(ntaps)), ntaps = 5; end
if(isempty(filt)||Pntaps~=ntaps)
    filt = namedFilter(sprintf('binom%d',ntaps));
    filt = filt./sum(filt);
    Pntaps = ntaps;
end

% Use seperable convolution
im = conv2(double(im),filt','same');
im = conv2(im,filt,'same');

return;
