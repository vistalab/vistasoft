function [dataOUT, xform, ni] = mrLoadRet2nifti(dataIN, mmPerVox, vw) 
%  [dataOUT, xform, ni] = mrLoadRet2nifti(dataIN, mmPerVox, vw) 
% 
% AUTHOR:  JW
% DATE:    1.27.09
% PURPOSE:
%   Convert mrVista data set to our preferred axial format for NIFTI
%
% NIFTI coords will be in [sagittal(L:R), coronal(P:A), axial(I:S)] format. 
% mrLoadRet coords are in [axial(S:I), coronal(A:P), sagittal(L:R)] format.
% 
%
%   dataIN: 3D iamge matrix with mrVista formatted data
%   mmPerVox: 3 vector (mrVista format)
%
% Example: Convert the anat image in a current mrVista volume view to a
%   NIFTI file, and save.
%
% vw        = getSelectedVolume;
% dataIN    = vw.anat; 
% mmPerVox  = viewGet(vw, 'mmPerVox'); 
% [data, xform, ni] = mrLoadRet2nifti(dataIN, mmPerVox);
% ni.fname = [pwd filesep 'myNIFTYfile.nii.gz'];
% writeFileNifti(ni);
%

% If we don't have units get them from the view struct
if ~exist('mmPerVox', 'var') || isempty('mmPerVox')
    if ~exist('vw', 'var'), vw = getCurView; end
    mmPerVox = viewGet(vw, 'mmPerVox');    
end

% Transform the units
mmPerVox = permute(mmPerVox, [3 2 1]);

% Transform the coordinates
dataOUT = flip(flip(permute(dataIN,[3 2 1]),2),3);

% Get the xform matrix
xform = [diag(1./mmPerVox), size(dataOUT)'/2; 0 0 0 1];

% Create a nifti struct so that it can be returned, if requested 
ni = niftiCreate('data', dataOUT, 'qto_xyz', inv(xform));

return