function serverStarted = quenchCheckServer(host)
%
%     serverStarted = quenchCheckServer(host)
%
% Author: dakers
% Purpose:
%   Test whether the Quench application has been started.
%   
% mrmCheckServer

if(~exist('host','var')||isempty(host)) host = 'localhost:4001'; end

stat = mrMesh(host, 999, 'ping'); 

% If the status is not -1000, the window opened and the server is there.
% So, close the window and return.
if stat ~= -1000 
    serverStarted = 1;
    return;
else
    serverStarted = 0;
end

return;
