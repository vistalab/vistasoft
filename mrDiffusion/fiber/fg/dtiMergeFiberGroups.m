function mergedFG = dtiMergeFiberGroups(fg1,fg2,name)
% Merge two fiber groups
%
%   mergedFG = dtiMergeFiberGroups(fg1,fg2,[name])
%  
% The parameters are all added into a long list in the params structure.
%
% 
% Author: Dougherty, Wandell

if notDefined('fg1'), error('fg1 not defined'); end
if notDefined('fg2'), error('fg2 not defined'); end


% Merge just the fiber data
mergedFG = fg1;
mergedFG.fibers = vertcat(fg1.fibers, fg2.fibers);
if ~(~isfield(fg1, 'subgroup')||~isfield(fg2, 'subgroup'))
mergedFG.subgroup = horzcat(fg1.subgroup, fg2.subgroup);
end
mergedFG.visible = 1;
mergedFG.seeds = [];

% Do the merge of the parameters the parameters
n1 = length(fg1.params);
n2 = length(fg2.params);
for ii=1:n1, mergedFG.params{ii}=fg1.params{ii}; end
for ii=(n1+1):(n1+n2), mergedFG.params{ii} = fg2.params{ii - n1}; end

if ~exist('name','var'),  mergedFG.name = [fg1.name,'_',fg2.name '_MERGED'];
else                  
    mergedFG.name = name;
end

return;