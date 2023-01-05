function T = chainpermute(range, m)
% "chainpermute([range],m)" gives a 1-by-m row vector with random 
% assignment of elements within "range".  If m is a multiple of length(range) 
% then each element occurs with equal frequency.  If m is not a
% multiple of length(range)then no more than one of each element is
% omitted from output.
%
% range is specified as range = [Xlow:Xhigh]
% Can also specify a non-contiguous row vector for range, though a warning will
% appear if that vector is 1x2.
%
% >> v = chainpermute([1:3],12)
% 
% v =
% 
%      3     1     3     2     1     2     2     2     1     1     3     3
%
% >> v = chainpermute([1:3],10)
% 
% v =
% 
%      3     1     2     3     1     1     2     2     3     2
% 
% 03/10/06 - dr - created and tested
%
% David Remus - Stanford Univerity Dept. of Psychology

dummy = randperm(m);
iterations = floor(m/length(range));

if isequal(size(range),[1 2]) && ~isequal(range(1),range(2)-1),
    warning('To specify a range [low high] use [low:high].')
end

if iterations == 0
    warning('number of elements in output is less than number of elements in range')
else
    for i = 1:length(range)
        for j = 1:iterations
            unsorted((i*j)+(iterations-j)*(i-1)) = range(i);
        end
    end
end

smalldummy = randperm(length(range));
remaining = m-iterations*length(range);

for i = 1:remaining
    unsorted(i+iterations*length(range)) = range(smalldummy(i));
end


for i = 1:length(dummy)
    T(i) = unsorted(dummy(i));
end

% % EOF chainpermute.m