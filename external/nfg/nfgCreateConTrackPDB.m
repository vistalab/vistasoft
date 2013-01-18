function  [fg] = nfgCreateConTrackPDB(phantomDir, fStepSizeMm, nMinNodes, nMaxNodes, bSanityCheck)
%Create ConTrack PDB
%
%   [fg] = nfgCreateSTTPDB(phantomDir, fStepSizeMm, nMinNodes, nMaxNodes,
%   bSanityCheck)
%
% AUTHORS:
% 2009.08.05 : AJS wrote it.
%
% NOTES: 

if ieNotDefined('bSanityCheck'); bSanityCheck=0; end

% Directories
binDir = nfgGetName('binDir',phantomDir);
% Input Files
dtFile = nfgGetName('dtFile',phantomDir);
wmROIFile = nfgGetName('wmROIFile',phantomDir);
% Output Files
sttPDBFile = nfgGetName('sttPDBFile',phantomDir);
ctrparamsFile = nfgGetName('ctrparamsFile',phantomDir);
gold_sttPDBFile = nfgGetName('gold_sttPDBFile',phantomDir);
goldPDBFile = nfgGetName('goldPDBFile',phantomDir);




return;