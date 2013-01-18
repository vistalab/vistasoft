function tc_plotAllTrials(tc);
% tc_plotAllTrials(tc);
%
%
% plots tc data, superimposing different "trials"
% on top of one another. A "trial" may be an event-related
% trial, a block, or half a cycle (ABAB design).
% The lines for different conditions are color-coded.
%
% 02/23/04 ras: broken off as a separate function (previously kept in
% ras_tc).
% 06/04 ras: stores sorted data in the figure's userdata as 
% an 'allTcs' field
% kgs 031605 changed colors to reflect trial number 
% ras 031605 amended this: will color diff't trials if 'legend'
% is selected
cla

hold on

% only plot selected conditions
selected = find(tc_selectedConds(tc));

selectedTrials = [];
if tc.settings.legend==1
    % color diff't trials (will use condition colors 
    % specified in tc struct)
    colors= tc.trials.condColors;
else
    colors = {};
end

for i = selected
    for j = 1:size(tc.allTcs,2);
        if ~(any(isnan(tc.allTcs(:,j,i)))) % empty trials have NaNs
            if tc.settings.legend==0
                % color all trials according to condition
                colors = [colors {tc.trials.condColors{i}}];
            end
            selectedTrials = [selectedTrials tc.allTcs(:,j,i)];
        end
    end
end

render3DTraces(selectedTrials,colors);
xlabel('Trial time, frames');
ylabel('Trials');
zlabel('% Signal');
view(0,0);
grid on
rotate3d

return
