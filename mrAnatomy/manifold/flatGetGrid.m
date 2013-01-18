function val = flatGetGrid(gridPoints,param)
%
%  val = flatGetGrid(gridPoints,param)
%
%Author: Wandell
%Purpose:
%   Get parameters from all of the gridPoints(:).
%   Current parameters are 'loc' (desired 2D grid locations)
%        err, idx, and dist
%

if ieNotDefined('param'), error('You must specify a gridPoints parameter'); end

nGrid = length(gridPoints);

switch lower(param)
    case 'loc'
        for ii=1:nGrid
            val(ii,:) = gridPoints(ii).loc;
        end
    case 'err'
        for ii=1:nGrid
            val(ii) = gridPoints(ii).err;
        end
    case 'idx'
        for ii=1:nGrid
            val(ii) = gridPoints(ii).idx;
        end
    case 'dist'
        for ii=1:nGrid
            val(:,ii) = gridPoints(ii).dist;
        end
    otherwise
        error('Unknown parameter');
end
return;
