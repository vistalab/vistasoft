function tc = tc_barMeanAmplitudes(tc, parent, ampType);
% tc = tc_barMeanAmplitudes(tc, <parent=tc.ui.plot panel>, <ampType=1>);
%
% plots a bar graph of mean amplitudes for each condition,
% with error bars (SEMs), coded by color.
%
% The optional 'ampType' argument specifies which amplitudes to plot (since
% there are a number of options for how to plot amplitudes). The possible
% values are:
%   1 - Plot Peak/Baseline difference of event-triggered average <default>
%   2 - Plot GLM Beta values
%   3 - Plot Dot-Product Projection Amplitudes
%   4 - Plot Peak/Baseline from deconvolved time courses
%   0 - Use the value in the tc.params.ampType field.
%
% 02/25/04 ras: adapted from tc_plotMeanTrials.
% 07/04 ras: big redesign -- the means are already computed using
% er_chopTSeries; this is once again a passive plotting script.
% 
% 07/07 kgs + kw fixed indexing error in selected conditions to ignore
% baseline condition when plotting betas
%
if notDefined('tc'),        tc = get(gcf,'UserData');     end
if notDefined('parent'),    parent = tc.ui.plot;          end
if notDefined('ampType'),   ampType = 0;                  end
if parent==gcf
    % make a uipanel to fit on the target
    parent = uipanel('Parent', parent, ...
        'Units', 'normalized', ...
        'BackgroundColor', get(gcf, 'Color'), ...
        'Position', [0 0 1 1]);
end

if isequal(get(parent, 'Type'), 'uipanel')
    axes('Parent', parent);
end

cla
hold on

lineWidth = 2;
fsz = 11;
sel = find(tc_selectedConds(tc));
colors = tc.trials.condColors(sel);
% labels = tc.trials.condNames(sel);
nums = tc.trials.condNums(sel);
for i=1:length(nums), labels{i} = num2str(nums(i)); end

%% get amplitudes Y and errors E according to ampType pref
% for 0 flag, this means use the amplitude specified in the parameters
if ampType==0 
    ampType = tc.params.ampType;
end

% depending on the ampType flag, get Y and E
switch lower(ampType)
    case {1 'meanamps' 'difference'}, % event-triggered average
        for i = sel
            nTrials = sum(~isnan(tc.amps(:,i)));
            Y(find(sel==i)) = nanmean(tc.amps(:,i));
            E(find(sel==i)) = nanstd(tc.amps(:,i)) ./ sqrt(nTrials-1);
        end
        ytxt = 'Mean Amplitude (% signal)';
        
    case {2 'betas'}, % glm betas
        if ~isfield(tc, 'glm'), tc = tc_applyGlm(tc); end
		sel = setdiff(sel, 1);   % don't need null
        Y = tc.glm.betas(sel-1);
        E = tc.glm.sems(sel-1);
        
        ytxt = '\beta';
        
    case {3 'relamps' 'projectedamps' 'dotproductamps'}, % dot-product amps
        % NYI
        
        ytxt = 'Projected Amplitude';
        
    case {4 'deconvolved'}, % deconvolved amps
        if ~checkfields(tc, 'glm') % if deconvolution was not run, run the deconvolve glm
            tc.params.glmHRF = 0;
          
            tc = tc_applyGlm(tc);
            % add a blank condition at the beginning betas are zero
            % because this is the baseline to which the glm is
            % estimated
            tc.meanTcs = [zeros(tc.glm.nh, 1) tc.glm.betas];
         end         
            % recompute amps    
            tc.params.ampType='deconvolved';
            [Y, E]=tc_amps(tc);
  
        ytxt = 'Deconvolved Amplitude (% signal)';
        
    case {5 'zscore' 'z-score'}, % Z-score
        for i = sel
            nTrials = sum(~isnan(tc.amps(:,i)));
            Y(find(sel==i)) = nanmean(tc.amps(:,i)) ./ nanstd(tc.amps(:,i));
            E(find(sel==i)) = nanstd(tc.amps(:,i)) ./ sqrt(nTrials-1);
        end
        
        ytxt = 'Z score';
        
    case {6 'meanbetas'}, % mean beta values across subjects
        % this step is conceptually the same as for the event-triggered
        % average, only now, instead of averaging across trials, we average
        % across sessions. Also, the value of each amplitude is the beta
        % coefficient for that condition/session, rather than a % signal
        % difference:
        for i = sel
            nTrials = sum(~isnan(tc.amps(:,i)));
            Y(find(sel==i)) = nanmean(tc.amps(:,i));
            E(find(sel==i)) = nanstd(tc.amps(:,i)) ./ sqrt(nTrials-1);
        end
        ytxt = 'Mean \beta (% signal)';
        
    case {7 'deconvolved'}, % mean deconvolved amplitude across subjects
        % see case 6 above.
        for i = sel
            nTrials = sum(~isnan(tc.amps(:,i)));
            Y(find(sel==i)) = nanmean(tc.amps(:,i));
            E(find(sel==i)) = nanstd(tc.amps(:,i)) ./ sqrt(nTrials-1);
        end
        ytxt = 'Mean deconvolved amplitude (% signal)';        
end

mybar(Y, E, labels, [], colors);

% set line width
htmp = findobj('Type','line','Parent',gca);
set(htmp,'LineWidth',lineWidth);

% add labels
xlabel('Condition', 'FontWeight', 'bold', 'FontSize', fsz);
ylabel(ytxt, 'FontWeight', 'bold', 'FontSize', fsz);

% set axis bounds
AX = axis;
AX(1:2) = [0 length(sel)+1];
if isfield(tc.params,'axisBounds') & ~isempty(tc.params.axisBounds)
    AX(3:4) = tc.params.axisBounds(3:4);
end
axis(AX);

cNames = tc_condInitials(tc.trials.condNames(sel));
set(gca, 'Box', 'off', 'XTick', 1:length(cNames), 'XTickLabel', cNames);
tuftify;

% grid
if tc.params.grid==1
    grid on
end

return
