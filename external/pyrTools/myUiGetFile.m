function [filename, pathname] = myUiGetFile(browseDir, varargin)
%
% [filename, pathname] = myUiGetFile(browseDir, varargin)
%
% Wrapper for uigetfile. Will start browsing at 'browseDir' instead of pwd.
% The rest of the input args should be the normal arguments to uigetfile (see 'help uigetfile').
%
% HISTORY:
% 2002.03.05 RFD (bob@white.stanford.edu): wrote it.
% 2009.04.29 RAS: allows MultiSelect.
%
% Example:
%
% [fileName,inputGrayPath]=myUiGetFile(get(handles.inputGrayPath,'String'),'*.?ray','Get gray file');
% [fileName,inputGrayPath]=myUiGetFile(inputGrayPath,'*.?ray','Get gray file');
% [fileName,inputGrayPath]=myUiGetFile(inputGrayPath,{'*.?ray','.class'},'Gray or mesh file');
%

curDir = pwd;
if(~exist('browseDir','var')), browseDir = curDir; end

% We're slightly clever- if the browseDir is not a dir, go up one level.
% This lets us pass in a file, and browse the file's dir.
if(~exist(browseDir,'dir'))
    browseDir = fileparts(browseDir);
    if(~exist(browseDir,'dir')), browseDir = pwd; end
end

cd(browseDir);
if(~exist('varargin','var') || isempty(varargin))
    [filename, pathname] = uigetfile('multiselect', 'on');
else
    [filename, pathname] = uigetfile(varargin{:}, 'multiselect', 'on');
end
cd(curDir);

return;