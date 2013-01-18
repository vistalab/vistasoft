function x=RandSample(list,dims)
% Returns a random sample from a list. 
% 
% x=RandSample(list,[dims])
%
% The optional second argument may be
% used to request an array (of size dims) of independent samples. E.g.
% RandSample(-1:1,[10,10]) returns a 10x10 array of samples from the list -1:1. 
% RandSample is a quick way to generate samples (e.g. visual noise) from a bounded
% Gaussian distribution. Also see RAND, RANDN, Randi, Sample, and Shuffle.
% 
% "list" must be a vector. In the future, we may accept matrices and treat
% columns separately, as other MATLAB functions do.
%
% Denis Pelli 7/22/97 3/24/98
% 8/14/99 Renamed from "Rands" (which conflicts with Neural Net Toolbox) to
% "RandSample".

if nargin<1 || nargin>2 || min(size(list))~=1
	error('Usage: i=RandSample(list,[dims])')
end

if nargin==1
	dims=1;
end

x=list(ceil(length(list)*rand(dims)));

return
