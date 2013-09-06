function dtiAddCorticalSurfaceStatsToFibers(PDBFileName,retVarFileName,retMapFileName,localStatsName)
%Add retinotopy stats to fibers in pdb files
%
%   dtiAddCorticalSurfaceStatsToFibers(PDBFileName,retVarFileName, retMapFileName, localStatsName)
%
% INPUTS:
%               PDBFileName:    Complete name of the pdb file containing the fibers 
%               retVarFileName: Complete name of the nifti file containing the variance explained map
%               retMapFileName: Complete name of the nifti file containing the retinotopy map based on 
%                               which you want to add statistics to the fiber, can be eccentricity 
%                               map, polar-angle map or the ROIs
%               localStatsName: A string containing the name of the statistics, 
%                               for example 'Ecc' or 'Pol' or 'ROI'.
% EXAMPLES:
%               dtiAddCorticalSurfaceStatsToFibers('mrtrix_stream_dti.pdb','varianceExplained.nii.gz', 'eccentricity.nii.gz','Ecc')
%               dtiAddCorticalSurfaceStatsToFibers('mrtrix_stream_dti.pdb','varianceExplained.nii.gz', 'polar.nii.gz', 'Pol')
%               dtiAddCorticalSurfaceStatsToFibers('mrtrix_stream_dti.pdb','varianceExplained.nii.gz', 'all_ROIs_RH.nii.gz', 'ROI_RH')
% AUTHORS:
% 2009.11.14 : AJS wrote it.
%
% NOTES: 
%   * Need to add a half voxel offset to the center of the sphere because
%     we have an even number of voxels.

if ieNotDefined('localStatsName'); localStatsName = 'CorticalSurfaceStats'; end

% Get stats
ret = niftiRead(retMapFileName);
retVar = niftiRead(retVarFileName);
% Limit consideration by some variance explained
%var_mode = mode(retVar.data(:));
var_thresh=0.3;
ret.data(retVar.data<=var_thresh) = -1;
ret.data(ret.data==0) = -1;

% Add stat to all pdb files
%pdbfiles = {mrtrixStreamCSDPDBFile, mrtrixStreamDTIPDBFile};
pdbfiles = {PDBFileName};
for pp=1:length(pdbfiles)
    disp(' '); disp(['Adding retinotopy stats to ' pdbfiles{pp} ' ...']);
    fg = mtrImportFibers(pdbfiles{pp});
    fg = dtiClearQuenchStats(fg);
    fg = dtiCreateQuenchStats(fg,'Length','Length', 1);
    fg = dtiCreateQuenchStats(fg,'Max',localStatsName, 0, ret, 'max');
    mtrExportFibers(fg, pdbfiles{pp});
end
return;
