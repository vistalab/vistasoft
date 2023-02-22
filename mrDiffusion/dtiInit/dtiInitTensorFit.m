function dt6FileName = dtiInitTensorFit(dwRawAligned,dwDir,dwParams,bs)
% dt6FileName = dtiInitTensorFit(dwRawAligned,dwDir,dwParams,bs)
% 
% Process the raw aligned DWI data from dtiInit using both trilinear
% interpolation and robust tensor fitting. 
%
% INPUTS
%   
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
%   dt6FileName = dtiInitTensorFit(dwDir,dwParams,bs);
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
    
    
    %  Feed in the aligned_trilin files from the raw directory
    dwParams.fitMethod = 'rt';
    dt6FileName{2} = dtiRawFitTensorRobust(dwDir.dwAlignedRawFile, ... 
                                        dwDir.alignedBvecsFile, ...
                                        dwDir.alignedBvalsFile, ...
                                        [dwParams.dt6BaseName 'rt'], ...
                                        [],[],[], dwParams.nStep, ... 
                                        dwParams.clobber,dwParams.noiseCalcMethod);
                                    
    
else
    disp('B-Spline fitting was done... Skipping robust tensor fitting.');
end

return


