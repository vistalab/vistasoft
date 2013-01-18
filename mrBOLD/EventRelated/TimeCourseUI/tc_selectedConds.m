function sel = tc_selectedConds(tc);
% sel = tc_selectedConds(tc);
%
% goes through the conditions menu on the tc figure,
% parsing which conditions are selected for plotting 
% and which aren't, returning a binary index vector
% of length nConds.
%
% 02/23/04 ras: broken off as a separate function (previously kept in
% ras_tc).
if checkfields(tc,'ui','condMenuHandles') & ishandle(tc.ui.condMenuHandles(1))
    for i = 1:length(tc.ui.condMenuHandles) 
        state = get(tc.ui.condMenuHandles(i), 'Checked');
        sel(i) = isequal(state,'on');
    end
else
    % no UI: first check if there's a params.selConds field
    if checkfields(tc,'params','selConds')
    
        sel = logical(zeros(size(tc.trials.condNums)))
        sel(tc.params.selConds+1) = 1
    else
        %  select all non-null conds
        sel = (tc.trials.condNums>0);
    end
end
return
