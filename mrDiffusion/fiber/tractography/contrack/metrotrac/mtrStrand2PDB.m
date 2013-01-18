function [strand_info, fg] = mtrStrand2PDB(strand_dirname,pdbFile)
%Create PDB from NFG strand directory
%
%   [strand_info, fg] = mtrStrand2PDB(strand_dirname,pdbFile)
%
%   strand_dirname: Directory containing strand files.
%   pdbFile: Output pdb filename.
%   strand_info: Information fields containing [strand ID, radius, 
%     bundle ID].
%   fg: Fiber group of PDB file.
%
% NOTES: 

% Convert into pdb format
[fg,strand_info] = nfgLoadStrands(strand_dirname);
% Write out pdb file
if ~ieNotDefined('pdbFile')
    fg = dtiCreateQuenchStats(fg,'Length','Length', 1);
    mtrExportFibers(fg,pdbFile,eye(4));
end

return;

