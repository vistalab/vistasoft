function [inpC,p] = regCorrContrast(inp,Limit,pinit);
% regCorrContrast - removes mean and normalizes by the standard deviation, 
%                both estimated by minimizing a robust error measure 
%                between the sampled histogram and a mixture of 2 gaussians.
%
% [inpC,p] = regCorrContrast(inp, <pinit>);
%
% INPUT:
% - inp: set of original inplanes
% - pinit: initial parameters of the two best fitting Gaussians (optional)
%          (pinit = [mu1 sigma1^2 mu2 sigma2^2 p1 p2])
%
% Oscar Nestares - 5/99
%

if nargin<2
   Limit = 2;
end

% building the histogram
II = find(~isnan(inp));
[h x] = regHistogram(double(inp(II)), 256);

% normalizing the histogram
h = h/(sum(h)*mean(diff(x)));

% initial parameters: if they are not specified, chosoe the first
% gaussian with the actual mean and variance, and the second gaussian
% around 1 and with 1/10 of the actual variance, both with weights of 0.5 
if nargin<3
   pinit = [mean(inp(II)) var(inp(II)) 1 var(inp(II))/10 0.5 0.5];
end

% minimizing the robust measure of the error
%p=fmins('regErrGaussRob', pinit, [], [], x, h);
p = fminsearch('regErrGaussRob', double(pinit), [], x, h);

% selecting the mean closer to 1
if abs(p(1)-1)>abs(p(3)-1)
   mu = p(3); sigma2 = p(4);
else
   mu = p(1); sigma2 = p(2);
end

% renormalizing
inpC = (inp - mu)/sqrt(sigma2);

% saturating for low and high values
%Limit = 4;  %%% This is a reasonable value, 2*std (now std=1)
Low = inpC < -Limit;
High = inpC > Limit;
inpC = inpC .*((~Low) & (~High)) + (-Limit)*Low + Limit*High;

return


