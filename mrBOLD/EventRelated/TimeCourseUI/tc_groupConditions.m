function tc = tc_groupConditions(tc, groups, names, colors);
%
% tc = tc_groupConditions(tc, groups, names, colors);
%
% Group conditions together in a time course analysis.
% Groups should be a cell array of vectors, specifying which
% conditions should be grouped together in the new tc struct.
% Conditions not included in groups will be kept as separate conditions.
%
% Example: 
% tc2 = tc_groupConditions(tc, {[1 2] [3 4]}, {'Obj' 'Scrambled'}, {'r' 'k'});
%
% ras, 03/01/07.
if notDefined('tc'), tc = get(gcf, 'UserData'); end

if notDefined('groups') | isequal(groups, 'dialog')
	[groups names colors] = groupConditionsDialog(tc);
end

if notDefined('names')
	for i = 1:length(groups)
		names{i} = sprintf('Group %i', i);
	end
end

if notDefined('colors')
	colors = tc.trials.condColors(1:length(groups));
end

if isempty(tc), return; end

% group conditions in each group together
% (to avoid confusion between the old cond nums and the new, target
% cond nums, we first assign each new cond a negative, then multiply by
% -1)
for i = 1:length(groups)
	tgtConds = find( ismember(tc.trials.cond, groups{i}) );
	tc.trials.cond(tgtConds) = -i;
end

% find any remaining (positive) numbers, and assign them to the 
% remaining condition numbers
leftOver = find(tc.trials.cond > 0);
remainingConds = unique(tc.trials.cond(leftOver));

for i = 1:length(remainingConds)
	newVal = -1 * (length(groups) + i);  
	tc.trials.cond(tc.trials.cond==remainingConds(i)) = newVal;
	
	% grab the color/name of this leftover condition as well
	names = [names tc.trials.condNames{remainingConds(i)+1}];
	colors = [colors tc.trials.condColors{remainingConds(i)+1}];
end

% now, assign all to positive
tc.trials.cond = -1 * tc.trials.cond;

% ensure the null condition name/color is preserved
nNewConds = length( unique(tc.trials.cond) );
if length(names) < nNewConds | length(colors) < nNewConds
	names = [tc.trials.condNames{1} names];
	colors = [tc.trials.condColors{1} colors];
end


% assign new cond names, colors
tc.trials.condNums = unique(tc.trials.cond);
tc.trials.condNames = names;
tc.trials.condColors = colors;

% if there's a GUI open, update
if checkfields(tc, 'ui', 'fig')
	set(tc.ui.fig, 'UserData', tc);
	
	% redo the conditions menu
	delete(tc.ui.condMenuHandles);
	tc.ui.condMenuHandles = tc_condMenu(tc, tc.ui.condMenu);
	
	% redo legend
	mrvPanelToggle(tc.ui.legend, 'off');
	delete(tc.ui.legend);
	tc = tc_legend(tc, 1);
end

% re-chop time series according to this new group
tc = tc_recomputeTc(tc, 1);

return
% /------------------------------------------------------------------/ %



% /---------------------------------------------------------------/ %
function hc = tc_condMenu(tc,h);
% Update conditions menu to reflect new condition groups

% Callback for all menu items:
% umtoggle(gcbo);
% tc_legend(get(gcf, 'UserData'));
% timeCourseUI; 
accelChars = '0123456789-=|';
cb = ['umtoggle(gcbo); tc_legend(get(gcf,''UserData'')); timeCourseUI; '];
for i = 1:length(tc.trials.condNames)
    if i < length(accelChars)
        accel = accelChars(i);
    else
        accel = '';
    end
    
    if isempty(tc.trials.condNames{i})
        tc.trials.condNames{i} = num2str(i);
    end
    
    hc(i) = uimenu(h, 'Label', tc.trials.condNames{i}, ...
                 'Separator', 'off', 'Checked', 'on', ...
                 'Accelerator', accel, ...
                 'Tag', tc.trials.condNames{i}, ...
                 'UserData', tc.trials.condNums(i), ...
                 'Callback', cb);
end

% unselect the null condition if there is one
if any(tc.trials.condNums==0)
    null = find(tc.trials.condNums==0);
    set(hc(null), 'Checked', 'off');
end    

return
% /---------------------------------------------------------------/ %



% /------------------------------------------------------------------/ %
function [groups, names, colors] = groupConditionsDialog(tc);
% get the condition groups from a dialog
% (we try to keep the null condition from being included in this, so it
% stays null)
dlg(1).fieldName = 'groups';
dlg(1).style = 'edit';
dlg(1).string = 'Enter condition groups as cell: ''{[1 2] [3 4]}''';
dlg(1).value = sprintf('{%s}', num2str(tc.trials.condNums(2:end)));

names = '';  colors = '';
for i = 2:length(tc.trials.condNums)
	names = [names ' ''' tc.trials.condNames{i} ''''];
	colors = [colors ' ''' tc.trials.condColors{i} ''''];
end
dlg(2).fieldName = 'names';
dlg(2).style = 'edit';
dlg(2).string = 'Enter condition names as cell: ''{''Obj'' ''Scr''}''';
dlg(2).value = sprintf('{%s}', names);

dlg(3).fieldName = 'colors';
dlg(3).style = 'edit';
dlg(3).string = 'Enter condition colors as cell: ''{''k'' [.3 .3 .7]}''';
dlg(3).value = sprintf('{%s}', colors);

resp = generalDialog(dlg);

groups = eval(resp.groups);
names = eval(resp.names);
colors = eval(resp.colors);


return

