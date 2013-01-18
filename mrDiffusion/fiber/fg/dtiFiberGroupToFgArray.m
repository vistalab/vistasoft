function fgArray=dtiFiberGroupToFgArray(fg)
% Convert a Fiber Group with multiple subgroups into an array of
% fiber groups
%
%   fgArray = dtiFiberGroupToFgArray(fg)
%
%
% We can represent a fiber group in 2 ways.
% Fiber group array means that each subgroup of fibers is its own entry
% into the cell array
% The other way is to keep all the fibers in 1 fiber group structure and
% indicate which subgroup each fiber goes with in the field fg.subgroup.
% fg.subgroup is a 1xN vector of integers where N is the number of fibers.
% Each unique integer corresponds to a different subgroup.  There should
% also be another field fg.subgroupNames which is a 1XN array where each
% array entry has 2 fileds. subgroupIndex and subgroupName which give the
% name of the subgroup corresponding to each index number.
%
% Cell arrays of fiber groups are used pricipally by GUI functions, whereas
% a fiber group with subgroup field is as the preffered represenation for
% many scripts. Names are assigned based on subgroup names.
%
% Example:
%  fg = dtiLoadFiberGroup('myFiberGroup.mat');
%  fgArray = dtiFiberGroupToArray(fgArray);
%
% See also: dtiFgArrayToFiberGroup
%
% (c) Stanford VISTA Team, 2010

if ~isfield(fg, 'subgroup')
    fgArray=fg;
    return
end

subgroupVals = unique(fg.subgroup);

% Create an array of fiber groups.  Each one corresponds to a single name
% type of fibers.  The name is attached.

for iFG=1:length(subgroupVals)
    fgArray(iFG) = fg;
    fgArray(iFG).fibers = fg.fibers(fg.subgroup==subgroupVals(iFG));
    fgArray(iFG).name = [fgArray(iFG).name '--' ...
        fg.subgroupNames(vertcat(fg.subgroupNames(:).subgroupIndex)==subgroupVals(iFG)).subgroupName];
    
end

fgArray = rmfield(fgArray, {'subgroup', 'subgroupNames'});

return
