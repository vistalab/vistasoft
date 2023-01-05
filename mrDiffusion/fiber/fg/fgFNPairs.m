function voxel2FNpair = fgFNPairs(coords,node2voxel)
% Compute the (fiber,node) pairs in each of the coords
%
%   voxel2FNpair = fgFNPairs(coords,node2voxel)
%
% Explain me.  Part of the diffusion prediction code.
%
% See also: t_arcuatePlotXXX
%
% (c) Stanford VISTA Team

nFiber = length(node2voxel);

nCoords = size(coords,1);
voxel2FNpair = cell(nCoords,1);

for thisFiber=1:nFiber
    % We need to know both the nodes that pass through a voxel
    lst = (node2voxel{thisFiber}~=0);
    nodes = find(lst);

    % And we need to know which voxels they pass through
    voxelsInFiber = node2voxel{thisFiber}(lst);

    % Then we store for each voxel the (fiber,node) pairs that pass through
    % it.
    for jj=1:length(voxelsInFiber)
        voxel2FNpair{voxelsInFiber(jj)} = ...
            [voxel2FNpair{voxelsInFiber(jj)},[thisFiber,nodes(jj)]];
    end
end

return

