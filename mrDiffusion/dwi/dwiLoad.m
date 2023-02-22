function [dwi, bvals, bvecs] = dwiLoad(dwiNifti, bvecsFile, bvalsFile)
% Load diffusion weighted image and corresponding bvecs/bvals. For use with
% dtiSet and dtiGet.
%
%   [dwi, bvals, bvecs] = dwiLoad([dwiNifti=mrvSelectFile],... 
%                      [bvecsFile=mrvSelectFile],[bvalsFile=mrvSelectFile])
%
% dwiNifti: Full path to a nifti file containing the motion corrected, ac-pc
%           aligned dwi data, 
%           OR, the nifti struct data from such a file.
%
% bvecsFile: A tab delimited text file specifying the gradient
%           directions that were applied during the diffusion weighted data
%           acquisition. This file should contain a 3xN matrix where N is
%           the number of volumes
%           NOTE: If you applied motion correction to your data it is
%           essential that the same rotations were aplied to the vector
%           directions stored in the bvecs file. The convention for the
%           pre-processing (dtiInit) in mrDiffusion is that a new bvecs
%           file is created and appended with _aligned.
%
% bvalsFile: A tab delimited text file specifying the b value
%           applide to each dwi volume.  Should be a 1xN vector where N is
%           the number of volumes
% 
% Usage Notes:
%           (1) If your bvals and bvecs files have the same name as your
%           dwiNifti (with a .bvec(s) or .bval(s) extension) you only need
%           to point to the dwiNifti and this code will find the correct
%           files for you. 
%           (2) If you create a dwi structure using dwiCreate, set the full
%           file names in that structure, and pass that structure to this
%           function, and this function will load the data using the full
%           path file names in those fields. 
% 
% Example:
%           If your bvecs/bvals files are named dwi.bvecs and dwi.bvals:
%            >> dwi = dwiLoad('dwi.nii.gz')
%               dwi = 
%                   nifti: [1x1 struct]
%                   bvecs: [130x3 double]
%                   bvals: [130x1 double]
%           You can also run the function with no inputs and select your
%           files one by one:
%            >> dwi = dwiLoad;
%
% Web Resources:
%           mrvBrowseSVN('dwiLoad'):
% 
% See Also:
%           dwiCreate.m ; dwiGet.m ; dwiSet.m
% 
% 
% (C) Stanford University, VISTA Lab [2011]

%% Check inputs

% Check to see if the user passed in a dwiCreate struct. If they did then
% we set the inputs based on the fields in that structure. 
if nargin == 1 && isstruct(dwiNifti) 
    dwi = dwiNifti;
    if isfield(dwi,'bvecs') && exist(dwi.bvecs,'file')
        bvecsFile = dwi.bvecs; end
    if isfield(dwi,'bvals') && exist(dwi.bvals,'file')
        bvalsFile = dwi.bvals; end
    if isfield(dwi,'nifti') && exist(dwi.nifti,'file')
        dwiNifti = dwi.nifti; else dwiNifti = []; end
end

show = false;  % Show file names if we have to guess them (see last cell)

% Check for raw dwi nifti file
if notDefined('dwiNifti') || ~exist(dwiNifti,'file')
    dwiNifti = mrvSelectFile('r','*.nii.gz','Select your DWI NIFTI File.');
    if isempty(dwiNifti); disp('Canceled by user.'); return; end
    show = true;
end

% Get basename of bvecs/bvals files
[dwiPath f junk] = fileparts(dwiNifti);   %#ok<NASGU>
[junk, dwBaseName junk] = fileparts(f);   %#ok<ASGLU,NASGU>

% Check for bvecs file
if notDefined('bvecsFile') || ~exist(bvecsFile,'file')
    vecsFile = fullfile(dwiPath, [dwBaseName '.bvecs']);
    vecFile  = fullfile(dwiPath, [dwBaseName '.bvec']);
    if     exist(vecsFile,'file'), bvecsFile = vecsFile;
    elseif exist(vecFile,'file'),  bvecsFile = vecFile;
    else   bvecsFile = mrvSelectFile('r','*bvec*', 'Select BVECS File');
    end
    if isempty(bvecsFile); disp('Canceled by user.'); return; end
    show = true;
end

% Check for bvals file
if notDefined('bvalsFile') || ~exist(bvalsFile,'file')
    valsFile = fullfile(dwiPath, [dwBaseName '.bvals']);
    valFile  = fullfile(dwiPath, [dwBaseName '.bval']);
    if     exist(valsFile,'file'), bvalsFile = valsFile;
    elseif exist(valFile,'file'),  bvalsFile = valFile;
    else   bvalsFile = mrvSelectFile('r','*bval*', 'Select BVALS File');
    end
    if isempty(bvalsFile); disp('Canceled by user.'); return; end
    show = true;
end


%% Create dwi structure

% Check if a dwiCreate struct was passed in - if not then create it.
if notDefined('dwi'), dwi = dwiCreate('name', dwBaseName); end

dwi.nifti = niftiRead(dwiNifti);
dwi.bvecs = dlmread(bvecsFile);
dwi.bvals = dlmread(bvalsFile);

dwi.files.nifti = dwiNifti;
dwi.files.bvecs = bvecsFile;
dwi.files.bvals = bvalsFile;

% Check that bvecs = 3D && bvals = 1D
[dwi.bvecs,dwi.bvals] = dwiCheckBvecsBvals(dwi.bvecs, dwi.bvals, dwi.nifti);


%% Show file names after the load is complete. 

% Show if the user did not provide them up front and we had to find them.
if show
    fprintf('\nFiles loaded: \n  dwi   = %s \n  bvecs = %s \n  bvals = %s\n\n',...
        dwiNifti, bvecsFile, bvalsFile);
end


%% Return bvecs and bvals

bvecs = dwi.bvecs;
bvals = dwi.bvals;

return

