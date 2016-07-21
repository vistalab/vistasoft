function [dt6FileName, outBaseDir] = dtiInit(dwRawFileName, t1FileName, dwParams)
% function [dt6FileName, outBaseDir] = dtiInit([dwRawFileName], [t1FileName], [dwParams])
% 
%   Run the mrDiffusion pre-processing steps on raw DWI and T1 data.
%
%  This function runs with the default parameters unless the user passes in
%  dwParams with alternate parameters. To create a new set of dwParams use
%  'dtiInitParams'. See dtiInitParams.m for default parameters.
% 
% INPUTS:
%   dwRawFileName = Raw dti data in nifti format.
%   twFileName    = T1-weighted anatomical image. By default the diffusion
%                   data are aligned to this image. You can, however, pass 
%                   in the string 'MNI' to align the data to the standard 
%                   MNI-EPI templte.
%   dwParams      = This structure is generated using dtiInitParams.m It
%                   contains all the parameters necessary for running the 
%                   pipeline. Users should look at the comments there for 
%                   more information. 
%
% WEB resources:
%   vistaBrowseGit('dtiInit');
%   https://github.com/vistalab/vistasoft/wiki/DWI-Initialization 
% 
% Example Usage: 
%   % Using default params
%   dtiInit 
% <or> 
%   dtiInit('rawDti.nii.gz','t1.nii.gz') 
%  
% % Using varargin to set specific params
%   dwParams = dtiInitParams('clobber',1,'phaseEncodeDir',2);
%   dtiInit('rawDti.nii.gz','t1.nii.gz', dwParams)
%    <or> 
%  dtiInit([],[],dwParams);
% 
% See Also:
%       dtiInitParams.m
% 
% (C) Stanford VISTA, 8/2011 [lmp]
% 

%% I. Load the diffusion data, set up parameters and directories structure

if notDefined('dwRawFileName') || ~exist(dwRawFileName,'file')
    dwRawFileName = mrvSelectFile('r',{'*.nii.gz';'*.*'},'Select raw DTI nifti file');
    if isempty(dwRawFileName); disp('dtiInit canceled by user.'); return; end
end

% Load the difusion data
disp('Loading raw data...');
dwRaw = niftiRead(dwRawFileName);

% By default all processed nifti's will be at the same resolution as the
% dwi data
if notDefined('dwParams'); 
  dwParams         = dtiInitParams; 
  dwParams.dwOutMm = dwRaw.pixdim(1:3);
end 

% Initialize the structure containing all directory info and file names
dwDir      = dtiInitDir(dwRawFileName,dwParams);
outBaseDir = dwDir.outBaseDir;
fprintf('Dims = [%d %d %d %d] \nData Dir = %s \n', size(dwRaw.data), dwDir.dataDir);
fprintf('Output Dir = %s \n', dwDir.subjectDir);


%% II. Select the anatomy file

% Check for the case that the user wants to align to MNI instead of T1.
if exist('t1FileName','var') && strcmpi(t1FileName,'MNI')
    t1FileName = fullfile(mrDiffusionDir,'templates','MNI_EPI.nii.gz');
    disp('The MNI EPI template will be used for alignment.');
end

if notDefined('t1FileName') || ~exist(t1FileName,'file')
    t1FileName = mrvSelectFile('r',{'*.nii.gz';'*.*'},'Select T1 nifti file');
    if isempty(t1FileName); disp('dtiInit canceled by user.'); return; end
end
fprintf('t1FileName = %s;\n', t1FileName);


%% III. Reorient voxel order to a standard, unflipped, axial order

% Canonical form has the first through third dimensions represented as
% RAS: (Right-left, Anterior-posterior, Superior-inferior) 
[dwRaw,canXform] = niftiApplyCannonicalXform(dwRaw);


%% IV. Make sure there is a valid phase-encode direction 

if isempty(dwParams.phaseEncodeDir)  ... 
       || (dwParams.phaseEncodeDir<1 ...
       ||  dwParams.phaseEncodeDir>3)
    dwRaw.phase_dim = dtiInitPhaseDim(dwRaw.phase_dim);
else
    dwRaw.phase_dim = dwParams.phaseEncodeDir;
end


%% V. Read Bvecs & Bvals and build if they don't exist

if ~exist(dwDir.bvalsFile,'file') || ~exist(dwDir.bvecsFile,'file')
    [doBvecs, dwParams] = dtiInitBuildBVs(dwDir, dwParams);
