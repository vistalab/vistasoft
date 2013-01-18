function tc = tc_reorderCondNums(tc,newOrder);
% 
% tc = tc_reorderCondNums(tc,[newOrder]);
%
% Specify a new order for non-null conditions.
% If not specified, will pop up a UI.
%
%
%
% ras 03/05.
if notDefined('tc'),    tc = get(gcf,'UserData');		end


if notDefined('newOrder')
    % put up a dialog
    nums = tc.trials.condNums;
    names = tc.trials.condNames;
    def = {num2str(nums)};
    prompt{1} = 'New Condition # Order [Current Order: ';
    for i = 1:length(names)
        prompt{1} = [prompt{1} num2str(nums(i)) ') ' names{i} ' '];
    end
    prompt{1} = [prompt{1} ']'];
	dlgTitle='Reorder Conditions';
	answer=inputdlg(prompt,dlgTitle,1,def);
    newOrder = str2num(answer{1});
end

% if the null isn't included, put it first:
if ~ismember(newOrder, 0)
	newOrder = [0 newOrder];
end


%% need to actually change the condition numbers in the event
%% specification...tricky...
% first, make all the conditions negative. We don't allow negative
% condition specification, so these won't be confused in the shuffling
tc.trials.cond = -(tc.trials.cond + 1); % null is -1, down from there

% now, map each original value to the new value
for c = 1:length(newOrder)
	I = find(tc.trials.cond == -c);
	tc.trials.cond(I) = newOrder(c);
end


% get the indexing needed to produce this
% new order:
% [ignore ind] = sort(newOrder);
newOrder = newOrder + 1; % just account for null

% now change the labels, colors etc.
tc.trials.condNums = tc.trials.condNums(newOrder);
tc.trials.condNames = tc.trials.condNames(newOrder);
tc.trials.condColors = tc.trials.condColors(newOrder);

tc = tc_recomputeTc(tc, 1);

if checkfields(tc, 'ui', 'legend') & ishandle(tc.ui.legend)
	tc = tc_legend(tc); % update the legend w/ new colors
end

set(gcf,'UserData',tc);

timeCourseUI;

return
