function tc = tc_legend(tc, createFlag, sz);
%
% tc = tc_legend(tc, <createFlag=0>, <sz=0.2>);
%
% Populate the legend uipanel of a Time Course UI with the
% current set of selected condition names and colors.
%
% If createFlag is set to 1, will create a legend uipanel, 
% and point to it in the tc.ui.legend field. Otherwise, just
% repopulates the legend with the current condition names / colors
%
%
% ras, 03/06
if notDefined('tc'),			tc = get(gcf, 'UserData');		end
if notDefined('createFlag'),	createFlag = 0;					end
if notDefined('sz'),			sz = .2;						end

if createFlag==1
    %% create side panel for legend -- can be toggled on or off
	% first remove any existing legends
	if checkfields(tc, 'ui', 'legend') & ishandle(tc.ui.legend)
		mrvPanelToggle(tc.ui.legend, 'off');
		delete(tc.ui.legend);
	end
	
	% now add the new legend panel
    tc.ui.legend = mrvPanel('right', sz);
    set(tc.ui.legend, 'BackgroundColor', get(gcf,'Color'), 'BorderType', 'none');
    
	% update the figure to have this new info
	set(gcf, 'UserData', tc);
	
else
    if ~checkfields(tc, 'ui', 'legend')
        warning('No GUI found for this time course struct.')
        return
    end
    
end

% clear any existing objects in the panel
old = findobj('Parent', tc.ui.legend);
delete(old);

% get selected conditions
sel = find(tc_selectedConds(tc));
N = length(sel);

% the legend images will be an array of subplots, with at
% most 20 rows per column:
ncols = ceil(N/20);
nrows = min(20, N);

% for each selected condition, make a patch with 
% that condition's color, and the condition name
for i = sel
    j = find(sel==i); 
    row = mod(j-1, 20) + 1;
    col = ceil(j/20);
    pos = [.8*(col-1)/ncols,  .96-row*.05,  .1,  .02];
    axes('Position', pos, 'Parent', tc.ui.legend);
    axis([0 1 0 1]); axis off; 
    set(gca, 'Box', 'off');
    hp = patch([0 1 1 0], [0 0 1 1], tc.trials.condColors{i});
    set(hp, 'EdgeColor', 'none');
    text(1.5, 1.3, tc.trials.condNames{i}, 'FontSize', 12, ...
         'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
end

% return focus to the main plot panel
if checkfields(tc, 'ui', 'plot')
	mainPlotAxes = findobj('Parent', tc.ui.plot, 'Type', 'axes');
	if ~isempty(mainPlotAxes)
		axes(mainPlotAxes(1));
	else
		axes('Parent', tc.ui.plot); cla;
	end
end

return
