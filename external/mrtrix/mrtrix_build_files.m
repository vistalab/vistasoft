function files = mrtrix_build_files(fname_trunk,lmax)
% Builds a structure with the names of the files that the MRtrix commands
% will generate and need.
%
% files = mrtrix_build_files(fname_trunk,lmax)
%
% Franco Pestilli, Ariel Rokem, Bob Dougherty Stanford University

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

end
