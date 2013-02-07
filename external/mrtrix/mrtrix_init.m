function files = mrtrix_init(dt6, lmax, mrtrix_folder, wmMaskFile)
%
% function files = mrtrix_init(dt6, lmax, mrtrix_folder, [wmMaskFile])
% 
% Initialize an mrtrix CSD analysis
%
% This function computes all the files needed to use mrtrix_track. 
%
% - Inputs -
%    dt6  - string, full-path to an mrInit-generated dt6 file. 
%    lmax - The maximal harmonic order to fit in the spherical deconvolution (d
%           model. Must be an even integer. This input determines the
%           flexibility  of the resulting model fit (higher values correspond
%           to more flexible models), but also determines the number of
%           parameters that need to be fit. The number of dw directions
%           acquired should be larger than the number of parameters required.	
%           lmax: 4  -> nParams 15
%           lmax: 8  -> nParms  45
%           lmax: 12 -> nParmas 91
%           General formula: lmax = n	nParams = ½ (n+1)(n+2)
%           http://www.brain.org.au/software/mrtrix/tractography/preprocess.html
%
%    mrtrix_folder - Name of the output folder
%    wmMaskFile    - Full path to a nifti file to be used as WM mask,
%                    in replacemnt of the default WM mask found in the dt6 file.
%
% - Outputs -
%    files - The full-path to the files created
%
% - Notes -
%   This functionn performs the following operations:
%
%   1. Convert the raw dwi file into .mif format
%   2. Convert the bvecs, bvals into .b format
%   3. Convert the brain-mask to .mif format 
%   4. Fit DTI and calculate FA and EV images
%   5. Estimate the response function for single fibers, based on voxels with
%      FA > 0.7
%   6. Fit the CSD model. 
%   7. Convert the white-matter mask to .mif format. 
% 
% For details: 
% http://www.brain.org.au/software/mrtrix/tractography/preprocess.html
% 
% Bob, Ariel & Franco (c) Stanford Vista Team 2012

% Loading the dt file containing all the paths to the fiels we need.
dt_info = load(dt6);

% Strip the file names out of the dt6 strings. 
dwRawFile   = dt_info.files.alignedDwRaw;
fname_trunk = dwRawFile(1:strfind(dwRawFile,'.')-1);
raw_idx     = strfind(fname_trunk,'raw');
if isempty(raw_idx), error('Could not find raw directory'); end

% Strip out the name information for the mrDiffusion folders.
session      = fname_trunk(1:raw_idx-1);

% If the outtput fiber folder was nto passed in generate one in the current
% mrDiffusion session.
if notDefined('mrtrix_folder'), mrtrix_folder = [session, 'mrtrix']; end

% Generate a file name that contains the information of the original file
% that was used for tracking.
fname_trunk  = [mrtrix_folder, fname_trunk(raw_idx+3:end)]; 
file_sep_idx = strfind(fname_trunk, filesep);
mrtrix_dir   = fname_trunk(1:file_sep_idx(end)); 

% Make the folder where to save the fibers if it doe snot exist yet.
if ~exist(mrtrix_dir, 'dir'), mkdir(mrtrix_dir); end

% Build the mrtrix file names.
files = mrtrix_build_files(fname_trunk,lmax);

% Check wich processes were already computed and which ons need to be doen.
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

% Estimate the response function of single fibers: 
if (~computed.('response'))
  mrtrix_response(files.brainmask, files.fa, files.sf, files.dwi,...
      files.response, files.b, true) % That last 'true' means a figure of the 
                                  % response function will be displayed
end

% Create a white-matter mask, tracktography will act only in here.
if (~computed.('wm'))
    if notDefined('wmMaskFile') || isempty('wmMaskFile')
        % Use mrDiffusion default white-matter mask
        wmMaskFile = fullfile(session, dt_info.files.wmMask);
    end
    mrtrix_mrconvert(wmMaskFile, files.wm)
end

% Compute the CSD estimates: 
if (~computed.('csd'))  
  disp('The following step takes a while (a few hours)');                                  
  mrtrix_csdeconv(files.dwi, files.response, lmax, files.csd, files.b, files.brainmask)
end


%%%%%%%%%%%%%%%%%%%%%%
% mrtrix_build_files %
%%%%%%%%%%%%%%%%%%%%%%
function files = mrtrix_build_files(fname_trunk,lmax)
%
% Builds a structure with the mrtrix file names.
%

% Convert the raw dwi data to the mrtrix format: 
files.dwi = strcat(fname_trunk,'_dwi.mif');

% This file contains both bvecs and bvals, as per convention of mrtrix
files.b     = strcat(fname_trunk, '.b');

% Convert the brain mask from mrDiffusion into a .mif file: 
files.brainmask = strcat(fname_trunk,'_brainmask.mif');

% Generate diffusion tensors:
files.dt = strcat(fname_trunk, '_dt.mif');

% Get the FA from the diffusion tensor estimates: 
files.fa = strcat(fname_trunk, '_fa.mif');

% Generate the eigenvectors, weighted by FA: 
files.ev = strcat(fname_trunk, '_ev.mif');

% Estimate the response function of single fibers: 
files.sf = strcat(fname_trunk, '_sf.mif');
files.response = strcat(fname_trunk, '_response.txt');

% Create a white-matter mask, tracktography will act only in here.
files.wm    = strcat(fname_trunk, '_wm.mif');

% Compute the CSD estimates: 
files.csd = strcat(fname_trunk, sprintf('_csd_lmax%i.mif',lmax)); 




