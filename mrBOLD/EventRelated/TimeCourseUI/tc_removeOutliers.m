function tc = tc_removeOutliers(tc, criterion, thresh, action, plotFlag);
%
% tc = tc_removeOutliers([tc], [criterion, thresh, action]);
%
% Remove outlier points / trials / events from a time course.
%
% INPUTS:
% tc: time course struct.
%
% criterion: flag for which criterion to use to determine outlier points.
%   0 -- find time points a certain number of standard deviations
%       (abs. value) from the mean;
%   1 -- find time points whose absolute value exceeds a certain threshold
%        value.
%
% thresh: value to use as the threshold (in # of standard deviations,
% if the criterion is 0, or the units of tc.wholeTc if criterion is 1).
%
% action: flag describing which action to take for outlier points:
%   1 -- interpolate between the surrounding time points.
%   2 -- remove the event during which the outlier data occurs from
%        the trials struct. Does not modify the time course data itself,
%        but modifies the trials information.
%   3 -- append points to a field params.outliers subfield, containing
%        information on the outlier time and the event to which it
%        belonged, to be considered by future analyses. This doesn't
%        modify either the time course data or the trials information,
%        but I haven't yet written any code that parses this information.
%
% If any of the last 3 arguments are omitted, a dialog is brought up.
% plotFlag - 1 is for plotting, zero is for no plotting (scripts)
%
% 11/2/2005 by ras.
if notDefined('tc'), tc = get(gcf,'UserData'); end
if notDefined('plotFlag'), plotFlag = 1; end

if notDefined('criterion') || ...
        notDefined('thresh') || ...
        notDefined('action') % #ok<OR2>
    % dialog
    ui(1).string = 'Threshold value:';
    ui(1).fieldName = 'thresh';
    ui(1).style = 'edit';
    ui(1).value = '3';

    ui(2).string = 'Criterion:';
    ui(2).fieldName = 'criterion';
    ui(2).list = {'Standard Deviations from Mean' 'Absolute % Signal'};
    ui(2).style = 'popup';
    ui(2).value = 1;

    ui(3).string = 'Action to take for outliers?';
    ui(3).fieldName = 'action';
    ui(3).style = 'popup';
    ui(3).list = {'Replace data point with interpolated neighbors' ...
        'Remove event from trials struct' ...
        'Mark outliers in params.outliers subfield'};
    ui(3).value = 1;

    resp = generalDialog(ui,'Remove Outliers');
    thresh = str2num(resp.thresh);
    criterion = cellfind(ui(2).list, resp.criterion)-1;
    action = cellfind(ui(3).list, resp.action);
end

% find outliers, based on specified criterion
switch criterion
    case 0, % find time points w/ mean > thresh std. deviations from
        sigma = nanstd(tc.wholeTc);
        mu = nanmean(tc.wholeTc);
        positiveOutliers = find(tc.wholeTc > mu + thresh*sigma);
        negativeOutliers = find(tc.wholeTc < mu - thresh*sigma);
        outliers = [positiveOutliers negativeOutliers];

    case 1, % find time points greater than threshold value
        outliers = find(abs(tc.wholeTc) > thresh);

end

% if no outliers, hooray!
if isempty(outliers)
    disp('tc_removeOutliers: No Outliers! Hooray!')
    return
end

% check that not ALL time points are outliers...
if length(outliers)==length(tc.wholeTc)
    msg = ['Warning: Given the selected criteria, ALL time points '...
        'were found to be outliers! No action taken.'];
    mrMessage(msg);
    return
end

% do what the selected action says
switch action
    case 1, % remove point, replacing w/ average of neighbors
        for ii = outliers(:)'
            % find nearest non-outlier neighbors
            nFrames = length(tc.wholeTc);
            a = ii - 1; while ismember(a,outliers) && (a>1), a=a-1; end
            b = ii + 1; while ismember(b,outliers) && (b<nFrames), b=b+1; end

            % Without this there is a bug if the last frame is an outlier. 
            if b>nFrames, b=a; end 
            tc.wholeTc(ii) = 0.5 * (tc.wholeTc(a)+tc.wholeTc(b));
        end

        % re-chop the tSeries
        if plotFlag,     tc = tc_recomputeTc(tc,1);
        else             tc = tc_recomputeTc(tc,1,0);
        end

    % this is not done in a satisfactory way. removing an event, in the
    % current setup, extends the previous event. if this is fixation, not
    % too bad (though still wrong). if its a different condition, even
    % worse (since we are including the outlier, which was in fixation
    % block, as part of the experimental block preceding it).
    % we may want to assign it a new cond number, for example,
    % tc.trials.cond = -1. which will mean "not defined".
    case 2, % remove entry for event in trials
        rmEvents = [];
        for thisOutlier = outliers(:)'
            % Find all the onset frame just before this outlier.  
            jj = find(tc.trials.onsetFrames < thisOutlier);
            
            % If there are any, add the last onset frame (i.e., the one
            % prior to the outlier) to the list of events that will be
            % removed.  The events are first positive, then negative
            % outliers.
            if ~isempty(jj), rmEvents = [rmEvents jj(end)]; end 
        end
        nEvents = length(tc.trials.cond);
        ok = setdiff(1:nEvents, unique(rmEvents));

        tc.trials.cond        = tc.trials.cond(ok);
        tc.trials.onsetSecs   = tc.trials.onsetSecs(ok);
        tc.trials.onsetFrames = tc.trials.onsetFrames(ok);
        tc.trials.label       = tc.trials.label(ok);
        tc.trials.run         = tc.trials.run(ok);

        % re-chop the tSeries
        if plotFlag,    tc = tc_recomputeTc(tc,1);
        else            tc = tc_recomputeTc(tc,1,0);
        end

    case 3, % note where the outliers are, but take no other action
        rmEvents = [];
        for ii = outliers(:)'
            jj = find(tc.trials.onsetFrames<ii);
            if ~isempty(jj), rmEvents = [rmEvents jj(end)]; end
        end

        tc.params.outliers.frames = outliers;
        tc.params.outliers.secs = outliers .* tc.trials.TR;
        tc.params.outliers.events = rmEvents;
end

% report on results
fprintf('%i Outlier Time Points Found. \n',length(outliers));

% refresh
if plotFlag, timeCourseUI; end


return
