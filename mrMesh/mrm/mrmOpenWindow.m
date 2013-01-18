function windowID = mrmOpenWindow(host,windowID)
%
%  windowID = mrmOpenWindow(host,windowID)
%
%Author: Wandell
%Purpose:
%   Open a window with number windowID on the host.  
%  
%   windowID = mrmOpenWindow;
%   windowID = mrmOpenWindow([],1);
%
% See code for many things TODO.

if ieNotDefined('host'), host = 'localhost'; end
if ieNotDefined('windowID'), windowID = -1; end


if windowID < 0
    % If there is no assigned window, let's get the next one in the list.  If
    % we leave it up to mrMesh, it will count from the last opened window and
    % the numbers increase without bounds.
    %  So the code here should be
    %   windowID = mrmGet(host,windowID,'nextwindowID');
    %   The code in mrmGet should be
    %       lst = mrMesh(host,windowID,'openwindowlist');
    %       Then find an unused number and go.
    %   We should also be able to assign the mesh name to the window title
    %   bar.
    % No way to do this yet because we can't query mrMesh about the
    % currently open windows.
    %
end

[windowID,status,res] = mrMesh(host, windowID, 'refresh'); 

if (status == -1000)
    fprintf('Starting mrMesh server and opening window.');
    windowID = mrmStart(windowID,host);
end

return;
