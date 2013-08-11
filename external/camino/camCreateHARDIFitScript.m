function camCreateHARDIFitScript(scr_modelfit_filename,scr_after_modelfit_filename,scheme_filename,raw_filename,num_procs,bgthresh)
%
%
%
%
%

% Parameters

% Number parallel processes
if ieNotDefined('num_procs')
    num_procs=1;
end
% Reduced Encoding for spherical deconvolution
re = 16;
% Threshold on b0 for processing background voxels
if ieNotDefined('bgthresh')
    bgthresh = 200;
end
% Volumetric information
raw = niftiRead(raw_filename);
vol_dim = raw.dim;
xd = vol_dim(1);
yd = vol_dim(2);
zd = vol_dim(3);
gd = vol_dim(4);

fid = fopen(scr_modelfit_filename,'wt');
fprintf(fid,'#!/usr/bin/env bash\n\n');

fprintf(fid,'cam_run_mp_hardi_slice.sh %d %d %d %d %d %d %d %s \n', num_procs, re, xd, yd, zd, gd, bgthresh, scheme_filename);

fclose(fid);

fid = fopen(scr_after_modelfit_filename,'wt');
fprintf(fid,'#!/usr/bin/env bash\n\n');

fprintf(fid,'cam_run_after_mp_hardi_slice.sh %d %d %d %d %d %d %d %s \n', num_procs, re, xd, yd, zd, gd, bgthresh, scheme_filename);

fclose(fid);

return
