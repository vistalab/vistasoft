function dt6FileName = dtiInitTensorFit(dwRawFileName,dwRawAligned,dwDir,dwParams,bs)
% dt6FileName = dtiInitTensorFit(dwRawAligned,dwDir,dwParams,bs)
% 
% Process the raw aligned DWI data from dtiInit using both trilinear
% interpolation and robust tensor fitting. 
%
% INPUTS
%   dwRawFileName
%   dwRawAligned
%   dwDir
%   dwParams
%   bs
%
% RETURNS
%   dt6FileName
%
% Web Resources
%   mrvBrowseSVN('dtiInitTensorFit');
%
% Example:
%   dt6FileName = dtiInitTensorFit(dwRawAligned,dwDir,dwParams,bs);
%
% (C) Stanford VISTA, 2011 [lmp]

fprintf('Running TRILINEAR INTERPOLATION and ROBUST (RESTORE) TENSOR FITTING...\n');
dt6FileName = {};

%% Run the initial tensor fit using trilinear interpolation
dwParams.fitMethod = 'ls';

dt6FileName{1} = dtiRawFitTensorMex(dwRawAligned, dwDir.alignedBvecsFile,...
                   dwDir.alignedBvalsFile, dwParams.dt6BaseName,...
                   bs,[], dwParams.fitMethod,[],[],dwParams.clobber);

               
%% Fit the tensor again with the RESTORE method.

% Trilinear interp was done so we go on.
if ~dwParams.bsplineInterpFlag 
    
    %  Set up the directory structure for the robust tensor fits
    %  Build from the raw nifti file that was fed in originally
    [bd, dwName]   = fileparts(dwRawFileName);
    [tmp, dwName]  = fileparts(dwName); %#ok<ASGLU>
    
    %  Want the files that have been aligned and trilinearly interpolated
    dwBaseName   = fullfile(bd,[dwName,'_aligned_trilin']);
    
    %  Feed in the aligned_trilin files from the raw directory
    dwParams.fitMethod = 'rt';
    dt6FileName{2} = dtiRawFitTensorRobust([dwBaseName '.nii.gz'], ... 
                                        [dwBaseName '.bvecs'], ...
                                        [dwBaseName '.bvals'], ...
                                        [dwParams.dt6BaseName 'rt'], ...
                                        [],[],[], dwParams.nStep, ... 
                                        dwParams.clobber);
    
else
    disp('B-Spline fitting was done... Skipping robust tensor fitting.');
end

return


%%


% outName = fullfile(subDir, outDir);
% % Run initial preprocessing.
% dtiRawPreprocess(niftiRaw, t1, [], [], false, outDir, [], [], [], [], false, 2);


% [tmp outBaseDir] = fileparts(niftiRaw);
% [junk outBaseDir] = fileparts(outBaseDir);
% outBaseDir = fullfile(tmp,[outBaseDir,'_aligned_trilin']);


% % fit the tensor again with the RESTORE method.
% dtiRawFitTensor([outBaseDir '.nii.gz'], [outBaseDir '.bvecs'], [outBaseDir '.bvals'], [outName 'rt'],