else
    doBvecs = false;
end

% Read bvecs and bvals
bvecs = dlmread(dwDir.bvecsFile);
bvals = dlmread(dwDir.bvalsFile);


%% VI. Check for missing data volumes and exclude indicated vols

[doResamp, bvecs, bvals, dwRaw] = dtiInitCheckVols(bvecs, bvals, dwRaw, dwParams);

%% VII. Rotate bvecs using Rx or CanXform

% We rotated the data. Now we need to rotate the bvecs to correspond to the
% new, rotated directions.  That happens here.
if dwParams.rotateBvecsWithRx 
    bvecXform = affineExtractRotation(dwRaw.qto_xyz);
else
    bvecXform = eye(3);
end

if dwParams.rotateBvecsWithCanXform 
    bvecXform = bvecXform * canXform(1:3,1:3);
end

% Apply the transform to each of the bvecs
if ~isequal(bvecXform,eye(3)) 
    for ii=1:size(bvecs,2) 
        bvecs(:,ii) = bvecXform * bvecs(:,ii);
    end
end

%% VIII. Compute mean b=0: used for e-c correction and alignment to t1

% Here we decide if we compute b0. If the user asks to clobber existing
% files, or if the mean b=0 ~exist dtiInitB0 will return a flag that will
% compute it in dtiInit. If clobber is set to ask, then we prompt the user. 
computeB0 = dtiInitB0(dwParams,dwDir);

% If computeB0 comes back true, do the (mean b=0) computation
% This gets saved as a B0 file.
if dwParams.eddyCorrect==-1, doAlign=0; else doAlign=1; end
if computeB0, dtiRawComputeMeanB0(dwRaw, bvals, dwDir.mnB0Name, doAlign); end


%% IX. Eddy current correction

% Based on user selected params decide if we do eddy current correction 
% and resampling. If the ecc is done doResamp will be true.
[doECC, doResamp] = dtiInitEddyCC(dwParams,dwDir,doResamp);

% If doECC comes back true do the eddy current correction
if doECC
   dtiRawRohdeEstimateEddyMotion(dwRaw, dwDir.mnB0Name, bvals, dwDir.ecFile,...
                              dwParams.eddyCorrect==1);
   % Make a figure of the Motion estimated during eddy current correction
   dtiCheckMotion(dwDir.ecFile,'off');
end


%% X. Compute the dwi -> structural alignment

% Based on user selected params decide if we align the raw dwi data to a
% reference T1 image. If the alignment is computed the diffusion data will
% also be resampled to the T1 resolution.
[doAlign, doResamp] = dtiInitAlign(dwParams,dwDir,doResamp);

if doAlign, dtiRawAlignToT1(dwDir.mnB0Name, t1FileName, dwDir.acpcFile); end


%% XI. Resample the DWIs / ACPC alignment

% Based on user selected params and doResamp decide if we are resampling
% the raw data. If doSample is true and we have computed an alignment or
% we're clobbering old data we doResampleRaw will be true. 
doResampleRaw = dtiInitResample(dwParams, dwDir, doResamp);

% Applying the dti-to-structural xform and the eddy-current correction
% xforms. If dwParams.eddyCorrect == 0, dwDir.ecFile will be empty and
% dtiRawResample will only do acpcAlignment.
if doResampleRaw,  dtiRawResample(dwRaw, dwDir.ecFile, dwDir.acpcFile,...
                   dwDir.dwAlignedRawFile, dwParams.bsplineInterpFlag,...
                   dwParams.dwOutMm);
end


%% XII. Reorient and align bvecs 

% Check to see if bvecs should be reoriented and reorient if necessary. If
% the conditions are met then the bvecs are reoriented and the aligned
% bvals file is saved from bvals.
dtiInitReorientBvecs(dwParams, dwDir, doResamp, doBvecs, bvecs, bvals);


%% XIII. Load aligned raw data and clear unaligned raw data

% This dwAlignedRawFile should be saved so we can crop it along with the T1
% and just do analyses on a smaller chunk of the diffusion data.
dwRawAligned = niftiRead(dwDir.dwAlignedRawFile);
clear dwRaw;  


%% XIV. Bootstrap parameters

