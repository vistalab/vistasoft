function status = mrmCloseWindow(windowID,host)
%  Close a window on the host. 
%
%   status = mrmCloseWindow(windowID,host)
%
% Example:
%  status = mrmCloseWindow(6,'localhost')
%  status = mrmCloseWindow(windowID,'localhost')
%  status = mrmCloseWindow(windowID)
%
% BW (c) Stanford VISTASOFT Team, many years ago

if ieNotDefined('host'), host = 'localhost'; end

[windowID,status,res] = mrMesh(host, windowID, 'close'); 

return;
