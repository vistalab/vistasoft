function fg = fgRead(fgFile)
% Read fiber group file to create a FG structure.
%
%  fgRead([fgFile=mrvSelectFile]) 
%
% INPUTS:
%   fgFile - A fiber group on file. C
%          - Compatible file formats are:
%            a. VISTASOFT .mat and .pdb
%            b. MRTrix .tck
%            c. TrackVis .trk
%
% WEB RESOURCES:
%   mrvBrowseSVN('fgRead');
%
% EXAMPLE:
%   >> fg = fgRead('fgName.mat');
%   >> fg = fgRead('fgName.pdb')
%   >> fg = fgRead('fgName.tck')
%   >> fg = fgRead('feName.trk')
% 
% See Also:
%   fgWrite.m
% 
% 
% (C) Stanford VISTA, 2017 | Pestilli Franco

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
        fg = mtrImportFibers( fgFile );
    case '.mat'
        fg = dtiLoadFiberGroup( fgFile );
    case '.tck'
        fg = dtiImportFibersMrtrix( fgFile );
    case '.trk'
        fg = read_trk_to_fg( fgFile );
    otherwise
        error('[%s] Cannot parse file type for the tractogram.',mfilename)
end

return