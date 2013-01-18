function fg = dtiNewFiberGroup(name, color, thickness, visibleFlag, fibers)
% Use fgCreate instead of this - Create a new fiber group
%
% fg = dtiNewFiberGroup([name='FG-1'], [color=[20 90 200]], ...
%                [thickness=-0.5], [visibleFlag=1], [fibers=[]])
%
% Retained for compatibility
%
% HISTORY:
%   2003.10.03 RFD (bob@white.stanford.edu) wrote it.
%
% (c) Stanford VISTA Team, 2003

if(~exist('name','var') || isempty(name)),   name = 'fiber group 1'; end
if(~exist('thickness','var') || isempty(thickness)), thickness = -0.5; end
if(~exist('visibleFlag','var') || isempty(visibleFlag)), visibleFlag = 1; end
if(~exist('color','var') || isempty(color)), color = [20 90 200]; end
if(~exist('fibers','var') || isempty(fibers)), fibers = {}; end

fg.name = name;
fg.colorRgb = color;
fg.thickness = thickness;
fg.visible = visibleFlag;
fg.seeds = [];
fg.seedRadius = 0;
fg.seedVoxelOffsets = [];
fg.params = {};
fg.fibers = fibers;
fg.query_id = -1;

return;
