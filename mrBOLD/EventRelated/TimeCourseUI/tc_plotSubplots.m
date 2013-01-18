function tc_plotSubplots(tc, plotMeanFlag, parent);
% tc_plotSubplots(tc, <plotMeanFlag=1>, <parent=tc.ui.plot panel>);
%
% Plots each condition in a separate subplot of
% the tc UI figure. If plotMeanFlag is set to 
% 1 (default), plots mean TC with error bars;
% otherwise, plots all trials.
%
% 10/04 ras.
% 03/05 changed colors so they reflect trial #
% kgs 031605 changed colors to reflect trial number 
% ras 03/16/05 amended this: will color diff't trials if 'legend'
% is selected
if nargin<1,    tc = get(gcf,'UserData');     end
if nargin<2,    plotMeanFlag = 1;             end
if nargin<3,    parent = tc.ui.plot;          end
if parent==gcf | parent==get(gcf, 'CurrentAxes')
    % make a uipanel to fit on the target
    parent = uipanel('Parent', parent, ...
                     'Units', 'normalized', ...
                     'BackgroundColor', get(gcf, 'Color'), ...
                     'Position', [0 0 1 1])
end

% params
sameAxes = 1; % if 1, will set all subplots to 
              % have the same axis bounds
columnMajor = 1;   % plot conditions along columns              

% init axes
axes('Parent', parent);
cla
% otherAxes = findobj('Parent', parent, 'Type', 'axes');
% delete(otherAxes);

conds = find(tc_selectedConds(tc));
nConds = length(conds);
nrows = ceil(sqrt(nConds));
ncols = ceil(nConds/nrows);

maxTrials = max(squeeze(sum(~isnan(tc.allTcs(1,:,conds)))));
% altColors = (tc.params.legend==1 & plotMeanFlag==0 & maxTrials < 10);
try
    altColors = tc.params.markEachTrial;
catch
    altColors = 0 % back compatibility
end

%% get peri-stimulus time sample points
t = tcGet(tc, 't');

%% main loop: plot each condition
for c = 1:nConds
    if columnMajor==1
        col = ceil(c/nrows);
        row = mod(c-1,nrows) + 1;
        pos = (row-1)*ncols + col;
    else
        pos = c;
    end
       
    subplotHandles(c) = subplot(nrows,ncols,pos);

    i = conds(c);
    cond = tc.trials.condNums(i);
    col = tc.trials.condColors{i};
    name = tc.trials.condNames{i};
    
    if plotMeanFlag==1
        htmp = errorbar(t, tc.meanTcs(:,i), tc.sems(:,i));
        set(htmp, 'Color', col, 'LineWidth', 2.5);
    else
        htmp = plot(t, tc.allTcs(:,:,i));
        if altColors==0
            set(htmp, 'Color', col, 'LineWidth', 1);
        else
            setLineColors( jet(maxTrials) );
        end
    end
    
    % indicate conditions with titles
    title(name);
    
    if tc.params.grid==1
        grid on
    end
        
    if isfield(tc.params, 'axisBounds') & ~isempty(tc.params.axisBounds)
        axis(tc.params.axisBounds);
    else
        axis tight
    end
    
    % if normalizing axis bounds, record them for this subplot
    if sameAxes==1
        allAX(c,:) = axis;
    end
end

% normalize axis bounds if selected
if sameAxes==1
    maxAX = [allAX(1,1) allAX(1,2) min(allAX(:,3)) max(allAX(:,4))];
    for c = subplotHandles
        subplot(c);
        axis(maxAX);
        axis off
    end
    if columnMajor==1
        corner = nrows;
    else
        corner = (nrows-1)*ncols + 1;
    end
    subplot(subplotHandles(corner)); axis on; set(gca, 'Box', 'off');
end

% label only appropriate subplots
for c = 1:nConds
    subplot(subplotHandles(c));
    if columnMajor==1
        if ceil(c/nrows)==1
			ylabel('% Signal');
        end
        if mod(c-1, nrows)+1==nrows
        	xlabel('Trial time, secs');          
        end
    else
        if mod(c, ncols)==1
			ylabel('% Signal');
        end
        if ceil(c/nrows)==nrows
        	xlabel('Trial time, secs');          
        end
    end
end

% indicate the peak and baseline periods, if selected
if tc.params.showPkBsl==1
    for c = 1:nConds
        subplot(subplotHandles(c));
        hold on
        AX = axis;
        plot(tc.bslPeriod, repmat(AX(3), size(tc.bslPeriod)), ...
            'k', 'LineWidth', 3);
        plot(tc.peakPeriod, repmat(AX(4), size(tc.peakPeriod)), ...
            'r', 'LineWidth', 4);	
    end
end

if altColors==1
% 	% add legend that indicates trial number to last subject plot
	for j=1:tc_numTrials(tc)
        legendtext{j} = num2str(j);
    end
    
	hleg = legend(legendtext, -1);
    legend(hleg, 'Boxoff', 'Location', 'BestOutside')
    
%     axes(hleg)
%     xlabel('Trial #')
%     legendPanel(legendtext);
end

% add the handles to the user data
tc.ui.subplotHandles = subplotHandles;
set(gcf, 'UserData', tc);


return
