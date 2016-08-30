function fg = fgRead(fgFile)
% Read fiber group file to create a FG structure.
%
%  fgRead([fgFile=mrvSelectFile]) 
%
% INPUTS:
%   fgFile - Fiber group file. Can be a .mat file or a .pdb (Quench file).
%
% WEB RESOURCES:
%   mrvBrowseSVN('fgRead');
%
% EXAMPLE:
%   fgRead('fgName.mat');
%   fgRead('fgName.pdb')
%   fgRead('fgName.tck')
% 
% See Also:
%   fgWrite.m
% 
% 
% (C) Stanford VISTA, 2016

%% Check inputs
% Check for name variable and use fg.name if empty
if ~exist('fgFile','var') || isempty(fgFile) 
    fgFile = mrvSelectFile('r',{'pdb','mat','tck'},'Select FG File'); 
end

% Get the file type
[~,~,fileType] = fileparts(fgFile);

%% Read the file
switch fileType
    case '.pdb'
        fg = mtrImportFibers(fgFile);
    case '.mat'
        fg = dtiLoadFiberGroup(fgFile);
    case '.tck'
        fg = dtiImportFibersMrtrix(fgFile);
    otherwise
        error('[%s] Cannot parse file type for the tractogram.',mfilename)
end

return