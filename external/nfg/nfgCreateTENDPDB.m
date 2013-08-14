function [fg] = nfgCreateTENDPDB(phantomDir, fStepSizeMm, nMinNodes, nMaxNodes, bSanityCheck)
%Create TEND PDB using mrDiffusion
%
%   [fg] = nfgCreateTENDPDB(phantomDir, fStepSizeMm, nMinNodes, nMaxNodes,
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
tendPDBFile = nfgGetName('tendPDBFile',phantomDir);
ctrparamsFile = nfgGetName('ctrparamsFile',phantomDir);
gold_sttPDBFile = nfgGetName('gold_sttPDBFile',phantomDir);
goldPDBFile = nfgGetName('goldPDBFile',phantomDir);

% Tracking Parameters
faThresh = 0.15;
opts.stepSizeMm = fStepSizeMm;
opts.faThresh = faThresh;
opts.lengthThreshMm = [nMinNodes-1 nMaxNodes-1]*fStepSizeMm;
opts.angleThresh = 90;
opts.wPuncture = 0.2;
opts.whichAlgorithm = 3;
opts.whichInterp = 1;
opts.seedVoxelOffsets = 0.5;

% Create ROI from WM mask that has high enough FA
disp(['Creating WM ROI with FA > ' num2str(faThresh) ' ...']);
wm = niftiRead(wmROIFile);
dt = dtiLoadDt6(dtFile);
fa = dtiComputeFA(dt.dt6);
fa(fa>1) = 1; fa(fa<0) = 0;
roiAll = dtiNewRoi('all');
mask = wm.data>0 & fa>=faThresh;
[x,y,z] = ind2sub(size(mask), find(mask));
roiAll.coords = mrAnatXformCoords(dt.xformToAcpc, [x,y,z]);

% Track Fibers
disp('Tracking TEND fibers ...');
fg = dtiFiberTrack(dt.dt6,roiAll.coords,dt.mmPerVoxel,dt.xformToAcpc,'FG_TEND',opts);
fg = dtiClearQuenchStats(fg);
%fgSTT = dtiCreateQuenchStats(fgSTT,'Length','Length', 1);
mtrExportFibers(fg, tendPDBFile);
disp(['The TEND fiber group has been written to ' tendPDBFile]);

% Call contrack_score to limit fibers to those intersecting the GM ROI
disp('Removing fibers that do not have both endpoints in GM ROI ...');
pParamFile = [' -i ' ctrparamsFile];
pOutFile = [' -p ' tendPDBFile];
pInFile = [' ' tendPDBFile];
pThresh = [' --thresh ' num2str(length(fg.fibers))];
cmd = ['contrack_score' pParamFile pOutFile pThresh ' --find_ends' pInFile];
disp(cmd);
system(cmd,'-echo');
fg = mtrImportFibers(tendPDBFile);

return;
