function [finalResNifti, resample_params] = mrAnatResampleToNifti(originalResNifti, finalResNifti,fname,resample_params)
% Resample a nifti file to the resoltuion fo a second nifti file.
%
%   [finalResNifti, resample_params] = ...
%    mrAnatResampleToNifti(originalResNifti,finalResNifti,[fname],[resample_params])
%
% INPUTS:
%    originalResNifti - The nifti file that we want to resmaple. 
%    finalResNifti    - The nifti file with the resolution that we want.
%
% OUTPUTS:
%    finalResNifti   - The resampled nifti file structure.
%    resample_params - The parameter of the SPM algorithm used for
%                      resampling the data.
%
% Example:
%   % Down sample
%   basedir = mrvDataRootPath;
%   originalResNifti = fullfile(basedir,'/diffusion/sampleData/t1/t1.nii.gz');
%   finalResNifti    = fullfile(basedir,'/diffusion/sampleData/dti40/bin/b0.nii.gz');
%   fname            = fullfile(basedir,'/diffusion/sampleData/downsample_deleteme.nii.gz');
%   res              = mrAnatResampleToNifti(originalResNifti, finalResNifti,fname)
%
%   % Up sample
%   basedir = mrvDataRootPath;
%   originalResNifti = fullfile(basedir,'/diffusion/sampleData/dti40/bin/b0.nii.gz');
%   finalResNifti    = fullfile(basedir,'/diffusion/sampleData/t1/t1.nii.gz');
%   fname            = fullfile(basedir,'/diffusion/sampleData/upsample_deleteme.nii.gz');
%   res              = mrAnatResampleToNifti(originalResNifti, finalResNifti,fname)
%
% Franco Pestilli (c) Stanford Vista Team 2012

% Load the nifti file if it was not passed is as nifti structure but as a
% full path.
if ~isstruct(originalResNifti)
  originalResNifti = niftiRead(originalResNifti);
end
if ~isstruct(finalResNifti)
  finalResNifti = niftiRead(finalResNifti);
end

if notDefined('resample_params')
  % SPM reslice parameters, default nearest-neighbour
  resample_params = [0 0 0 0 0 0];
end

% The final nifti file will have the resolution (in mm) of the second input image.
outmm = finalResNifti.pixdim(1:3);

% We need to build a boinding box, in mm for the initial image. This
% bounding box should have the size (in mm) of the image we are taking as
% second input. So here after we build the bounding box using the size
% information of the image passed in as second input.

% First we build a bounding box in pixels (image space) containing the full
% volume of the second input image.
bbimg = [1 1 1; finalResNifti.dim(1:3)];

% Second, we convert the bounding box from image space to mm space.
bbmm = mrAnatXformCoords(finalResNifti.qto_xyz,bbimg);

% Third, we reslice the file.
% mrAnatResliceSpm, takes bounding boxes in mm and interprets them
% appropriately in the image space by using the information in the xform of
% the original image and the final resolution in mm.
finalResNifti.data = mrAnatResliceSpm(double(originalResNifti.data), ...
                                         inv(originalResNifti.qto_xyz), ...
                                         bbmm,outmm,resample_params,0);
                                     
% mrAnatResliceSpm only hadles doubles. Here we change back the data to its
% original class.
dataClass = class(originalResNifti.data);
eval(sprintf('finalResNifti.data = %s( finalResNifti.data );',dataClass))

% Make sure all the fields in the output file are matched to the input
% file. Except for the fields relative to the image size, those shoudl be
% take from the finalResNifti.
f = getFieldsToUpdate;
for fi = 1:length(f)
  if isfield(originalResNifti, f{fi})
  finalResNifti.(f{fi}) = originalResNifti.(f{fi}); 
  end
end

% Special cases
if     (originalResNifti.ndim > finalResNifti.ndim)
  finalResNifti.dim     = [finalResNifti.dim    originalResNifti.dim(finalResNifti.ndim + 1:end)];
  finalResNifti.pixdim  = [finalResNifti.pixdim originalResNifti.pixdim(finalResNifti.ndim + 1:end)];
  finalResNifti.ndim    = originalResNifti.ndim;
elseif (finalResNifti.ndim >= originalResNifti.ndim) 
  finalResNifti.ndim    = originalResNifti.ndim;
  finalResNifti.dim     = finalResNifti.dim(1:originalResNifti.ndim);
  finalResNifti.pixdim  = finalResNifti.pixdim(1:originalResNifti.ndim);
end

if ~notDefined('fname')  
  % Save it
  fprintf('[%s] Saving resampled nifti to file:\n%s\n',mfilename,fname);
  finalResNifti.fname = fname;
  niftiWrite(finalResNifti);
end

end

%------------------------------%
function f = getFieldsToUpdate()
%
% Helper function that simply returns the set of fields that might need to
% be updated in the finalResFile, by taking them from the originalResFile.
%
f = {'fname','xyz_units', 'time_units',...
  'nifti_type', 'intent_code', ...
  'intent_p1', 'intent_p2',   ...
  'intent_p3', 'intent_name', ...
  'descrip',   'aux_file',    ...
  'num_ext',   'data_type',   ...
  'scl_slope', 'scl_inter',   ...
  'cal_min',   'cal_max',     ...
  'qform_code','sform_code',  ...
  'freq_dim',  'phase_dim',   ...
  'slice_dim', 'slice_code', ...
};

end

