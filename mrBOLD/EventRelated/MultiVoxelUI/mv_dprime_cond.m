function [dprime mapName amps varAll] = mv_dprime_cond(mv, refCond, conditions);
% [dprime mapName] = mv_dprime_cond(mv, refCond,[conditions=all]);
%
%
% Compute a 'd prime' form of selectivity index for a multi-voxel UI, 
% relative to the specified reference condition, for the selected
% conditions list.
%
% This measure of d-prime performs a series of pairwise comparisons between
% each voxel's 'preferred' condition (the condition which elicits the highest 
% response) to each of the other 'nonpreferred' conditions. For each
% comparison, it computes the 'd-prime', separation over spread, between
% those 2 conditions. This is defined (for conditions A and B) as:
%
%    d' = (refCond - meanB) / sqrt((varianceA + varianceB) / 2)
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

if notDefined('refCond')
	defaults={'1'};
	prompt = {'ref condition'};
	AddOpts.WindowStyle = 'Normal';
	AddOpts.Interpreter = 'tex';
    AddOpts.Resize = 'on';
	answer=inputdlg(prompt,'Choose reference condition for d'' calculation',1,defaults,AddOpts);
    refCond=str2num(answer{1})
end
mapName=sprintf('dprime_refcond_%d',refCond);
if notDefined('conditions'), 
    conditions = mv.trials.condNums(mv.trials.condNums>0); 
end

mv.params.selConds = conditions;
%mv = mv_blurTimeCourse(mv);
amps = mv_amps(mv);
varAll = (mv_stdev(mv)) .^ 2; % variance = sigma^2
nVoxels = size(amps,1);
nConds = size(amps,2);

%%%%% step 1: define reference condition and other conditions

AmpA = amps(:,refCond);
% amplitudes of other conditions
other = amps(:,setdiff(1:nConds,refCond));
%get variance estimates 
varA = varAll(:,refCond);
varB = varAll(:,setdiff(1:nConds,refCond));


% remove entries with NaNs
ok = ~isnan(AmpA);
AmpA=AmpA(ok);
other = other(ok,:);
varA = varA(ok,:); 
varB = varB(ok,:);

% %%%%% step 2: do pairwise comparisons
 dprime = [];
 for i = 1:size(other, 2)
     dprime(:,i) = [AmpA - other(:,i)] ./ sqrt([varA/2 + varB(:,i)/2]);
 end

% % may want to replace formula with the following
%  other=mean(other, 2); % average across all other conditions
%  
%  switch mv.params.ampType
% 	 case 'betas'
%     % do nothing
% 	% for GLM betas variances are the same for all betas do not need to
% 	% recalulate -use the first column
% 	 varB=varB(:,1);
% 	 otherwise
% 		%grab all amplitudes  across all trials .
% 		 otheramps=mv.voxAmps(:,:,mv.params.selConds);
% 		% restrict to other conditions
% 	 	otheramps = otheramps(:,:,setdiff(1:nConds,refCond));
% 		% average across other conditions for each repeat
% 		otheramps=squeeze(mean(otheramps,3)); 
% 		% calulate variance across repeats
% 		varB=std(otheramps,[],1).^2;
% 		varB=varB'; % transpose row into column
%   end


% dprime=[AmpA-other]./sqrt([varA/2+varB/2]);


  dprime = nanmean(dprime, 2);



return
