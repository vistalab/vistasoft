function orig_path = mrtrix_set_ld_path
% Set the library path for mrtrix libraries

% Save origional environment path
orig_path = getenv('LD_LIBRARY_PATH');
% Get mrtrix path
[status, pathstr] = system('which csdeconv');
if status~=0
    error('Please install mrtrix')
end
% This will be the path to the mrtrix libraries
pathstr = fullfile(pathstr(1:end-13),'lib');
% set the environment path
setenv('LD_LIBRARY_PATH',pathstr)