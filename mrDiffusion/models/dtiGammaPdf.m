function y = dtiGammaPdf(x, alpha, beta)
%
% y = dtiGammaPdf(x, alpha, beta)
%
% Returns values from the gamma pdf. This is functionally equivalent to
% Matlab's gampdf(x,alpha,1/beta). It is included for convenience, as not
% everyone has the Matlab stats toolbox.
%
% E.g.:
% figure; hold on; x = [0.1:0.1:10];
% for(alpha=1:10), plot(x,dtiGammaPdf(x,alpha,1)); end; 
% hold off;
%
% HISTORY
% 2009.06.09 RFD wrote it.

% The gamma function in Assaf and Basser isn't quite right:
%y = (x.^(1./(alpha-1)) .* exp(-x./beta)) ./ (beta.^alpha.*gamma(alpha));

% This is the standard gamma pdf (e.g., see Wikipedia):
y = (beta.^alpha)./gamma(alpha) .* x.^(alpha-1) .* exp(-beta.*x);

return;