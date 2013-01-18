function [relamps,Y,E,avgTC] = eventBoldContrast(tc,selectedConds,avgTC,unitFree,plotFlag) 
% Calculate and plot the relative time series amplitudes for various
% experimental conditions
%
%   [relamps,Y,E,avgTC] = eventBoldContrast(tc,selectedConds,[avgTC],[unitFree],[plotFlag]);
%
% returns: 
% relamps: the contrast values for every event
% Y: the average contrast value per condition
% E: standard error per condition
% avgTC: the mean time course of all the events in all conditions (r, baseline
% for contrast computation)
%
% The model is based on Ress & Heeger (Nature Neuroscience, 2000).  The
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
%      |x| = (s.r)/sqrt(r.r)
%
% The |r| is the lenth of r and this is sqrt(dot(r,r,))
% Units, scaling: taking the sqrt in the denominator has the effect of keeping the
% original scale of the subject's signal. so, the units are %modulation now.
% 
% unitFree flag: if this is set to 1, we do not take the square root in the denominator.
% this leaves us with a unit less measure, but one that is more comparable
% across subjects, which can be used for a group analysis, if overall signal 
% variations are considered irrelevant.
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
% 08/05 MBS, BW Comments. also changed the way relAmps are computed - avgTC
% is normalized to mean zero and unit size
%

if ieNotDefined('tc'), error('Time course structure required'); end
if ieNotDefined('selectedConds'), selectedConds = find(tc_selectedConds(tc)); end
if ieNotDefined('avgTC'),    avgTC = []; end
if ieNotDefined('unitFree'), unitFree = 0; end
if ieNotDefined('plotFlag'), plotFlag = 1; end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clean up existing objects in figure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if plotFlag
    otherAxes = findobj('Type','axes','Parent',gcf);
    delete(otherAxes);
    otherUiControls = findobj('Type','uicontrol','Parent',gcf);
    delete(otherUiControls);
    cla
end

% params
prestim = 1;

% tx contains the frame # in tc.wholeTc at which each trial starts
tx = round([(tc.trials.onsetSecs./tc.TR)+1 length(tc.wholeTc)]);
% intervals = diff(tx);

% figure out selected conditions, trials, labels, and colors

whichConds = tc.condNums(selectedConds);
nConds = length(whichConds);
trials = find(ismember(tc.trials.cond,whichConds));
nTrials = length(trials);

colors = tc.condColors(selectedConds);
labels = tc.condNames(selectedConds);

% initialize selTrials matrix to be NaNs of the size of the shortest trial
% minInt = min(intervals(trials)) + prestim;
% selTrials = NaN*ones(minInt,nTrials);

% get selected trials, avg time course of selected trials
selTrials = [];
for i = 1:nTrials
    rng = tx(trials(i))-prestim:tx(trials(i)+1)-1;
    rng = round(rng);
    rng = rng(rng>0 & rng<length(tc.wholeTc)); % clip to fit data    
    selTrials(1:length(rng),i) = tc.wholeTc(rng)';
    conds(i) = tc.trials.cond(trials(i));
end

% normalize everything to have a mean zero
for i = 1:nTrials
    offset = mean(selTrials(:,i));
    selTrials(:,i) = selTrials(:,i) - offset;
end

% we calculate the avgTC after normalizing each trial, so its mean is set to zero too
if isempty(avgTC), avgTC = mean(selTrials,2);
else
    if length(avgTC) ~= size(selTrials,1)
        error('User supplied avgTC has length %.0f.  Should have length %.0f\n',...
            length(avgTC),size(selTrials,1));
    end
end

% take dot product of each trial's time course w/ avg
relamps = NaN*ones(1,nTrials);
for i = 1:nTrials
    relamps(i) = dot(avgTC,selTrials(:,i));
end

if unitFree % this will give Ress' measure, no units
    relamps = relamps / dot(avgTC,avgTC);
else
    % this will give a bold contrast measure
    relamps = relamps / sqrt(dot(avgTC,avgTC));
end

% get mean and stdev of each condition
for c = 1:length(whichConds)
    ind = (conds==whichConds(c));
	Y(c) = mean(relamps(ind));
	E(c) = std(relamps(ind)) ./ sqrt(sum(ind));
end

%%%%% plot color bars for each cond
% (gum to keep legend from being erased:)
if plotFlag

    % figure out nice axis range
    maxY = max([0 1.2*max(Y)]);
    minY = min([0 1.2*min(Y)]);
    AX = [0 nConds+1 minY maxY];

    set(gcf,'NextPlot','add');
    set(gca,'Visible','off');
    subplot('Position',get(gca,'Position'))
    mybar(Y,E,labels,labels,colors);
    ylabel('Relative amplitude');
    hold on

    % append calculated relamps to tc struct
    tc.relamps = relamps;
    if isfield(tc,'ui'),  set(gcf,'UserData',tc); end
end

return
