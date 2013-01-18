function serverStarted = mrmCheckServer(host)
%Test whether the server has been started. 
%
%     serverStarted = mrmCheckServer(host)
%
% There should be a way to test without creating a new window.  But I am
% not sure how. 
%
% (c) Stanford Vista Team, 2008

if ieNotDefined('host'), host = 'localhost'; end

% Try opening a window
stat = mrMesh(host, 999, 'refresh'); 

% If the server is not started, the window won't open and we get a return
% of -1000. Otherwise, the window was properly opened.
if stat ~= -1000
    % Window was opened properly by server.  So close it and return.
    serverStarted = 1;
    mrMesh(host,999,'close');
    return;
else
    % Tell 'em that the call didn't work, so the server isn't running.
    serverStarted = 0;
end

return;