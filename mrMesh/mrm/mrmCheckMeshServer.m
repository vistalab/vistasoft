function [id,wasOpen] = mrmCheckMeshServer(id, host)
%
%     [id,wasOpen] = mrmCheckMeshServer(id, [host='localhohst']);
%
% Author: Ress
% Purpose:
%   Test whether a window with id is open on the host (defaults to
%   localhost). If not, start a new window is opened and its id is
%   returned. If id is set to -1, no possible window could be open so a new
%   window is opened and its value is returned in id.
%   
%   The (boolean) variable wasOpen specifies that the window numbered id
%   was open (or not).
%   
% Examples:
%    [id,wasOpen] = mrmCheckMeshServer(5);   % Checks for window 5
%    
% Notes:
%    It would be nice to really just test, and not to test and open a new
%    one.  Also, I am not sure why the pauses are there.  Must be some
%    mrMesh bogosity. (BW)

warndlg('Obsolete.  mrmCheckMeshServer')

wasOpen = 0;
if ieNotDefined('id'), id = -1; end
if ieNotDefined('host') host = 'localhost'; end
oldId = id;

% Refreshing the window with this idea gives us the status.
[id,stat,res] = mrMesh(host, id, 'refresh');

if(id<-1)
    % If the server isn't up, id should be -1000.
    wasOpen = 0;
    switch computer
        case 'PCWIN'
            srvPath = which('mrMeshSrv.exe');
            dos([srvPath ' &']);
        case 'GLNX86'
            srvPath = which('mrMeshSrv.glx');
            eval(['! ' srvPath ' &']);
        otherwise
            error(['Platform "' computer '" is currently not supported!']);
        end
        % Some annoying inter-process communication pause.  Do not remove.
    pause(2); id = mrMesh(host, -1, 'refresh'); pause(1);
elseif(stat<0)
    % this means the server is up, but the specified ID doesn't exist (user
    % probably closed the window). So, we get a new window and return that
    % new id.
    id = mrMesh(host, -1, 'refresh');
    pause(1);
else
    if(oldId>=0)
        wasOpen = 1;
    end
end

return;