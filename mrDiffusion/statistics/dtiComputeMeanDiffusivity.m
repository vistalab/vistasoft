function [md mdNifti] = dtiComputeMeanDiffusivity(dt6File,niftiName)
%
% Compute the Mean Diffusvity image from a dt6 file.
%
% INPUTS:
%   dt6File - Full path to a dt6 file.
% niftiName - full path to a nifti file to save the MD image.
%
% OUTPUTS: 
%   md      - The 3D volume of mean diffusivity.
%   mdNifti - The nifti structure of the mean diffusivity file created
%
% See also: feMakeWMMask.m
%
% Franco (c) Stanford Vista Team 2012

% Check inputs
if notDefined('dt6File')
    error('[%s] The fullpath to a dt6 file is necessary.',mfilename)
end

% Load the dt6 file
[dt, ~] = dtiLoadDt6(dt6File, 1);

% Build a mean dffusivity image
% Geneated the tensors in a convenient format
[~, eigVal] = dtiSplitTensor(dt.dt6);

% Clip the mean diffusivity values to good acceptable values, the rest were
% probably bad fits and should be mostly outside of the brain.
eigVal( (isnan(eigVal) | eigVal<0) ) = 0;

% Compute the mean diffusivity image. We will use thi sfile to threshold
% the file white-matter mask
md = mean(eigVal,4);
% To check the the image: makeMontage3(md);
% Show the histogram: figure; hist(md(:),1000)

% If a nifti file name was passed in we save the image to file.
if ~notDefined('niftiName')
  % We use the b0 if defined as a template for the nifti information.
  b0file = dt.files.b0;
  % We load it.
  mdNifti       = niftiRead(b0file);
  mdNifti.fname = niftiName;
  mdNifti.data  = md;
  mdNifti.descrip = fullpath(mfilename);
  % Save the file
  niftiWrite(mdNifti);
end

return