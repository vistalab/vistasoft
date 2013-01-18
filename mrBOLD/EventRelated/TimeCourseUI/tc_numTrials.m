function nTrials = tc_numTrials(tc,nullFlag);
% 
% nTrials = tc_numTrials(tc,[nullFlag]);
%
% Find the max # of trials for a condition
% (by default, excluding the null/cond=0 condition)
% 
% If nullFlag is set to 1, will incl. the
% null condition in counting trials.
%
% ras 03/05.
if ieNotDefined('nullFlag')
    nullFlag = 0;
end

if nullFlag==0
    allTcs = tc.allTcs(:,:,find(tc.trials.condNums>0));
else
    allTcs = tc.allTcs;
end

nonEmptyTrials = any(~isnan(allTcs));

nTrials = max(sum(nonEmptyTrials));

return
