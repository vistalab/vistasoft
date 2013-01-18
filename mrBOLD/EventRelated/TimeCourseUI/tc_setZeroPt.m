function tc =  tc_setZeroPt(tc, val);
% tc = tc_setZeroPt(tc, val);
%
% For Time Course UI:
%
% Set the zero value of the wholeTc in the current UI figure. If val is -1 (default), 
% will set the zero value to be the mean of the time course wholeTc overall. If it's
% zero or greater, will find all wholeTc points during trials of the specified condition,
% and set the mean value of that as the zero point. (Takes into account onset deltas
% already specified). In all cases, will simply arithmetically shift the existing wholeTc
% by the appropriate offset.
%
% 06/16/04 ras.
if ieNotDefined('val')
    val = -1;
end

tc = get(gcf,'UserData');

% check that this is an appropriate figure
if isempty(tc) | ~isfield(tc,'wholeTc')
    errmsg = 'tc_setZeroPt: This doesn''t seem to be a Time Course UI figure.';
    error(errmsg);
end

% get an offset value for the time course wholeTc,
% relevant for the specified value
if val==-1
    % use overall mean of time course
    offset = mean(tc.wholeTc)

elseif val==-2
    % use bsl period, all non-null conds
    vals = [];
    ok = find(tc.trials.cond>0);
    for j = 1:length(tc.bslPeriod)
        rng = tc.trials.onsetSecs(ok)+tc.bslPeriod(j);
        rng = rng(rng>0 & rng<length(tc.wholeTc));
        vals = [vals tc.wholeTc(rng)];
    end
    offset = mean(vals)

elseif val==-3
    % put up a dialog to get a condition, then call the
    % function again with that condition:
    q = 'What condition should be set as the 0% signal condition? ';
    resp=inputdlg(q,'Set Zero Value',1,{''});
    if isempty(resp), return; end;
    tc_setZeroPt(tc,str2num(resp{1}));
    return

elseif val==-4
    % use GLM DC components to estimate offset
    if ~isfield(tc, 'glm')
        tc = tc_applyGlm(tc);
    end
    nConds = sum(tc.trials.condNums>0);
    nRuns = length(unique(tc.trials.run));
    dcConds = nConds + [1:nRuns];
    offset = mean(tc.glm.betas(dcConds))
    
    
else
    % a condition is specified -- use only 
    % wholeTc points for trials of that condition
    if ~ismember(val,tc.trials.condNums)
        errmsg = sprintf('tc_setZeroPt: %i is not an assigned condition for this wholeTc.',val);
        error(errmsg);
    end

    % get onset seconds, corrected for onset delta
    onsetSecs = tc.trials.onsetSecs + tc.params.onsetDelta;

    % sample the condition at each TR    
    condPerTR = er_resample(tc.trials.onsetFrames,tc.trials.cond,...
                            1:length(tc.wholeTc));
    
    offset = mean(tc.wholeTc(condPerTR==val))
end

% shift the time course wholeTc
tc.wholeTc = tc.wholeTc - offset;

% recompute tc struct w/ new wholeTc
tc = tc_recomputeTc(tc,1);

% set as figure's user wholeTc
set(tc.ui.fig,'UserData',tc);

% refresh UI
timeCourseUI;

return