function camImage2Voxel(raw_filename,raw_bfloat_filename)
%Call image2voxel from Camino to visualize a data file
%
%
%  camImage2Voxel(raw_filename,raw_bfloat_filename)
%
%
% (c) Stanford Vista, 2010, Sherbondy
%
cmd = ['image2voxel -4dimage ' raw_filename ' > ' raw_bfloat_filename];
display(cmd);
system(cmd,'-echo');

return
