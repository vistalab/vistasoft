function mv = mv_groupConditions(mv, groups, names, colors);
%
% mv = mv_groupConditions(mv, groups, names, colors);
%
% Group conditions together in a MultiVoxel analysis.
% Groups should be a cell array of vectors, specifying which
% conditions should be grouped together in the new mv struct.
% Conditions not included in groups will be kept as separate conditions.
%
% Example: 
% mv2 = mv_groupConditions(mv, {[1 2] [3 4]}, {'Obj' 'Scrambled'}, {'r' 'k'});
%
% ras, 03/01/07.
if notDefined('mv'), mv = get(gcf, 'UserData'); end

if notDefined('groups') | isequal(groups, 'dialog')
	[groups names colors] = groupConditionsDialog(mv);
end

if notDefined('names')
	for i = 1:length(groups)
		names{i} = sprintf('Group %i', i);
	end
end

if notDefined('colors')
	colors = mv.trials.condColors(1:length(groups));
end

% group conditions in each group together
% (to avoid confusion between the old cond nums and the new, target
% cond nums, we first assign each new cond a negative, then multiply by
% -1)
for i = 1:length(groups)
	tgtConds = find( ismember(mv.trials.cond, groups{i}) );
	mv.trials.cond(tgtConds) = -i;
end

% find any remaining (positive) numbers, and assign them to the 
% remaining condition numbers
leftOver = find(mv.trials.cond > 0);
remainingConds = unique(mv.trials.cond(leftOver));

for i = 1:length(remainingConds)
	newVal = -1 * (length(groups) + i);  
	mv.trials.cond(mv.trials.cond==remainingConds(i)) = newVal;
	
	% grab the color/name of this leftover condition as well
	names = [names mv.trials.condNames{remainingConds(i)+1}];
	colors = [colors mv.trials.condColors{remainingConds(i)+1}];
end

% now, assign all to positive
mv.trials.cond = -1 * mv.trials.cond;

% ensure the null condition name/color is preserved
nNewConds = length( unique(mv.trials.cond) );
if length(names) < nNewConds | length(colors) < nNewConds
	names = [mv.trials.condNames{1} names];
	colors = [mv.trials.condColors{1} colors];
end


% assign new cond names, colors
mv.trials.condNums = unique(mv.trials.cond);
mv.trials.condNames = names;
mv.trials.condColors = colors;

% if there's a GUI open, update
if checkfields(mv, 'ui', 'fig')
	set(mv.ui.fig, 'UserData', mv);
	
	% redo the conditions menu
	delete(mv.ui.condMenuHandles);
	mv.ui.condMenuHandles = mv_condMenu(mv, mv.ui.condMenu);
end

% re-chop time series according to this new group
mv.voxData = er_voxDataMatrix(mv.tSeries, mv.trials, mv.params);

% re-apply analyses which may have been done
if isfield(mv, 'glm')
	mv = mv_applyGlm(mv);
end



return
% /------------------------------------------------------------------/ %



% /---------------------------------------------------------------/ %
function hc = mv_condMenu(mv,h);
% Update conditions menu to reflect new condition groups

% Callback for all menu items:
% umtoggle(gcbo);
% mv_legend(get(gcf, 'UserData'));
% timeCourseUI; 
accelChars = '0123456789-=|';
cb = ['umtoggle(gcbo); mv_legend(get(gcf,''UserData'')); timeCourseUI; '];
for i = 1:length(mv.trials.condNames)
    if i < length(accelChars)
        accel = accelChars(i);
    else
        accel = '';
    end
    
    if isempty(mv.trials.condNames{i})
        mv.trials.condNames{i} = num2str(i);
    end
    
    hc(i) = uimenu(h, 'Label', mv.trials.condNames{i}, ...
                 'Separator', 'off', 'Checked', 'on', ...
                 'Accelerator', accel, ...
                 'Tag', mv.trials.condNames{i}, ...
                 'UserData', mv.trials.condNums(i), ...
                 'Callback', cb);
end

% unselect the null condition if there is one
if any(mv.trials.condNums==0)
    null = find(mv.trials.condNums==0);
    set(hc(null), 'Checked', 'off');
end    

return
% /---------------------------------------------------------------/ %



% /------------------------------------------------------------------/ %
function [groups, names, colors] = groupConditionsDialog(mv);
% get the condition groups from a dialog
% (we try to keep the null condition from being included in this, so it
% stays null)
dlg(1).fieldName = 'groups';
dlg(1).style = 'edit';
dlg(1).string = 'Enter condition groups as cell: ''{[1 2] [3 4]}''';
dlg(1).value = sprintf('{%s}', num2str(mv.trials.condNums(2:end)));

names = '';  colors = '';
for i = 2:length(mv.trials.condNums)
	names = [names ' ''' mv.trials.condNames{i} ''''];
	colors = [colors ' ''' mv.trials.condColors{i} ''''];
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