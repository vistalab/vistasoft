function vol = camVoxel2Image(voxel_order_filename, nifti_filename, data_type, qto_xyz, meas_dim, vol_dim)

fid = fopen(voxel_order_filename,'r','b');
vol = fread(fid,inf,data_type);
fclose(fid);

if notDefined('meas_dim') || meas_dim == 1
    vol = reshape(vol,[vol_dim]);
else
    vol = reshape(vol,[meas_dim vol_dim]);
end

if ~notDefined('nifti_filename')
    dtiWriteNiftiWrapper(vol, qto_xyz, nifti_filename);
end

return;