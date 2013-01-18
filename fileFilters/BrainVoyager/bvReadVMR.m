function bvVMR = bvReadVMR(filename)
%
% AUTHOR:  Wandell
% PURPOSE:
%
% DATE:

fid = fopen(filename,'r','l');

bvVMR.dim(1) = fread(fid,1,'uint16');
bvVMR.dim(2) = fread(fid,1,'uint16');
bvVMR.dim(3) = fread(fid,1,'uint16');

[bvVMR.data] = fread(fid,prod(bvVMR.dim) ,'uint8');

fclose(fid);

return;

