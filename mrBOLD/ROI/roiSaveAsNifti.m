function roiSaveAsNifti(vw, fname, roiColor)
% function roiSaveAsNifti(vw, fname, roiColor)
%
% Aug 2008: JW
%
% Save a mrVista ROI as a nifti file that can be read by itkGray. The ROI
% can be viewed in itkGray by opening either a segmentation image or an RGB
% overlay. The latter may be preferable, because you can then view a
% T1-anatomy with a segmentation file plus the ROI overlay, allowing you
% to see the position of the ROI relative to the anatomy and the
% segmentation. Note that if you plan to view the nifti as an  RGB overlay,
% the roiColor is an 8-bit intensity value and should probably be high
% (e.g., 255). If you view the ROI as a segmentation file, then the
% 'roiColor' is  an itkGray label number and should be a low integer.
%
% See roiSaveAllForItkGray.m
% check vars
mrGlobals;

if notDefined('vw'), vw = getCurView; end

viewType = viewGet(vw, 'viewtype');
switch lower(viewType)
    case {'gray', 'volume'}
        ROI = viewGet(vw, 'roistruct');
    otherwise
        error('[%s]: Must be in gray view', mfilename);
end

if notDefined('fname'),
    fname = fullfile(fileparts(vANATOMYPATH), [ROI.name '.nii.gz']);
end

% Note that if we want to load the ROI as a segementation file in itgGray,
% values that are too high will crash itkGray. The cutoff is somewhere
% above 100 and below 128. We should check.
if notDefined('roiColor'), roiColor = 1; end

%get ROI coords
coords = getCurROIcoords(vw);
len = size(coords, 2);

% make a 3D image with all points set to zero except ROI = roiColor
roiData = zeros(viewGet(vw, 'anatomy size'));
for ii = 1:len
    roiData(coords(1,ii), coords(2,ii), coords(3,ii)) = roiColor;
end

% Create and save nifti file with roiData
fname = niftiSaveVistaVolume(vw, roiData, fname);

message = (['file saved as ' fname]);
disp(message)

return
