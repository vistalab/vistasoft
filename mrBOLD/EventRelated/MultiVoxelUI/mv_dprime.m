function [dprime, prefCond] = mv_dprime(mv, conditions, verbose);
% [dprime, prefCond] = mv_dprime(mv, [conditions=all], [verbose=1]);
%
%
% Compute a 'd prime' form of selectivity index for a multi-voxel UI, given the selected
% conditions and threshold.
%
% This measure of d-prime performs a series of pairwise comparisons between
% each voxel's 'preferred' condition (the condition which elicits the highest 
% response) to each of the other 'nonpreferred' conditions. For each
% comparison, it computes the 'd-prime', separation over spread, between
% those 2 conditions. This is defined (for conditions A and B) as:
%
%    d' = (meanA - meanB) / sqrt((varianceA + varianceB) / 2)
%
% Response amplitudes are computed according the to
% event-related paramter 'ampType': see er_setParams, er_defaultParams.
%
% In addition to coding the degree of response, this also returns a list of
% the preferred condition for each category.
%
% If the verbose flag is set to 1 (default), will report how many voxels prefer each
% condition.
%
% ras 09/06: written.
if notDefined('verbose'), verbose = prefsVerboseCheck; end
if notDefined('conditions'), 
    conditions = mv.trials.condNums(mv.trials.condNums>0); 
end

mv.params.selConds = conditions;
amps = mv_amps(mv);
amps = amps(:,conditions);
varAll = (mv_stdev(mv)) .^ 2; % variance = sigma^2
nVoxels = size(amps,1);
nConds = size(amps,2);

%%%%% step 1: find preferred cond for each condition
mx = max(amps,[],2); % max values
for i = 1:nVoxels
    if isnan(mx(i)) | sum( amps(i,:)==mx(i) ) > 1
        prefCond(i) = NaN; 
        other(i,:) = NaN; 
        varA(i,:) = NaN;
        varB(i,:) = NaN;
        continue; 
    end
    
    % preferred condition
    prefCond(i) = find(amps(i,:)==mx(i)); 
    
    % amplitudes of other conditions
    other(i,:) = amps(i,setdiff(1:nConds,prefCond(i)));
    
    % get variance estimates for max, nonmax conds
    varA(i,1) = varAll(i,prefCond(i));
    varB(i,:) = varAll(i,setdiff(1:nConds,prefCond(i)));
end

% remove entries with NaNs
ok = ~isnan(prefCond);
prefCond = prefCond(ok);
other = other(ok,:);
varA = varA(ok,:); 
varB = varB(ok,:);
mx = mx(ok,:);

%%%%% step 2: do pairwise comparisons
dprime = [];
for i = 1:size(other, 2)
    dprime(:,i) = [mx - other(:,i)] ./ sqrt([varA + varB(:,i)]./2);
end

% take mean across comparisons for each voxel
dprime = nanmean(dprime, 2);

% report breakdown by condition, if requested
if verbose==1
    for i=1:nConds
        fprintf(1,'cond %i numvoxels %i\n', i, sum(prefCond==i));
    end
end

return
