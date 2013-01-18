function mv = mv_reorderCondNums(mv,newOrder);
% 
% mv = mv_reorderCondNums(mv,[newOrder]);
%
% Specify a new order for non-null conditions.
% If not specified, will pop up a UI.
%
%
%
% ras 03/05.
if notDefined('mv'),    mv = get(gcf,'UserData');		end
if ishandle(mv),		mv = get(mv, 'UserData');		end

if notDefined('newOrder')
    % put up a dialog
    nums = mv.trials.condNums;
    names = mv.trials.condNames;
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
mv.trials.cond = -(mv.trials.cond + 1); % null is -1, down from there

% now, map each original value to the new value
for c = 1:length(newOrder)
	I = find(mv.trials.cond == -c);
	mv.trials.cond(I) = newOrder(c);
end


% get the indexing needed to produce this
% new order:
% [ignore ind] = sort(newOrder);
newOrder = newOrder + 1; % just account for null

% now change the labels, colors emv.
mv.trials.condNums = mv.trials.condNums(newOrder);
mv.trials.condNames = mv.trials.condNames(newOrder);
mv.trials.condColors = mv.trials.condColors(newOrder);

set(gcf,'UserData',mv);

multiVoxelUI;

return
