function [relamps,avgTC] = tc_plotRelamps(tc, parent); 
% Calculate and plot the relative time series amplitudes for various
% experimental conditions
%
%   [relamps,avgTC] = tc_plotRelamps(tc, <parent=tc.ui.plot panel>);
%
% The model is based on Ress & Heeger, Nature Neuroscience 2000).  The
% relative amplitudes are  (after our recent edits) probably a misnomer.
% The values returned here are the percent contrast of the modulation.
%
% The model used here is this.  We assume that the basic time course of
% each condition has the same shape function, say r(t). They differ only by
% noise and a scalar, a*r(t) + N. We estimate the basic shape of the time
% course by averaging all of the conditions. This reduces the effect of the
% noise (N).  Then we compare the amplitude of the response by looking at
% the scalar (dot, inner) product of the measurements for one condition
% with respect to the estimated average. 
%
% At present, the calculation of the relative amplitude is
%
%       a =  s . r / sqrt(r.r)
%
% where r is the average set to a mean of zero, and s is the time course
% for the selected condition, also set to a mean of zero. 
%
% The logic for this is as follows.  The angle, theta, between s and r is 
%
%     cos(theta) = s.r / |s||r|
%
% The length of the projection of s onto r is |x|/|s| = cos(theta).
% Putting these together, 
%
%      |x| = |s|* (s.r) / |s||r|
%      |x| = (s.r)/|r|
%
% The |r| is the lenth of r and this is sqrt(dot(r,r,))
%
% Limitations.
% If different conditions have different time courses, this too will be
% missed by this analysis. 
%
% tc: a structure containing the time course information for an
% experiment.
%
% HISTORY
% 02/23/04 ras: wrote it. This is the first new functionality to
% timeCourseUI since incorporating it into mrLoadRet.
% 07/04 ras: now everything uses er_chopTSeries, so the relamps
% are already calculated. Nonetheless, I'm keeping the old calculations
% here, since with relamps in particular, having some conditions not
% selected may significantly change the mean time course, fundamentally
% changing the usefulness of the estimate. (e.g., if there's a baseline
% condition with a fundamentally diff't shape than other conds, disabling
% it, then recomputing makes sense.)
% 08/05 MBS, BW Comments.
% 03/06 ras, updated UI logic to work with uipanels (so you can e.g. 
% plot this as a subplot in a larger figure); also, legends are done 
% elsewhere now.
if nargin<1,    tc = get(gcf,'UserData');     end
if nargin<2,    parent = tc.ui.plot;          end
if parent==gcf | parent==get(gcf, 'CurrentAxes')
    % make a uipanel to fit on the target
    parent = uipanel('Parent', parent, ...
                     'Units', 'normalized', ...
                     'BackgroundColor', get(gcf, 'Color'), ...
                     'Position', [0 0 1 1])
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clean up existing objects in figure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
otherAxes = findobj('Type', 'axes', 'Parent', parent);
delete(otherAxes);
otherUiControls = findobj('Type', 'uicontrol', 'Parent', parent);
delete(otherUiControls);
axes('Parent', parent);
cla

% params
prestim = 1;
clipToEqual = 0;

% tx contains the frame # in tc.wholeTc at which each trial starts
tx = round([(tc.trials.onsetSecs./tc.TR)+1 length(tc.wholeTc)]);
intervals = diff(tx);

% figure out selected conditions, trials, labels, and colors
sel = find(tc_selectedConds(tc));
whichConds = tc.trials.condNums(sel);
nConds = length(whichConds);
trials = find(ismember(tc.trials.cond,whichConds));
nTrials = length(trials);

colors = tc.trials.condColors(sel);
labels = tc.trials.condNames(sel);

% initialize selTrials matrix to be NaNs of the size of the shortest trial
minInt = min(intervals(trials)) + prestim;
selTrials = NaN*ones(minInt,nTrials);

% get selected trials, avg time course of selected trials
selTrials = [];
for i = 1:nTrials
    rng = tx(trials(i))-prestim:tx(trials(i)+1)-1;
    rng = round(rng);
    rng = rng(rng>0 & rng<length(tc.wholeTc)); % clip to fit data    
    selTrials(1:length(rng),i) = tc.wholeTc(rng)';
    
    conds(i) = tc.trials.cond(trials(i));
end
avgTC = mean(selTrials,2);

% Make the average have zero mean and unit contrast
avgTC = avgTC - mean(avgTC);
avgTC = avgTC / (max(avgTC) - min(avgTC));

% normalize everything to have a mean zero
for i = 1:nTrials
    offset = mean(selTrials(:,i));
    selTrials(:,i) = selTrials(:,i) - offset;
end

% take dot product of each trial's time course w/ avg
relamps = NaN*ones(1,nTrials);
for i = 1:nTrials
    relamps(i) = dot(avgTC,selTrials(:,i));
end
relamps = relamps / sqrt(dot(avgTC,avgTC));

% get mean and stdev of each condition
for c = 1:length(whichConds)
    ind = (conds==whichConds(c));
	Y(c) = mean(relamps(ind));
	E(c) = std(relamps(ind)) ./ sqrt(sum(ind)-1);
end

% % Newer code -- but too slow:
% selTrials = tc.allTcs(:,:,sel);
% 
% % remove needless NaNs -- this is caused by 
% % having lots of null conditions and should ultimately
% % be treated by having the null condition not included
% % in er_chopTSeries*
% ok = 1:size(selTrials,2);
% for i = 1:size(selTrials,2)
%     if all(isnan(selTrials(:,i,:)))
%         ok = setdiff(ok,i);
%     end
% end
% selTrials = selTrials(:,ok,:);
% 
% relamps = er_relamps(tc.allTcs);
% Y = nanmean(relamps);
% E = nanstd(relamps) ./ sqrt(size(selTrials,2));

% figure out nice axis range
maxY = max([0 1.2*max(Y)]);
minY = min([0 1.2*min(Y)]);
AX = [0 nConds+1 minY maxY];

%%%%% plot color bars for each cond
% (gum to keep legend from being erased:)
set(gcf,'NextPlot','add');
set(gca,'Visible','off');
subplot('Position',get(gca,'Position'))
mybar(Y, E, labels, [], colors);
ylabel('Relative amplitude', 'FontWeight', 'bold', 'FontAngle', 'italic', 'FontSize', 12);
hold on

% add x-labels only if legend is off: otherwise it looks kinda ungainly
% if tc.params.legend==0
%     set(gca,'XTick',[1:nConds],'XTickLabel',labels);
% else
%     set(gca,'XTick',[]);    
% end
    
% % set axes to frame conds nicely
% axis auto;
% AX = axis;
% AX(1:2) = [0 nConds+1];
% if isfield(tc.params,'axisBounds') & ~isempty(tc.params.axisBounds)
%     AX(3:4) = tc.params.axisBounds(3:4);
% end
% axis(AX);

% append calculated relamps to tc struct
tc.relamps = relamps;
if isfield(tc,'ui')
    set(gcf,'UserData',tc);
end

return
