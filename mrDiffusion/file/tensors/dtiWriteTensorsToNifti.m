function [fileName] = dtiWriteTensorsToNifti(dt6, xformToAcPc, desc, adcUnits, fileName)
% Write a dt6 (tensor) dataset in mrDiffusion format in NIFTI format.
%
%  [fileName] = dtiWriteTensorsToNifti(dt6, xformToAcPc, [desc=''], [adcUnits='um^2/msec'], [fileName=uiputfile])
%   
% The six entries are the diffusion tensor values, derived from the raw
% data.  The raw data can be in many different directions.  The diffusion
% tensor is a 3x3 positive-definite matrix, D.  The entries in the matrix
% are stored in a vector: (Dxx Dyy Dzz Dxy Dxz Dyz)
%
%
% HISTORY:
%  2008.11.10 RFD wrote it.

if(~exist('fileName','var')||isempty(fileName))
    [f,p] = uiputfile({'*.nii.gz';'*.*'},'Save to a NIFTI tensor file...');
    if(isnumeric(f)), disp('User canceled.'); return; end
    fileName = fullfile(p,f); 
end
if(~exist('desc','var') || isempty(desc))
    desc = '';
end

if(~exist('adcUnits','var') || isempty(adcUnits))
    adcUnits = 'um^2/msec';
end

% NIFTI convention is for the 6 unique tensor elements stored in the 5th
% dim in lower-triangular, row-order (Dxx Dxy Dyy Dxz Dyz Dzz). NIFTI
% reserves the 4th dim for time, so in the case of a time-invatiant tensor,
% we just leave a singleton 4th dim. Our own internal convention is
% [Dxx, Dyy, Dzz, Dxy, Dxz, Dyz], so we use the code below to convert to
% the NIFTI order and dt6=squeeze(ni.data(:,:,:,1,[1 3 6 2 4 5])); to get
% back to our convention. FOr reference- the 3x3 tensor matrix is:
%    Dxx Dxy Dxz
%    Dxy Dyy Dyz
%    Dxz Dyz Dzz
dt6 = dt6(:,:,:,[1 4 2 5 6 3]);
sz = size(dt6);
dt6 = reshape(dt6,[sz(1:3),1,sz(4)]);
dtiWriteNiftiWrapper(dt6, xformToAcPc, fileName, 1, desc, ['DTI ' adcUnits]);

return;