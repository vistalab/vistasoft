function [dtiF,dtiH] = dtiLoadHandles(dtiH,wStatus)
% Load saved handles,  open a mrDiffusion window and attach the handles
%
% [dtiF,dtiH] = dtiLoadHandles(dtiH,[wStatus = 'off'])
%
% dtiH: Handles from a mrDiffusion window or a file that contains a
%           variable with the variable dtiH
% wStatus:  String to determine whether the mrDiffusion window should stay
%           open or not.
%
% Example:
%   If you have saved a dtiH structure in a file fName, then
%    [dtiF,dtiH] = dtiLoadHandles(fName);
%   
%  Or, if you have a handle structure already then
%    [dtiF,dtiH] = mrDiffusion('off');
%    close(dtiF);
%    dtiF = dtiLoadHandles(dtiH);
%
%  or
%    dataDir = fullfile(mrvDataRootPath,'diffusion','sampleData');
%    dt6Name = fullfile(dataDir,'dti40','dt6.mat');
%    [dtiF, dtiH] = mrDiffusion('off',dt6Name);
%    save('deleteMe.mat','dtiH');
%    [dtiF2, dtiH] = dtiLoadHandles('deleteMe.mat');
%
% or
%    dataDir = fullfile(mrvDataRootPath,'diffusion','sampleData');
%    dt6Name = fullfile(dataDir,'dti40','dt6.mat');
%    [dtiF, dtiH] = mrDiffusion('off',dt6Name);
%    dtiF = dtiLoadHandles(dtiH,'on');
%
% See also:
%
% (c) Stanford VISTA team 2011

if notDefined('dtiH'), error('Handles or string to file must be passed'); end
if notDefined('wStatus'), wStatus = 'on'; end

if ischar(dtiH), load(dtiH,'dtiH'); end

% Open the window, get the figure and handles
dtiF = mrDiffusion(wStatus);

% Attach and refresh
guidata(dtiF,dtiH);

% If there are background images, refresh
if isfield(dtiH,'bg'), dtiRefreshFigure(dtiH); end

return
