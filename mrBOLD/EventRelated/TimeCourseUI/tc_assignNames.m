function tc = tc_assignNames(tc);
% tc_assignNames;
%
% This is a callback from ras_tc which allows the 
% user to set the condition colors.
%
% 01/04 ras.
if notDefined('tc'),    tc = get(gcf,'UserData');       end

% set up an input dialog to get colors %%%%%%%%%%%%%%%%%%%
for i = 1:length(tc.trials.condNames)
    defaults{i} = tc.trials.condNames{i};
end

for i = 1:length(tc.trials.condNums)
    labels{i} = sprintf('Condition %i',tc.condNums(i));
end
AddOpts.Resize = 'on';
AddOpts.Interpreter = 'tex';
AddOpts.Interpreter = 'Normal';
answers = inputdlg(labels,'Set Condition Names...',1,defaults);

for i = 1:length(tc.trials.condNames)
    tc.trials.condNames{i} = answers{i};
end

set(gcf, 'UserData', tc);

tc_legend(tc);

timeCourseUI;

return
