function files = mrtrix_init(dt6, lmax, mrtrix_folder, wmMaskFile)
% Initialize filenames and directories to use the MRtrix toolbox via
% MatLab. MRtrix allows using Contrained Spherical Deconvolution and
% implements different types of tractography (i.e., probabilistic,
% deterministic).
%
% files = mrtrix_init(dt6, lmax, mrtrix_folder, [wmMaskFile])
%
% This function computes all the files needed to use mrtrix_track.
% 
% - INPUTS -
%    dt6   - string, full-path to an mrInit-generated dt6 file. 
%    lmax  - The maximal harmonic order to fit in the spherical deconvolution (d
%            model. Must be an even integer. This input determines the
%            flexibility  of the resulting model fit (higher values correspond
%            to more flexible models), but also determines the number of
%            parameters that need to be fit. The number of dw directions
%            acquired should be larger than the number of parameters required.	
%              lmax: 4  -> nParams 15
%              lmax: 8  -> nParms  45
%              lmax: 12 -> nParmas 91
%            General formula: lmax = n	nParams = ½ (n+1)(n+2)
%            http://www.brain.org.au/software/mrtrix/tractography/preprocess.html
%
%    mrtrix_folder - Name of the output folder
%    wmMaskFile    - Full path to a nifti file to be used as WM mask,
%                    in replacemnt of the default WM mask found in the dt6 file.
%
% - OUTPUTS -
%    files - The full-path to the files created
%
% - Notes -
%   This function performs the following operations:
%   1. Convert the raw dwi file into .mif format
%   2. Convert the bvecs, bvals into .b format
%   3. Convert the brain-mask to .mif format 
%   4. Fit DTI and calculate FA and EV images
%   5. Estimate the response function for single fibers, based on voxels
%      with FA > 0.7
%   6. Fit the CSD model. 
%   7. Convert the white-matter mask to .mif format. 
% 
% For details: 
% http://www.brain.org.au/software/mrtrix/tractography/preprocess.html
% 
% Franco Pestilli, Ariel Rokem and Bob Dougherty Stanford University 

% Loading the dt file containing all the paths to the fiels we need.
if ~isstruct(dt6)
    dt_info = load(dt6);
else
    dt_info = dt6;
end

% Check if it contains a path to the raw dwi data
if ~isfield(dt_info.files,'alignedDwRaw')
    % This code handles special case where the dt6.mat file was not created
    % using dtiInit. For example if dtiRawFitTensorMex was run directly
    dt_info = load(dt6);
    dt_info.files.alignedDwRaw = fullfile(dt_info.params.rawDataDir,dt_info.params.rawDataFile);
    if ~exist(dt_info.files.alignedDwRaw,'file')
        dt_info.files.alignedDwRaw = [dt_info.files.alignedDwRaw '.gz'];
    end
    dt_info.files.alignedDwBvecs = [prefix(prefix(dt_info.files.alignedDwRaw)) '.bvecs'];
    dt_info.files.alignedDwBvals = [prefix(prefix(dt_info.files.alignedDwRaw)) '.bvals'];
end

% Strip the file names out of the dt6 strings. 
dwRawFile         = dt_info.files.alignedDwRaw;
[session,dwiname] = fileparts(dwRawFile);
[~,dwiname]       = fileparts(dwiname);

% Return a warning if the number of parameters necessary to fit the
% diffusion data using constrained spherical deconvolution is larger then
% the number of diffusion directions in the current data set. 
bv       = dlmread(dt_info.files.alignedDwBvecs);
nbvecs   = unique(sum((bv ~= 0),2));
max_lmax = mrtrix_findlmax(nbvecs);
if (max_lmax < lmax) 
    warning('[%s] The chosen Lmax value (%i) requires a number of diffusion directions larger than the measured ones (%i). \nThe suggested Lmax is: %i', mfilename, lmax, nbvecs, max_lmax);
end

% If the output fibers folder was not passed in, then generate one in the current
% mrDiffusion session.
if notDefined('mrtrix_folder'), mrtrix_folder = [session, 'mrtrix']; end

% Make the folder where to save the fibers if it doe snot exist yet.
if ~exist(mrtrix_folder, 'dir'), mkdir(mrtrix_folder); end

% Generate a file name that contains the information of the original file
% that was used for tracking.
fname_trunk  = fullfile(mrtrix_folder, dwiname); 

% Build the mrtrix file names.
files = mrtrix_build_files(fname_trunk, lmax);

% Check wich processes were already computed and which ones need to be done.
computed = mrtrix_check_processes(files);

% Convert the raw dwi data to the mrtrix format: 
if (~computed.('dwi')), mrtrix_mrconvert(dwRawFile, files.dwi); end

% This file contains both bvecs and bvals, as per convention of mrtrix
if (~computed.('b'))
  bvecs = dt_info.files.alignedDwBvecs;
  bvals = dt_info.files.alignedDwBvals;
  mrtrix_bfileFromBvecs(bvecs, bvals, files.b);
end

% Convert the brain mask from mrDiffusion into a .mif file: 
if (~computed.('brainmask'))
  brainMaskFile = fullfile(session, dt_info.files.brainMask); 
  mrtrix_mrconvert(brainMaskFile, files.brainmask, false); 
end

% Generate diffusion tensors:
if (~computed.('dt'))
  mrtrix_dwi2tensor(files.dwi, files.dt, files.b);
end

% Get the FA from the diffusion tensor estimates: 
if (~computed.('fa'))
  mrtrix_tensor2FA(files.dt, files.fa, files.brainmask);
end

% Generate the eigenvectors, weighted by FA: 
if  (~computed.('ev'))
  mrtrix_tensor2vector(files.dt, files.ev, files.fa);
end

% Create a white-matter mask. Tractography will act only within this mask.
if (~computed.('wm'))
    if notDefined('wmMaskFile') || isempty('wmMaskFile')
        % Use mrDiffusion default white-matter mask
        wmMaskFile = fullfile(session, dt_info.files.wmMask);
    end
    fprintf('[%s] Creating WM mask from file: %s\n', mfilename, wmMaskFile);
    mrtrix_mrconvert(wmMaskFile, files.wm);
end

% Estimate the response function of single fibers. 
% We use the max_lmax to estimate the response.
if (~computed.('response'))    
  mrtrix_response(files.wm, files.fa, files.sf, files.dwi, ...
      files.response, files.b, [], true,false, min([6,max_lmax]));
end

% Compute the CSD estimates: 
if (~computed.('csd'))  
  disp('The following step takes a while (a few hours)');                                  
  mrtrix_csdeconv(files.dwi, files.response, lmax, files.csd, files.b, files.brainmask);
end

end

