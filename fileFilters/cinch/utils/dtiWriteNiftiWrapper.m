function ni = dtiWriteNiftiWrapper(imArray, matrixTransform, filename, sclSlope,...
    description, intentName, intentCode, freqPhaseSliceDim, sliceCodeStartEndDuration, TR)
% See also niftiGetStruct and niftiCreate
% We think this should go away and be replaced by a proper niftiCreate
%
% dtiWriteNiftiWrapper (imArray, matrixTransform, filename,
%     [sclSlope=1], [description='VISTASOFT'], [intentName=''], [intentCode=0], 
%     [freqPhaseSliceDim=[0 0 0]], [sliceCodeStartEndDuration=[0 0 0 0]])
%
% INPUTS:
%   imArray:         the matlab array containing the image
%   matrixTransform: a 4x4 matrix transforming from image space to AC-PC
%                    space.
%   filename:        Name of the file to output (provide extension).
%   sclSlope:        'true' voxel intensity is storedVoxelVale*sclSlope.
%   intentName:      short (15 char) string describing the intent
%   intentCode:      an integer specifying a NIFTI intent type. Eg:
%                    1002 = NIFTI_INTENT_LABEL (index into a list of labels)
%                    1005 = NIFTI_INTENT_SYMMATRIX (e.g., DTI data)
%                    1007 = NIFTI_INTENT_VECTOR 
% 
% OUTPUTS: 
%   ni:              Nifti structure.
%
% See http://nifti.nimh.nih.gov/pub/dist/src/niftilib/nifti1.h for
% details on the other nifti options.
% 
% WEB:
%   mrvBrowseSVN('dtiWriteNiftiWrapper');
%
% HISTORY:
% Author: DA
% 2007.03.27 RFD: we now save the xform in both qto and sto and
% properly set qfac. This improves compatibility with some viewers,
% such as fslview.
% 
%  (C) Stanford University, VISTA

%% Handle inputs
% 
if(nargin<2)
  help(mfilename);
end

if ~exist('sclSlope','var') || isempty(sclSlope)
    sclSlope = 1.0;
end
if ~exist('description','var') || isempty(description)
    description = 'VISTASOFT';
end

if ~exist('freqPhaseSliceDim','var') || isempty(freqPhaseSliceDim)
    freqPhaseSliceDim = [0 0 0];
end
if ~exist('sliceCodeStartEndDuration','var') || isempty(sliceCodeStartEndDuration)
    sliceCodeStartEndDuration = [0 0 0 0];
end
if ~exist('intentName','var') || isempty(intentName)
    intentName = '';
end
if ~exist('intentCode','var') || isempty(intentCode)
    intentCode = '';
end
if ~exist('TR','var') || isempty(TR)
    TR = 1;
end


%% Create the nifti structure with the inputs provided
% 
% ni = niftiGetStruct(imArray, matrixTransform, sclSlope, description,...
%                     intentName, intentCode, freqPhaseSliceDim, ...
%                     sliceCodeStartEndDuration, TR);
                
ni = niftiCreate('data',imArray,...
                 'qto_xyz',matrixTransform,...
                 'scl_slope',sclSlope,...
                 'descrip',description,...
                 'intent_name',intentName,...
                 'intent_code',intentCode,...
                 'freq_dim',freqPhaseSliceDim,...
                 'slice_code',sliceCodeStartEndDuration,...
                 'tr',TR);

                
%% Filenaming 
% 
if(length(filename)<4)
    filename = [filename '.nii.gz'];
elseif(strcmpi(filename(end-2:end),'nii'))
    filename = [filename '.gz'];
elseif(length(filename)<6||~strcmpi(filename(end-5:end),'nii.gz'))
    filename = [filename '.nii.gz'];
end
ni.fname = filename;

%% Write the file
% 
writeFileNifti(ni);

return;




