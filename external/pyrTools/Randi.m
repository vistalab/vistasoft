function i=Randi(n,dims)
% i=Randi(n,[dims])
% Returns a random integer sample from 1:n. The optional second argument
% may be used to specify the size of the returned array of independent
% samples. E.g. randi(100,[3,3]) returns a 3x3 array of independent
% samples drawn from the range 1:100. Also see RAND, RANDN, RandSample, Sample,
% and Shuffle.
% 
% We assume that n is a positive integer, and rely on the fact that RAND
% never returns 0 or 1.
% 
% Randi(n) is similar to David Brainard's Ranint(n).
% 
% Denis Pelli 4/19/96, 6/25/96, 6/29/96, 7/22/97
if nargin<1 | nargin>2 | cumprod(size(n))~=1
	error('Usage: i=Randi(n,[dims])')
end
if nargin==1
	dims=1;
end
i=ceil(n*rand(dims));
