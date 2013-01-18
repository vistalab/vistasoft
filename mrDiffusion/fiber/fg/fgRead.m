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
% 
% See Also:
%   fgWrite.m
% 
% 
% (C) Stanford VISTA, 2011

%% Check inputs

% Check for name variable and use fg.name if empty
if ~exist('fgFile','var') || isempty(fgFile) 
    fgFile = mrvSelectFile('r',{'pdb','mat'},'Select FG File'); 
end

% Get the file type
if strcmp(fgFile(end-3:end),'.mat')
    type = 'mat';
end

if strcmp(fgFile(end-3:end),'.pdb')
    type = 'pdb';
end


%% Read the file

switch type
    case 'pdb'
        fg = mtrImportFibers(fgFile);
    case 'mat'
        fg = dtiLoadFiberGroup(fgFile);
end

return