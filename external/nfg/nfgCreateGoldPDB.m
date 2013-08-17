function [fg] = nfgCreateGoldPDB(phantomDir, bSanityCheck)
%Create gold standard PDB from NFG strands.
%
%   [fg] = nfgCreateGoldPDB(phantomDir)
%
% AUTHORS:
% 2009.08.05 : AJS wrote it.
%
% NOTES: 

if ieNotDefined('bSanityCheck'); bSanityCheck=0; end

% Directories
strandDir = nfgGetName('strandDir',phantomDir);
% Input Files
volExFile = nfgGetName('volExFile',phantomDir);
gmROIFile = nfgGetName('gmROIFile',phantomDir);
% Output Files
goldPDBFile = nfgGetName('goldPDBFile',phantomDir);
goldInfoFile = nfgGetName('goldInfoFile',phantomDir);

% Create gold PDB by converting from strands
disp(['Creating ' goldPDBFile '...']);
[strand_info, fg] = mtrStrand2PDB(strandDir,goldPDBFile);
fg.name = 'FG_GOLD';
save(goldInfoFile,'strand_info');

% Sanity check to make sure all gold standard fibers end within GM mask
if bSanityCheck
    disp('Performing sanity check on gold fibers ...');
    gm = niftiRead(gmROIFile);
    [vol] = nfgFibers2ROIImage(fg,volExFile);
    imgCheck = vol.data;
    imgCheck(gm.data>0)=0;
    if sum(imgCheck(:))>0
        error('Problem with match between gold standard PDB and GM ROI image!');
    end
end

return;
