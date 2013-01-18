function tc_plotMeanTrials(tc, parent, lineWidth);
% tc_plotMeanTrials(tc, <parent=tc.ui.plot panel>, <lineWidth=2>);
%
% plots mean time courses for each condition, 
% with error bars (SEMs), coded by color.
%
% 02/23/04 ras: broken off as a separate function (previously kept in
% ras_tc).
% 06/04 ras: stores the sorted data in the tc struct as 'meanTcs' for
% further analyses.
% 07/04 ras: big redesign -- the means are already computed using
% er_chopTSeries; this is once again a passive plotting script.
% Also, for what it's worth, I made the line width a bit thinner.
% 08/04 ras: added ability to plot deconvolved rapid event-related data.
if notDefined('tc'),            tc = get(gcf,'UserData');     end
if notDefined('lineWidth'),    lineWidth = 2;                 end
if notDefined('parent'),		parent = tc.ui.plot;		  end

fsz = 11; % font size for labels

% init axes
delete(findobj('Parent', parent));
type = get(parent, 'type');
if isequal(type, 'axes')
	axes(parent);
elseif ismember(type, {'figure' 'uipanel'})
	axes('Parent', parent);    
end

hold on

t = tcGet(tc, 't');

for i = find(tc_selectedConds(tc))
	cond = tc.trials.condNums(i);
	col = tc.trials.condColors{i};
	htmp = errorbar(t, tc.meanTcs(:,i), tc.sems(:,i));
	set(htmp,'Color', col, 'LineWidth', lineWidth);
end
	
if tc.params.grid==1
    grid on
end

% indicate the peak and baseline periods, if selected
if tc.params.showPkBsl==1
    AX = axis;
	plot(tc.bslPeriod,repmat(AX(3),size(tc.bslPeriod)),...
        'k','LineWidth',3.5);
	plot(tc.peakPeriod,repmat(AX(4),size(tc.peakPeriod)),...
        'r','LineWidth',3.5);	
end

axis tight
if isfield(tc.params,'axisBounds') & ~isempty(tc.params.axisBounds)
    axis(tc.params.axisBounds);
end

% tuftify;
set(gca, 'TickDir', 'out', 'Box', 'off')

xlabel('Trial time, secs', 'FontWeight', 'bold', 'FontSize', fsz);
ylabel('% Signal', 'FontWeight', 'bold', 'FontSize', fsz);

return
