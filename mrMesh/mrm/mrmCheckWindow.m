function [windowOpen, serverStarted] = mrmCheckWindow(windowID, host)
%
%     [windowOpen, serverStarted] = mrmCheckWindow(windowID, host)
%
% Author: Wandell
% Purpose:
%   Test whether a window with id is open on the host (defaults to
%   localhost). It is further possible to test whether the server has been
%   started.  If you only care about the server, set windowID = -1;
%   
%   The (boolean) variable windowOpen specifies whether windowID is open.
%   The (boolean) variable serverStarted specifies whether the server is running.
%   
% Examples:
%    windowOpen = mrmCheckWindow(8)   
%    [windowOpen,serverStarted] = mrmCheckWindow(0)
%    [windowOpen,serverStarted] = mrmCheckWindow(9)
%    [windowOpen,serverStarted] = mrmCheckWindow(-1)

if ieNotDefined('windowID'), error('windowID required'); end
if ieNotDefined('host') host = 'localhost'; end

% Start with a negative view of the world.
windowOpen = 0; serverStarted = 0;

% Refreshing the window gives us the window and server status.
if windowID < 0
    % Certainly no such window.  How about the server?
    [windowID, stat,res] = mrMesh(host, windowID, 'refresh'); 
    if stat ~= -1000 
        serverStarted = 1;
        return;
    end
else
    [windowID, stat,res] = mrMesh(host, windowID, 'refresh');
    if stat ~= -1000, serverStarted = 1;  end
    if stat == 1, windowOpen = 1; end
end

return;