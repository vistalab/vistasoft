function value = nfgGetName(name,phantomDir)
%Get standard names for BlueMatter NFG tests
%
%   value = nfgGetName(name)
%
% Mostly stores directory and file names.
%
% AUTHORS:
%   2009.08.05 : AJS wrote it
%
% NOTES: 

% Suppress variable may not be used warning
%#ok<*NASGU>

% Directories
rawDir = fullfile(phantomDir,'bluematter','raw');
paramDir = fullfile(phantomDir,'parameters');
strandDir = fullfile(phantomDir,'strands');
dtDir = fullfile(phantomDir,'bluematter','dti66');
trkDir = fullfile(phantomDir,'bluematter','trackvis');
binDir = fullfile(dtDir,'bin');
fiberDir = fullfile(dtDir,'fibers');
roiDir = fullfile(dtDir,'ROIs');
volcheckDir = fullfile(dtDir,'volcheck');
testcoordsDir = fullfile(phantomDir,'test_coords');
teststrandsDir = fullfile(testcoordsDir,'strands');
tempFiberDir = fullfile(fiberDir,'temp');
% Raw Image Files
cleanImgFilter = fullfile(phantomDir,'clean','dwi-*.img'); 
noisyImgFilter = fullfile(phantomDir,'noisy','dwi-*.img');
cleanImg = fullfile(rawDir,'dwi-clean.nii.gz');
noisyImg = fullfile(rawDir,'dwi-noisy.nii.gz');
% Post-processed Image Files
brainMaskFile = fullfile(dtDir,'bin','brainMask.nii.gz');
volExFile = fullfile(binDir,'b0.nii.gz');
b0File = fullfile(binDir,'b0.nii.gz');
tensorsFile = fullfile(binDir,'tensors.nii.gz');
% Imaging Sequence Files
nfgGradFile = fullfile(paramDir,'grad_directions.txt');
bvalsFile = fullfile(rawDir,'dwi-noisy.bvals');
bvecsFile = fullfile(rawDir,'dwi-noisy.bvecs');
% ROIs
gmROIFile = fullfile(binDir,'gm.nii.gz');
wmROIFile = fullfile(binDir,'wm.nii.gz');
% Tracking Files
ctrparamsFile = fullfile(fiberDir,'ctr_params.txt');
bmScriptFile = ['runBM_' phantomDir '.sh'];
bmLogFile = ['logBM_' phantomDir '.txt'];
% mrDiffusion Files
dtFile = fullfile(dtDir, 'dt6.mat');
% TrackVis Files
trkGradFile = fullfile(trkDir,'grad.txt');
trkImg = fullfile(trkDir,'dwi-noisy-trk.nii.gz');
trkHardiMatFile = fullfile(trkDir,'recon_mat.dat');
trkOdfReconRoot = fullfile(trkDir,'recon_out');
trkTRKFile = fullfile(trkDir,'tracks.trk');
trkPDBFile = fullfile(fiberDir,'trk.pdb');
trkBMPDBFile = fullfile(fiberDir,'trk_bm.pdb');
trkECullPDBFile = fullfile(fiberDir,'trk_ecull.pdb');
trkPidsDir = fullfile(fiberDir,'pids_trk');
gold_trkPDBFile = fullfile(fiberDir,'gold_trk.pdb');
% Fiber Names and Directories
% Gold
goldPDBFile = fullfile(fiberDir,'gold.pdb');
goldPidsDir = fullfile(fiberDir,'pids_gold');
goldInfoFile = fullfile(fiberDir,'gold_info.mat');
% TEND
tendPDBFile = fullfile(fiberDir,'tend.pdb');
tendBMPDBFile = fullfile(fiberDir,'tend_bm.pdb');
% STT
sttPDBFile = fullfile(fiberDir,'stt.pdb');
sttBMPDBFile = fullfile(fiberDir,'stt_bm.pdb');
sttECullPDBFile = fullfile(fiberDir,'stt_ecull.pdb');
sttBMBfloatFile = fullfile(fiberDir,'stt_bm.Bfloat');
sttPidsDir = fullfile(fiberDir,'pids_stt');
% Gold and STT
gold_sttPDBFile = fullfile(fiberDir,'gold_stt.pdb');
% CTR
ctrPidsDir = fullfile(fiberDir,'pids_ctr');
ctrBMPDBFile = fullfile(fiberDir,'ctr_bm.pdb');
% Misc
bashExe = '/bin/bash';

% PBC
pbcScanParamsDir = fullfile(phantomDir,'RawData','DiffusionData','ScannerParameters');
f = dir(fullfile(pbcScanParamsDir,'bvals*'));
pbcGradValsFile = fullfile(pbcScanParamsDir,f.name);
f = dir(fullfile(pbcScanParamsDir,'bvecs*'));
pbcGradVecsFile = fullfile(pbcScanParamsDir,f.name);
pbcRawDataDir = fullfile(phantomDir,'PreProcessing','FSLResults','EddyCorrected');
f = dir(fullfile(pbcRawDataDir,'brain*hdr'));
pbcRawDataFile = fullfile(pbcRawDataDir,f.name);



if ~ischar(name)
    error('Error: nfgGetName accepts string inputs only!');
end
if ~isvarname(name)
    error(['Error: ' name ' is not a valid variable name!']);
end

value = eval(name);

return;