function camTrackPico(seed_filename, numiteration, pdfs_filename, picotract_filename, curv_thresh, stepsize, curveinterval)
%
% camTrackPico(seed_filename, numiteration, pdfs_filename, picotract_filename, [curv_thresh=90], [stepsize=1], [curveinterval=5])
%
% Execute the PICo tracking using Camino
%
% INPUTS: 
%   seed_filename: The nifti file used as the seed for PICo tracking.This
%                  nifti file should have the identical resolution and data 
%                  matrix size as the original dwi data.
% 
%   numiteration:       The number of iterations in PICo 
% 
%   pdfs_filename:      The filename of probability density functions 
% 
%   picotract_filename: The filename for streamline file in Bfloat format
%                 
%   curv_thresh:        curvature threshold (default = 90)
% 
%   stepsize:           tracking step size (default = 1)
% 
%   curveinterval: The curvature threshold will not be applied if 
%                  streamline length is shorter than the curveinterval
%                  (default = 5)
% 
% For details of PICo Tracking parameter settings, please check Camino's
% website http://cmic.cs.ucl.ac.uk/camino//index.php?n=Man.Track
% 
% (C) Hiromasa Takemura, CiNet HHS/Stanford VISTA Team, 2015

if notDefined('curv_thresh')
    curv_thresh = 90;
end

if notDefined('stepsize')
    stepsize = 1;
end

if notDefined('curveinterval')
    curveinterval = 5;
end

% Execute tracking
cmd = sprintf('track -inputmodel pico -seedfile %s -iterations %s -curvethresh %s -stepsize %s -curveinterval %s < %s > %s', seed_filename, num2str(numiteration), num2str(curv_thresh), num2str(stepsize), num2str(curveinterval), pdfs_filename, picotract_filename);
display(cmd);
system(cmd,'-echo');

return

