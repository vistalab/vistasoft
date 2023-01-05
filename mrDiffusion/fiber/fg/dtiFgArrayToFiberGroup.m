function fg=dtiFgArrayToFiberGroup(fgArray, newFgName)
%Convert an array of Fiber Groups into a fiber group with subgroups.
%
%  fg=dtiFgArrayToFiberGroup(fgArray, newFgName)
%
% Arrays of fiber groups are used pricipally by GUI functions, whereas a
% fiber group with subgroup field is as the preferred represenation for
% many scripts that ER wrote.
%
% Example:
%  fgArray = dtiReadFibers('myFiberGroupArray.mat');
%  fg = dtiFgArrayToFiberGroup(fgArray, 'My new fiber group');
%
% See also: fg2Array
%
% (c) Stanford Vistalab
%
% HISTORY: ER wrote it 11/2009
%          JDy commented it 12/2011

if ~exist('newFgName', 'var')|| isempty(newFgName)
    newFgName = 'fg'; %This was for a specific project and needs to go
end

fg = dtiNewFiberGroup(newFgName);
fg.subgroup = [];

for jj = 1:length(fgArray)
    if ~isempty(fgArray(jj)) && ~isempty(fgArray(jj).fibers)
        % add fibers from fgArray(jj) to the fiber cell array in fg.fibers
        fg.fibers = vertcat(fg.fibers, fgArray(jj).fibers);
        % fg.subgroup has a unique number that corresponds to each fiber group within
        % fg.fibers. fg.subgroup is a 1xN vector where N is the number of
        % fibers in fg.fibers
        fg.subgroup = horzcat(fg.subgroup, repmat(jj, [1 length(fgArray(jj).fibers)]));
        % fg.subgroupNames gives the corresponding name for each subgroup
        fg.subgroupNames(jj).subgroupIndex = jj;
        fg.subgroupNames(jj).subgroupName = fgArray(jj).name;
    elseif ~isempty(fgArray(jj)) && isempty(fgArray(jj).fibers)
        % if there are no fibers in the fiber group we will still create
        % the corresponding name in case we want to add fibers to this
        % subgroup later
        fg.subgroupNames(jj).subgroupIndex = jj;
        fg.subgroupNames(jj).subgroupName = fgArray(jj).name;
    end
end


return