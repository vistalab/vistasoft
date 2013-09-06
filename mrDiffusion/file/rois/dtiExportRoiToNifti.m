function RoiFileName=dtiExportRoiToNifti(roi, refImage, outFile)
%
% dtiExportRoiToNifti(roi, ref, [outFile='roi'])
% Note:  refImage and outFile filenames: prefixes only
% Save a mrDiffusion ROI as a binary NIFTI image. Useful for
% loading the ROI into another program, like FSL or SPM.
%
% HISTORY:
% 2007.10.06 Kaustubh Supekar wrote it.

% Allow roi to be either a fileName or the roi struct.
if(ischar(roi))
   roi = dtiReadRoi(roi);
end

if(~exist('outFile','var')||isempty(outFile))
    outFile = 'roi';
end
l = length(outFile);
if(l<5||(~strcmpi(outFile(l-3:l),'.nii')&&~strcmpi(outFile(l-2:l),'.gz')))
    outFile = strcat(outFile,'.nii.gz');
end
% ref can either be a NIFTI filename or a NIFTI struct
if(ischar(refImage))
   l = length(refImage);
   if(l<5||(~strcmpi(refImage(l-3:l),'.nii')&&~strcmpi(refImage(l-2:l),'.gz')))
      refImage = [refImage '.nii.gz'];
   end
   ref = niftiRead(refImage);
end
c = mrAnatXformCoords(ref.qto_ijk, roi.coords);
c = round(c);
roiIm = ref;
roiIm.data = zeros(size(roiIm.data),'uint8');
roiIm.data(sub2ind(size(roiIm.data), c(:,1), c(:,2), c(:,3))) = 1;
roiIm.fname = outFile;
writeFileNifti(roiIm);
RoiFileName=roiIm.fname; 
return;
