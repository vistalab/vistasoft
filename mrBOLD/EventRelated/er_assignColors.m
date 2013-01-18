function trials = er_assignColors(trials);
%
% trials = er_assignColors(trials);
%
% Dialog to assign colors to different conditions for
% event-related analyses.
%
% written by ras, 09/2005
if ieNotDefined('trials')
    trials = er_concatParfiles(getSelectedInplane);
end

% set up an input dialog to get colors %%%%%%%%%%%%%%%%%%%
dlg(1).fieldName = 'preset';
dlg(1).style = 'popup';
dlg(1).string = 'Use a preset color map?';
dlg(1).list = {'No, manually define below...'};
dlg(1).value = 1;
presets = mrvColorMaps;
for i = 1:length(presets), dlg(1).list{i+1} = presets{i}; end
 

for i = 1:length(trials.condNums)
    dlg(i+1).fieldName = sprintf('Cond%i',i);
    dlg(i+1).style = 'edit';
    dlg(i+1).string = sprintf('%s color', trials.condNames{i});
    dlg(i+1).value = num2str(trials.condColors{i});
end

resp = generalDialog(dlg, 'Set Cond Colors...');

% exit quietly if user cancels
if isempty(resp), return; end

preset = cellfind(dlg(1).list, resp.preset);
if preset>1
    % use preset value
    map = mrvColorMaps(preset-1, length(trials.condNums));
    for i = 1:size(map,1)
        trials.condColors{i} = map(i,:);
    end
else
    % parse the rest of the responses for manual definitions
    for i = 1:length(trials.condNums)
        field = sprintf('Cond%i',i);
        vals = sscanf(resp.(field),'%f %f %f');
        trials.condColors{i} = vals';
    end
end

return