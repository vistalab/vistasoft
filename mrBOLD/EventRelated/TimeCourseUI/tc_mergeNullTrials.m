function tc = tc_mergeNullTrials(tc);
% for timeCourseUI:
%
% For a particular design type in which on and off blocks/trials alternate,
% with different on conditoins, we sometimes want to consider only the on
% conditions, and consider the in-between off trials as part of the
% last trial. This function merges all null trials (condition # = 0)
% besides the first one into the preceding trial. If the first trial is
% null, it leaves that one alone. 
%
% I've also considered merging each null with the preceding trial, which is
% nice b/c it gives a nice prestim baseline, but not so nice b/c it makes
% the actual onset time of the on stimulus ambiguous. Better to make that
% obvious, and let the user shift onset times using existing tools to see a
% prestim baseline.
%
%
%
% written 03/11/04 ras.
if nargin==0, tc = get(gcf,'UserData'); end

if all(tc.trials.cond(1:2:end)==0)
    tc.trials.cond = [tc.trials.cond(1) tc.trials.cond(2:2:end)];
    tc.trials.onsetSecs = [tc.trials.onsetSecs(1) tc.trials.onsetSecs(2:2:end)];
else
    tc.trials.cond = tc.trials.cond(1:2:end);
    tc.trials.onsetSecs = tc.trials.onsetSecs(1:2:end);
end

% since we're removing all null conditions, remove the 0 condition
% from other fields:
tc.trials.condNums = tc.trials.condNums(2:end);
for i = 1:length(tc.trials.condNums)
    tmp1{i} = tc.trials.condColors{i+1};
    tmp2{i} = tc.trials.condNames{i+1};
end
tc.trials.condColors = tmp1;
tc.trials.condNames = tmp2;

% it's even more complicated than that -- also
% need to turn off the cond menu entry for the null
% condition, and remove the handle:
null = 2; % assume null is 1st cond; first entry in condMenuHandles is cond menu
set(tc.ui.condMenuHandles(null),'Visible','off');
hs = tc.ui.condMenuHandles;
hs = [hs(1:null-1) hs(null+1:end)]; % remove the handle to the null cond.
tc.ui.condMenuHandles = hs;

% remove residual 0s that may be left over in the conditions array
ind = (tc.trials.cond ~= 0);
tc.trials.cond = tc.trials.cond(ind);
tc.trials.onsetSecs = tc.trials.onsetSecs(ind);

set(gcf,'UserData',tc);

% can only do this once -- disable the feature afterwards
set(gcbo,'Visible','off');

tc_recomputeTc(tc,1);
timeCourseUI;

return