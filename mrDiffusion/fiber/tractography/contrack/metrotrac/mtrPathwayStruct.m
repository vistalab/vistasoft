function [o] = mtrPathwayStruct(pathMatrix)
% Returns a struct in the format used for PDB fibers (Cinch/Quench)
%
%  
% pathMatrix - I assume this is a matrix storing the fibers.  The first
% three columns are (x,y,z) coordinates in some space.
%
% It would be nice to have a definition of the structure slots here.  Maybe
% we will figure them out after improving the I/O.
%
% See also: mtrPathwayDatabase (which is the real class constructor).
%
% Stanford Vista - Sherbondy probably wrote this.  He left no comments.


if nargin == 0
    o.xpos = [];
    o.ypos = [];
    o.zpos = [];
    o.algo_type = 1;
    o.seed_point_index = 0;
    o.point_stat_array = [];
    o.path_stat_vector = [];
    o.count = 1;
else
    % Convert matrix to DTIPathway format
    o.xpos = pathMatrix(1,:);
    o.ypos = pathMatrix(2,:);
    o.zpos = pathMatrix(3,:);
    o.algo_type = 1;
    o.seed_point_index = 0;
    o.point_stat_array = [];
    o.path_stat_vector = [];
    o.count = 1;
end

return