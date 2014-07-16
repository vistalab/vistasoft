function dtiFixITKGrayHeader(fileName,RefFileName)
% This function fixes the header of the NIFTI file exported from MrVista
% using the header of the reference file and overwrites the original file
%
%   dtiFixITKGrayHeader(fileName,RefFileName)
%
%EXAMPLE:
%           dtiFixITKGrayHeader('ROI1.nii.gz','t1.nii.gz');


% Read the Nifti Files
ni = niftiRead(RefFileName);
ni2 = niftiRead(fileName);

%Fix Headers
ni.fname = fileName;
ni.data = ni2.data;

%generate new file
writeFileNifti(ni);

return
