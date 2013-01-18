function [scaledSel, sel, prefCond] = mv_selectivity(mv, conditions, shiftBaseline);
% [scaledSel sel, prefCond] = mv_selectivity(mv, <conditions=all>, <shiftBaseline=1> );
%
%
% Compute the selectivity index for a multi-voxel UI, given the selected
% conditions and threshold.
%
% Selectivity is defined as:
%   sel = (max - nonmax) / (max + abs(nonmax))
% where [max] is the amplitude of response to the "preferred" condition --
% by definition, the condition which produced the maximal response;
% [nonmax] is the set of response amplitudes to all other selected
% conditions. Response amplitudes are computed according the to
% event-related paramter 'ampType': see er_setParams, er_defaultParams.
%
% In addition to coding the degree of response, this also encodes the
% preferred condition in the following manner: if the first selected
% condition is preferred, the map ranges from 0-1; if the second, from 1-2;
% and so on. In general, the main value of the map is 
%   (preferred condition-1) + sel.
%
% 'shiftBaseline': use the correction suggested by Alex Martin to enforce
% non-negative amplitudes, by shifting the amplitudes for such voxels to
% ensure they're positive. Default is 1.
%
% ras 05/06: broken off of mv_exportSelectivity into a separate function.

if notDefined('conditions'), 
    conditions = mv.trials.condNums(mv.trials.condNums>0); 
end
if notDefined('shiftBaseline'), shiftBaseline = 1; end


mv.params.selConds = conditions;
amps = mv_amps(mv);
nVoxels = size(amps,1);
nConds = size(amps,2);

%%%%% perform Alex Martin's correction if requested
if shiftBaseline
	mn = min(amps,[],2);
	hasNegResponse = find(mn < 0);
	offset = zeros(size(mn));
	offset(hasNegResponse) = -mn(hasNegResponse);
	offset = repmat(offset, [1 nConds]);
	amps = amps + offset;
end

%%%%% core part: compute selectivity
mx = max(amps,[],2); % max values
for i = 1:nVoxels
    if isnan(mx(i))
        prefCond(i) = 0; 
        other(i,:) = 0; 
        disp('NaN')
        continue; 
    end
    
    % preferred condition
    prefCond(i) = find(amps(i,:)==mx(i)); 
    
    % amplitudes of other conditions
    other(i,:) = amps(i,setdiff(1:nConds,prefCond(i)));
end

nonmx = mean(other,2);
sel = (mx-nonmx) ./ (mx+abs(nonmx));

scaledSel = sel + prefCond' - 1;
for i=1:nConds
    ii=find(scaledSel>i-1);
    jj=find(scaledSel(ii) <i);
    fprintf(1,'cond %i numvoxels %i\n', i, length(jj));
   
end


return