% We'll use the non-realigned bvecs since we want to count bvecs that are
% only a little differnt due to motion correction as 'repeats'. Also, we
% can count a direction with just a sign-flip as a 'repeat' since it will
% contain essentially the same diffusion info.
% Note that this code is now used just to compute the number of unique
% diffusion directions. We now use a residual bootstrap, so the repetion
% pattern is no longer important for the bootstrap.
bs.n = dwParams.numBootStrapSamples;

% nUniqueDirs used to name the folder later...
[bs.permuteMatrix, tmp, nUniqueDirs] = ...
    dtiBootGetPermMatrix(dlmread(dwDir.bvecsFile),dlmread(dwDir.bvalsFile));  
                                                      
% We still need an over-determined tensor fit to do residual bootstrap.
% We'll skip the bootstrap for datasets with fewer than 14 measurements
% (7 is the minimum for tensor fitting).
if size(dwRawAligned.data,4)<14
    if strcmpi(dwParams.fitMethod,'ls')
        warning('mrDiffusion:bootstrap','Not enough redundancy in the data- skipping bootstrap.');
    end
    bs.n = 0;
end
bs.showProgress = false;


%% XV. Name the folder that will contain the dt6.mat file

% If the user passed in a full path to dt6BaseName and outDir ... if
% they're different the dt6.mat file will be saved to dt6BaseName while the
% other data will be saved to outDir. See dtiInitDir for the fix.
if isempty(dwParams.dt6BaseName) 
    % nUniqueDirs from dtiBootGetPermMatrix
    dwParams.dt6BaseName = fullfile(dwDir.subjectDir,sprintf('dti%02d',nUniqueDirs));
    if ~dwParams.bsplineInterpFlag 
        % Using trilinear interpolation 
        dwParams.dt6BaseName = [dwParams.dt6BaseName 'trilin'];
    end
else
    if isempty(fileparts(dwParams.dt6BaseName)) 
        dwParams.dt6BaseName = fullfile(dwDir.subjectDir,dwParams.dt6BaseName);
    end
end

%% XVI. Tensor Fitting

% Switch on the fit method. If 'ls' use dtiRawFitTensorMex. If 'rt' use
% dtiRawFitTensorRobust. In the future this code will support running both
% at the same time and getting out a dti<N>trilinrt directory
dt6FileName = {};

switch lower(dwParams.fitMethod)
    case {'ls'}
        dt6FileName{1} = dtiRawFitTensorMex(dwRawAligned, dwDir.alignedBvecsFile,...
            dwDir.alignedBvalsFile, dwParams.dt6BaseName,...
            bs,[], dwParams.fitMethod,[],[],dwParams.clobber);
        
    case {'rt'}
        dt6FileName{1} = dtiRawFitTensorRobust(dwRawAligned, dwDir.alignedBvecsFile,...
            dwDir.alignedBvalsFile, dwParams.dt6BaseName,[],[],[], ... 
            dwParams.nStep,dwParams.clobber,dwParams.noiseCalcMethod);

    case {'rtls','lsrt','all','both','trilinrt'};
        dt6FileName = ...
            dtiInitTensorFit(dwRawAligned, dwDir, dwParams, bs);
end


%% XVII. Build the dt6.files field and append it to dt6.mat

% Need to handle the case where there is more than one dt6 file. 
for dd = 1:numel(dt6FileName)
    dtiInitDt6Files(dt6FileName{dd},dwDir,t1FileName);
end


%% XIIX. Check tensors and create t1pdd.png

[pddT1,tmp,mm] = dtiRawCheckTensors(fullfile(dwParams.dt6BaseName,'bin',...
                                  'tensors.nii.gz'),t1FileName);  
pddT1        = flipdim(permute(pddT1, [2 1 3 4]), 1);
imSlices     = 1:2:size(pddT1, 3);
img          = makeMontage3(pddT1, imSlices, mm(1), 0 , [], [], 0);
imwrite(img, fullfile(dwParams.dt6BaseName, 't1pdd.png'), 'CreationTime',... 
         now, 'Author', 'mrDiffusion from Stanford University', 'Description',...
         'T1 with PDD overlay');


%% XIX. Setup conTrack, fibers and ROIs directories and ctr options file

dtiInitCtr(dwParams,dwDir);


%% XX. Save out parameters, svn revision info, etc. for future reference

dtiInitLog(dwParams,dwDir);


return
%#ok<*ASGLU>

