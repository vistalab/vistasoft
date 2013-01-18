function im = mrClip(im, cmin, cmax)
%
% mrClip(im, cmin, cmax)
%	Clips image values between cmin and cmax.
%	Cmin and cmax default to 0 and 1 respectively if not specified.
%
% HISTORY:
%
%  2002.04.10 RFD (bob@white.stanford.edu): updated horribly inefficient 
%   and obscure code.
%  2004.08.28 BW. Used to be simply 'clip'.  Changed name.

if ~exist('cmin'), cmin=0; end
if ~exist('cmax'), cmax=1; end

im(im<cmin) = cmin;
im(im>cmax) = cmax;

return
