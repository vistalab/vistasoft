% Clear the statistics information within the fiber group
%
%   fg=dtiClearQuenchStats(fg)
% 
% Returns the cleared fiber group.
% 
% HISTORY:
% 2009.06.17 : AJS wrote it.
%

function fg=dtiClearQuenchStats(fg)
fg.params = [];
fg.pathwayInfo = [];
return;