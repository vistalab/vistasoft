function campicopdfs(picotablefile, inputmodel, fit_filename, pdfs_file)
% 
% campicopdfs(picotablefile, [inputmodel='dt'], fit_filename, pdfs_file)
% 
% Compute the probability density function for Probabilistic tractography
% (PICO) in Camino.
% 
% INPUTS:
%   picotablefile:  The lookup table file for PICo tracking 
% 
%   inputmodel:     The voxelwise diffusion model used for tracking. The 
%                   default is 'dt', which means tensor model. 
% 
%   fit_filename:   The filename including the information of voxelwise 
%                   diffusion model fit (e.g. tensor fit)
% 
%   pdfs_file:      The output file describing the probability density
%                   function within the voxel used for PICo tracking
% 
% (C) Hiromasa Takemura, CiNet HHS/Stanford VISTA team, 2015

if notDefined('inputmodel');
    inputmodel = 'dt';
end

% Execute conversion
cmd = sprintf('picopdfs -inputmodel %s -luts %s < %s > %s', inputmodel, picotablefile, fit_filename, pdfs_file);
display(cmd);
system(cmd,'-echo');

return
