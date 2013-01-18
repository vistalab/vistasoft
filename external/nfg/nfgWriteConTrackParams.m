function nfgWriteConTrackParams(ctrparamsFile, binDir, wmFile, roiFile, pdfFile, nMinNodes, nMaxNodes, fStepSizeMm, nSamples)
%Write the parameters file for ConTrack programs
%
%   nfgWriteConTrackParams(ctrparamsFile, binDir, wmFile, roiFile, pdfFile,
%   nMinNodes, nMaxNodes, fStepSizeMm, nSamples)
%
%   contrack_gen and contrack_score require this file to run.
%   ctrparamsFile : Filename to write.
%   binDir : Directory to find images.
%   wmFile : White matter mask relative to binDir.
%   roiFile : ROI mask relative to binDir.
%   pdfFile : PDF image relative to binDir.
% 
% AUTHORS:
%   2009.08.05 : AJS wrote it
%
% NOTES: 

if ieNotDefined('nSamples'); nSamples = 50000; end

ctr = ctrCreate();
ctr=ctrSet(ctr,'image_directory',binDir);
ctr=ctrSet(ctr,'fa_filename',wmFile);
ctr=ctrSet(ctr,'mask_filename',roiFile);
ctr=ctrSet(ctr,'pdf_filename',pdfFile);
ctr=ctrSet(ctr,'max_nodes', nMaxNodes);
ctr=ctrSet(ctr,'min_nodes', nMinNodes);
ctr=ctrSet(ctr,'step_size', fStepSizeMm);
ctr=ctrSet(ctr,'desired_samples', nSamples);
ctrSave(ctr,ctrparamsFile);

return;