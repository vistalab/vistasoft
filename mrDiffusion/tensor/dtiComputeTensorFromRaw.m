function [b0, dt6, mmPerVox] = dtiComputeTensorFromRaw(firstDataFile, gradsFile)
% Computes diffusion tensor from raw diffusion-weighted images.
%
% [b0, dt6, mmPerVox] = dtiComputeTensorFromRaw(firstDataFile, gradsFile)
%
% Loads a whole directory of raw image files, combines them according to
% the gradient direction information in gradsFile, then computes the
% diffusion tensor. Also returns the xform that will rotate the images into
% our cannonical orientation (as close to axial as possible- see
% computeCannonicalXformFromIfile).
%
% TODO:
%
%
% HISTORY:
% 2005.05.25: RFD (bob@sirl.stanford.edu) wrote it.
%

if(~exist('gradsFile','var')), gradsFile = []; end
if(~exist('firstDataFile','var')), firstDataFile = []; end

% Load raw data, averaging repeats
%
% *** TODO: we should NOT average repeated b>0 images. Rather, we should
% fit the tensor to all the individual data points.
[img, mmPerVox, gradDirs, bVals, xformToCan] = dtiAverageRawData(firstDataFile, gradsFile);

% Compute the tensor 
%
% Maybe try code in AFNI's 3dDWItoDT?
% http://afni.nimh.nih.gov/sscc/presentations/Diffusion%20Tensor.pdf
