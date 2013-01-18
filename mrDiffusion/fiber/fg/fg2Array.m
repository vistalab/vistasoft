function fgArray = fg2Array(fg)
% Convert a fiber group with labeled subgroups into a fiber group array
%
%   fgArray = fg2Array(fgClassified)
%
%  See also:  dtiFgArrayToFiberGroup  (rename that to fgArray2fg)
%
% (c) Stanford Vista Team 2012

nGroups = fgGet(fg,'nGroups');

% Suppose that there is an empty subgroup, we have to make sure that we
% don't lose track of a number

for jj=1:nGroups
    fgArray(jj)        = dtiNewFiberGroup;
    fgArray(jj).fibers = fg.fibers(fg.subgroup==jj);
    fgArray(jj).name   = fg.subgroupNames(jj).subgroupName;
    % NOTE:  Maybe we could use a form of fgExtract here.  At least,
    % fgExtract should be able to handle this situation, so let's make it
    % so.
end

return