function cam_fix_header(file_to_fix,file_to_src,file_out)

if ieNotDefined('file_out')
    file_out = file_to_fix;
end

%% Load image files
ni_fix = niftiRead(file_to_fix);
ni_src = niftiRead(file_to_src);

%% Fix image header
dtiWriteNiftiWrapper(ni_fix.data, ni_src.qto_xyz, file_out);
