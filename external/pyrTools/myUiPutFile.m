function [filename, pathname] = myUiPutFile(browseDir, varargin)
% [filename, pathname] = myUiPutFile(browseDir, varargin)
%
%
% Simple wrapper for uiputfile. Will start browsing at 'browseDir' instead of pwd.
% The rest of the input args should be what uiputfile expects (see 'help uiputfile').
%
% HISTORY:
% 2003.01.07 RFD (bob@white.stanford.edu): wrote it.

curDir = pwd;
if(~exist('browseDir','var'))
    browseDir = curDir;
end

% We're slightly clever- if the browseDir is not a dir, go up one level.
% This lets us pass in a file, and browse the file's dir.
if(~exist(browseDir,'dir'))
    browseDir = fileparts(browseDir);
    if(~exist(browseDir,'dir'))
        browseDir = pwd;
    end
end

cd(browseDir);
if(~exist('varargin','var') | isempty(varargin))
    [filename, pathname] = uiputfile;
else
    [filename, pathname] = uiputfile(varargin{:});
end
cd(curDir);

return;