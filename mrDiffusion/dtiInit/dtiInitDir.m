function dwDir = dtiInitDir(dwRawFileName,dwParams)
% function dwDir = dwInitDir(dwRawFileName,dwParams)
% 
% Returns a structure with directory and file information. This code was
% written specifically for use with dtiInit.
% 
% Example:
%       dwRawFileName = mrvSelectFile;
%       dwParams = dtiInitParams;
%       dwDir = dtiInitDir(dwRawFileName,dwParams)
% 
% Web resources:
%       mrvBrowseSVN('dtiInitDir');
% 
% (C) Stanford VISTA, 2011 [lmp]
%  

%% Set the suffix for the folder names

dwDir.outSuffix = '_aligned';

% In the case that we are using trilinear interpolation we use '_trilin' as
% the suffix for the dti* folder
if ~dwParams.bsplineInterpFlag, dwDir.outSuffix = [dwDir.outSuffix '_trilin']; end

if  dwParams.eddyCorrect == 0
    disp('Skipping eddy-current correction. Rigid-body motion correction.');
elseif  dwParams.eddyCorrect == -1 , dwDir.outSuffix = [dwDir.outSuffix '_noMEC'];
    disp('No eddy-current or motion correction.');
elseif dwParams.eddyCorrect == 1 
else
    error('eddyCorrect must be [-1|0|1]!');
end


%% Set up the directory and file naming scheme

dwDir.mrDiffusionDir = fileparts(which('mrDiffusion.m'));

% We need the full path to the dwRawFile so check to see if the user did
% not provide the full path the raw file and add it if needed.
[p f e] = fileparts(dwRawFileName);  %#ok<NASGU>                                      
if isempty(p), dwRawFileName = fullfile(pwd,dwRawFileName); end

% Build the names using the raw dti file
[dwDir.dataDir,dwDir.inBaseName] = fileparts(dwRawFileName);
if isempty(dwDir.dataDir); dwDir.dataDir = pwd; end

% Set default paths
[tmp,dwDir.inBaseName] = fileparts(dwDir.inBaseName); %#ok<ASGLU>
dwDir.mnB0Name         = fullfile(dwDir.dataDir,[dwDir.inBaseName '_b0.nii.gz']);
dwDir.outBaseName      = [dwDir.inBaseName dwDir.outSuffix];
dwDir.outBaseDir       = fullfile(dwDir.dataDir,dwDir.outBaseName);
dwDir.inBaseDir        = fullfile(dwDir.dataDir,dwDir.inBaseName);
dwDir.subjectDir       = fileparts(dwDir.dataDir);

% Default output dir is one level above the dataDir. We assume that
% this is the 'subjectDir', which contains the 'raw' data dir.
if isempty(dwDir.subjectDir); dwDir.subjectDir = pwd; end


%% Set file path and name defaults

dwDir.bvalsFile        = [dwDir.inBaseDir  '.bvals'];
dwDir.bvecsFile        = [dwDir.inBaseDir  '.bvecs'];
dwDir.ecFile           = [dwDir.inBaseDir  '_ecXform.mat'];
dwDir.acpcFile         = [dwDir.inBaseDir  '_acpcXform.mat'];
dwDir.alignedBvecsFile = [dwDir.outBaseDir '.bvecs'];
dwDir.alignedBvalsFile = [dwDir.outBaseDir '.bvals'];
dwDir.dwAlignedRawFile = [dwDir.outBaseDir '.nii.gz'];


%% Allow any arbitrary bvec or bval file names in the directory to be used

% This is written such that if the expected bvals or bvecs file does not
% exist then it will look in the raw data directory for any file with
% 'bval' or 'bvec' in the name. If no such files exist, or if there is more
% than one file that matches that criteria, it will prompt the user to
% select the bvals and/or bvecs. 

% We first check if the user provided a path to the bvecs and/or bvals
% files in the dwPrams structure. If they did we set the path to that. We
% still check that the file exists next.
if ~isempty(dwParams.bvalsFile); dwDir.bvalsFile = dwParams.bvalsFile; end
if ~isempty(dwParams.bvecsFile); dwDir.bvecsFile = dwParams.bvecsFile; end

% Get bvals file
if ~exist(dwDir.bvalsFile,'file')
    bval = dir(fullfile(mrvDirup(dwRawFileName),'*bval*'));
    if numel(bval(:,1))>1
        dwDir.bvalsFile = mrvSelectFile('r',{'*bval*';'*.*'},'Select bvals file.');
    elseif(numel(bval(:,1))==1)
        dwDir.bvalsFile = fullfile(mrvDirup(dwRawFileName),bval.name);
    end
end

% Get Bvecs file
if ~exist(dwDir.bvecsFile,'file')
    bvec = dir(fullfile(mrvDirup(dwRawFileName),'*bvec*'));
    if numel(bvec(:,1))>1
        dwDir.bvecsFile = mrvSelectFile('r',{'*bvec*';'*.*'},'Select bvecs file.');
    elseif(numel(bval(:,1))==1)
        dwDir.bvecsFile = fullfile(mrvDirup(dwRawFileName),bvec.name);
    end
end

return

