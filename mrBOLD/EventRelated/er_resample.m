function vals = er_resample(onsets, conds, T);
%
% vals = er_resample(onsets, conds, [T]);
%
% Resample a set of condition #s, or other values,
% with associated onset times at points T. onsets 
% and conds should be the same length. T should 
% be specified in the same units as onsets 
% (e.g., seconds or MR frames). [If omitted, T will run from 
% 1 to the max value of onsets.]
%
% I wrote this to sample conditions #s / run #s
% at each TR in a time course.
%
% ras, 09/2005.
if nargin<2, error('Not enough input args.'); end
if notDefined('T'), T = 1:max(onsets(:)); end

% enforce column vector for T
T = T(:);

vals = zeros(size(T));

% make everything increasing
[onsets I] = sort(onsets);
conds = conds(I);

for i = 1:length(T)    
    if T(i) >= onsets(1)
        lastOnset = max(find(onsets <= T(i))); % most recent 
        vals(i:end) = conds(lastOnset);
    end
end

return
        