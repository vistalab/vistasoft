function roi = dtiImportRoiFromNifti(roi_img, outFile)
% 
% roi = dtiImportRoiFromNifti(roi_img, [outFile])
% 
% Creates a mrDiffusion ROI structure from a binary NIFTI image and saves
% that structure to disk if the user supplies 'outFile'
% 
% INPUTS:
%       roi_img - path to a nifti ROI
%       outFile - file name for the new .mat ROI. Note: all filenames 
%                 should have prefixes only. IF this variable is not
%                 defined the ROI will not be saved to disk, it will only
%                 be returned. 
% 
% OUTPUTS:
%       roi     - mrDiffusion ROI structure. 
% 
% 
% EXAMPLE USAGE:
%       roi_img = '/path/to/niftiRoi.nii.gz';
%       outFile = 'niftiRoiName';
%       roi = dtiImportRoiFromNifti(roi_img, outFile);
% 
% 
% WEB RESOURCES:
%       mrvBrowseSVN('dtiImportRoiFromNifti');
% 
% 
% (C) Stanford University, VISTA LAB 
% 

% HISTORY:
% 2008.04.21 ER wrote it.


%% 

% NIFTI filename 
if notDefined('roi_img') || ~exist(roi_img,'file')
    roi_img = mrvSelectFile('r','.nii*','Select Nifti File');
end   

roiImg = niftiRead(roi_img);

% Pull out the coordinates from roiImg.data
[x1,y1,z1] = ind2sub(size(roiImg.data), find(roiImg.data));

% Initialize roi structrue
name = prefix(roiImg.fname, 'short');
roi  = dtiNewRoi(prefix(name));

% Xform the coordianates based on the Xform in the nifti image
roi.coords = mrAnatXformCoords(roiImg.qto_xyz, [x1,y1,z1]);

% Save the nifti if the user passed in outFile
if exist('outFile','var') && ~isempty(outFile)
    dtiWriteRoi(roi, outFile);
    fprintf('Saved %s \n',outFile);
end

return
