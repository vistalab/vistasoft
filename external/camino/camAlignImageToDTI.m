function camAlignImageToDTI(dti_ref_filename,high_res_filename,output_filename,pixdim_tosave)
%
%   camAlignImageToDTI(dti_ref_filename,high_res_filename,output_filename,pixdim_tosave)
%
% EXAMPLE:
%           camAlignImageToDTI('b0.nii.gz','mask_t1.nii.gz','xformed_mask.nii.gz');
%
% (c) Stanford VISTA, 2010


% Experiment with xform
ni_src = niftiRead(high_res_filename);
ni_ref = niftiRead(dti_ref_filename);

ref_dim = ni_ref.dim(1:3);
ref_pixdim = ni_ref.pixdim(1:3);

% If no desired pixel size given, choose the source pixel size
if notDefined('pixdim_tosave')
    pixdim_tosave = ni_src.pixdim(1:3);
end

if pixdim_tosave ~= ni_src.pixdim(1:3)
    % Get bounding box to match the world space of the dti reference
    bound_box = mrAnatXformCoords(ni_ref.qto_xyz,[1 1 1;ref_dim]);
    % Must take into account the pixel size difference that slightly shifts the
    % origin and therefore we must shift the bounding box
    % also (see mrAnatResliceSpm)
    bound_box = bound_box + repmat(rem((pixdim_tosave - ref_pixdim)/2,ref_pixdim),2,1);

    % reslice
    [new_data xform] = mrAnatResliceSpm(ni_src.data, ni_src.qto_ijk, bound_box, pixdim_tosave, [0 0 0 0 0 0]);
else
    new_data = ni_src.data;
    xform = ni_src.qto_xyz;
end

% write
dtiWriteNiftiWrapper(new_data, xform, output_filename);

return
