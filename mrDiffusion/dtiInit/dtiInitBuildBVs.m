function [doBvecs dwParams] = dtiInitBuildBVs(dwDir,dwParams,numVols)
%
%   [doBvecs dwDir dwParams] = dtiInitBVs(dwDir,dwParams,numVOls);
%
%  Generate bvecs file and a bvals file from a dwepi.grads file.
%
% *** FIX ME: get the bval and grad dir file number from the dicom header.
%
% *** NOTE: most sequences will need the bvecs reoriented based on the
% scanner-to-image transform stored in qto_ijk. But, for our Bammer
% sequence, the bvecs were rotated during image acquisition.
%
% INPUTS
%       (dwDir,dwParams) - passed in from dtiInit
% RETURNS
%       [doBvecs dwDir dwParams] - with paths to built bvecs and bvals
%                                  files
%
% Web Resources
%       mrvBrowseSVN('dtiInitBVs');
%
% (C) Stanford VISTA, 8/2011 [lmp]
%

%% Generate bvecs file and a bvals file from a dwepi.grads file.
doBvecs = true;
% Directory with gradient direction code files
gradsDir = fullfile(dwDir.mrDiffusionDir,'data','gradFiles');

% Get bval and gradient directions code from name file name
if ~isfield(dwParams,'bvalue') || isempty(dwParams.bvalue)
    [dwParams.bvalue, gradDirsCodeTmp] = dtiRawGetBvalVecFromName(dwDir.inBaseName);
end

if(~isfield(dwParams, 'gradDirsCode')||isempty(dwParams.gradDirsCode))
    if(exist('gradDirsCodeTmp','var'))
        dwParams.gradDirsCode = gradDirsCodeTmp;
    else
        [dwParams.bvalue, dwParams.gradDirsCode] = dtiRawGetBvalVecFromName(filename);
    end
end

% If we can't guess the gradDirsCode we ask for it.
if(isempty(dwParams.gradDirsCode))
    [f,p] = uigetfile({'*.grads';'*.*'},'Select the GE grads file...',gradsDir);
    if isnumeric(f); error('Canceled.'); end
    dwParams.gradDirsCode = fullfile(p,f);
end

% Set the gradsFile to use
if(ischar(dwParams.gradDirsCode))
    gradsFile = dwParams.gradDirsCode;
else
    gradsFile = fullfile(gradsDir,sprintf('dwepi.%d.grads',dwParams.gradDirsCode));
end

% Actually build the bvecs/vals
dtiRawBuildBvecs(numVols, eye(4), gradsFile, dwParams.bvalue, dwDir.inBaseDir, dwParams.flipLrApFlag);

fprintf('bvalsFile = %s; %% (dwParams.bvalue = %0.3f)\nbvecsFile = %s; %%(dwParams.gradDirsCode = %d)\n', dwDir.bvalsFile,dwParams.bvalue,dwDir.bvecsFile,dwParams.gradDirsCode);

return

