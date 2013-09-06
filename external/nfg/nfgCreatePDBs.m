function nfgCreatePDBs(phantomDir)
%Create PDBs from gold standard strands as well as STT
%
%   nfgCreatePDBs(phantomDir)
%
%   The purpose of this file is to create reference PDB files and the ROIs 
%   related to these PDBs.  The following files are create:
%   - gold.pdb: Gold standard paths from strands directory.
%   - gold_info.mat: Information, e.g., bundle ID, for gold.pdb.
%   - gm.nii.gz: GM ROI image.
%   - wm.nii.gz: WM ROI image.
%   - stt.pdb: STT pathways that have both endpoints in the GM.
%   - ctr_params.txt: Parameters file for running ConTrack.
%   - gold_stt.pdb: Gold pathways with the STT pathways for comparison.
%
% AUTHORS:
% 2009.08.05 : AJS wrote it.
%
% NOTES: 
%   * Need to add a half voxel offset to the center of the sphere because
%     we have an even number of voxels.

% Directories
binDir = nfgGetName('binDir',phantomDir);
fiberDir = nfgGetName('fiberDir',phantomDir);
roiDir = nfgGetName('roiDir',phantomDir);
% Input Files
volExFile = nfgGetName('volExFile',phantomDir);
wmROIFile = nfgGetName('wmROIFile',phantomDir);
gmROIFile = nfgGetName('gmROIFile',phantomDir);
% Output Files
ctrparamsFile = nfgGetName('ctrparamsFile',phantomDir);

% Validate existence of directories
if ~isdir(binDir)
    error('Must provide a valid path to an NFG simulation phantom!');
end
% Create fiber directory
if ~isdir(fiberDir); mkdir(fiberDir); end
% Create ROI directory
if ~isdir(roiDir); mkdir(roiDir); end

disp('Creating known sphere WM and GM ROIs ...');
nfgCreateGoldROIs(phantomDir);

disp(' '); disp('Converting NFG strands into gold PDB database ...');
nfgCreateGoldPDB(phantomDir);

disp(' '); disp('Creating ConTrack parameters file for STT and ConTrack ...');
% Global Tracking Parameters
[foo, wmFile, ext] = fileparts(wmROIFile);
wmFile = [wmFile ext];
[foo, roiFile, ext] = fileparts(gmROIFile);
roiFile = [roiFile ext];
pdfFile = 'pdf.nii.gz';
nMinNodes = 5;
nMaxNodes = 300;
vol = niftiRead(volExFile);
fStepSizeMm = min(vol.pixdim)/2;
nfgWriteConTrackParams(ctrparamsFile, binDir, wmFile, roiFile, pdfFile, nMinNodes, nMaxNodes, fStepSizeMm);

disp(' '); disp('Creating STT projectome with mrDiffusion ...');
nfgCreateSTTPDB(phantomDir, fStepSizeMm, nMinNodes, nMaxNodes);

disp(' '); disp('Creating TEND projectome with mrDiffusion ...');
nfgCreateTENDPDB(phantomDir, fStepSizeMm, nMinNodes, nMaxNodes);

disp(' '); disp('Creating HARDI projectome with mrDiffusion ...');
nfgSetupTrackvis(phantomDir);

disp('Done.');
return;
