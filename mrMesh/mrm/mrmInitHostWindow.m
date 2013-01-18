function msh = mrmInitHostWindow(msh)
% Initialize the host and window for a mesh.  
%
%   msh = mrmInitHostWindow(msh)
%
% The msh structure contains slots for the windowID and the local host. If
% the currently identified windowID is open and the server is running on
% the host, nothing happens.
%
% If the current windowID is not open, then a new one is opened and the
% windowID field is updated.
%
% If the server is not running and the window is not opened, both are
% started and assigned.
%
% Examples:
%   msh = viewGet(VOLUME{1},'mesh');
%   msh = mrmInitHostWindow(msh);
%
% BW (c) Stanford VISTASOFT Team, many moons ago

if ieNotDefined('msh'), error('You must define a mesh.'); end

windowID = meshGet(msh,'id'); 
host = meshGet(msh,'host');

% If the server is not started, start it with windowID 1
if ~mrmCheckServer,  windowID = mrmStart(1); end

% Open the window.
msh = meshSet(msh,'windowID',mrmOpenWindow(host,windowID)); 

return
