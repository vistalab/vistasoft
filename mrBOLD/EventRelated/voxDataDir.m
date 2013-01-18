function pth = voxDataDir(view);
%
% pth = voxDataDir(view);
%
% Return the directory in which voxel-wise
% data is kept for the current view type/
% data type. Makes it if necessary. 
% 
% See: er_voxelData.m
%
% ras, 04/05.
pth = fullfile(dataDir(view),'VoxelData');

if ~exist(pth)
    % make it
    [p f] = fileparts(pth);
    try
        [success, msg] = mkdir(p,f);
    catch
        errmsg = sprintf('Couldn''t create voxel data dir: %s',msg)
        error(errmsg);
    end
    fprintf('Made directory %s for voxel data.\n',pth);
end

return
