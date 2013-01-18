function im = clip(im, cmin, cmax)
% clip(im, cmin, cmax)
%	Clips image values between cmin and cmax.
%	Cmin and cmax default to 0 and 1 respectively if not specified.
%
% HISTORY:
%
%  2002.04.10 RFD (bob@white.stanford.edu): updated horribly inefficient 
%   and obscure code.

if ~exist('cmin')
  cmin=0;
end
if ~exist('cmax')
  cmax=1;
end

im(im<cmin) = cmin;
im(im>cmax) = cmax;

return


% result=im;
% 
% index = find(im < cmin);
% result(index) = cmin * ones(size(index));
% 
% index = find(im > cmax);
% result(index) = cmax * ones(size(index));
