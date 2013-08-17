%% Define params
s_cam_definitions;

%% Load image for pathway xforms
ni_seg = niftiRead(fullfile(mask_dir,seg_filename));
% Calc xform from camino space to acpc space
xform = ni_seg.qto_xyz;
xform(1:3,1:3) = eye(3);
xform_cam_to_acpc = xform;
xform_cam_to_acpc(1:3,4) = xform_cam_to_acpc(1:3,4)+diag(ni_seg.qto_xyz(1:3,1:3))/2;
xform_img_to_acpc = ni_seg.qto_xyz;
fd_size = ni_seg.dim;

%% Fix image header
%filename = fullfile(camino_dir,'acm','t_mesd_gm_rh_exit_1cm_acm_sc.nii.gz');
filename = fullfile(camino_dir,'fa.nii.gz');
ni = niftiRead(filename);
dtiWriteNiftiWrapper(ni.data, xform_img_to_acpc, filename);

%% Load generated paths
% Load camino path file
tractsFile = fullfile(camino_dir,'tracts_clean.Bfloat');
fg_temp = mtrImportFibers(tractsFile);
fg = dtiNewFiberGroup;
fg.fibers = fg_temp.fibers;
%fg = dtiXformFiberCoords(fg, xform_cam_to_acpc);
mtrExportFibers(fg,fullfile(camino_dir,'tracts.pdb'));

%% Make fiber density map of all occ lobe
tractsFile = fullfile(camino_dir,'tracts_occ.Bfloat');
fg_temp = mtrImportFibers(tractsFile,eye(4));
fg = dtiNewFiberGroup;
fg.fibers = fg_temp.fibers;
fg = dtiXformFiberCoords(fg, xform_cam_to_acpc);
fd_img = dtiComputeFiberDensityNoGUI(fg, xform_img_to_acpc, fd_size);
dtiWriteNiftiWrapper(fd_img, xform_img_to_acpc, fullfile(camino_dir,'tracts_occ.nii.gz'));
% Intersect occ map with cortex
tracts_filename = 'tracts_occ.nii.gz';
ni_tracts = niftiRead(fullfile(camino_dir, tracts_filename));
ni_c = niftiRead(fullfile(mask_dir,'gm.nii.gz'));
ni_tracts.fname = fullfile(camino_dir,'tracts_occ_gm.nii.gz');
ni_tracts.data(ni_c.data==0) = 0;
writeFileNifti(ni_tracts);
% Intersect with retinotopic cortex
ni_tracts = niftiRead(fullfile(camino_dir, tracts_filename));
ni_c = niftiRead(fullfile(mask_dir,'atlas_mask.nii.gz'));
ni_tracts.fname = fullfile(camino_dir,'tracts_occ_atlas.nii.gz');
ni_tracts.data(ni_c.data==0) = 0;
writeFileNifti(ni_tracts);

%% Make fiber density map of exiting occ lobe
tractsFile = fullfile(camino_dir,'tracts_occ_exit.Bfloat');
fg_temp = mtrImportFibers(tractsFile,eye(4));
fg = dtiNewFiberGroup;
fg.fibers = fg_temp.fibers;
fg = dtiXformFiberCoords(fg, xform_cam_to_acpc);
fd_img = dtiComputeFiberDensityNoGUI(fg, xform_img_to_acpc, fd_size);
dtiWriteNiftiWrapper(fd_img, xform_img_to_acpc, fullfile(camino_dir,'tracts_occ_exit.nii.gz'));
% Intersect occ map with cortex
tracts_filename = 'tracts_occ_exit.nii.gz';
ni_tracts = niftiRead(fullfile(camino_dir, tracts_filename));
ni_c = niftiRead(fullfile(mask_dir,'gm.nii.gz'));
ni_tracts.fname = fullfile(camino_dir,'tracts_occ_exit_gm.nii.gz');
ni_tracts.data(ni_c.data==0) = 0;
writeFileNifti(ni_tracts);
% Intersect with retinotopic cortex
ni_tracts = niftiRead(fullfile(camino_dir, tracts_filename));
ni_c = niftiRead(fullfile(mask_dir,'atlas_mask.nii.gz'));
ni_tracts.fname = fullfile(camino_dir,'tracts_occ_exit_atlas.nii.gz');
ni_tracts.data(ni_c.data==0) = 0;
writeFileNifti(ni_tracts);

%% Tract surface measurements

%% Fix residual image
ni_b0 = niftiRead(fullfile(dti_dir,'b0.nii.gz'));
ni = niftiRead(fullfile(camino_dir,'wdt_rmsqr.nii.gz'));
ni_b0.fname =  fullfile(camino_dir,'wdt_rmsqr.nii.gz');
ni_b0.data = ni.data;
%ni_b0.data = ni.data(1:-1:end,:,:);
writeFileNifti(ni_b0);

%% Examine residuals
ni_mse = niftiRead(fullfile(camino_dir,'wdt_rmsqr.nii.gz'));
ni_std = niftiRead(fullfile(camino_dir,'wdt_std.nii.gz'));
ni_std.data(ni_std.data>100) = 100;
ni_mse.data(ni_mse.data>100) = 100;
showMontage(ni_std.data)
showMontage(ni_mse.data)
e_ratio = zeros(ni_std.dim);
e_ratio(ni_std.data>0) = ni_mse.data(ni_std.data>0) ./ ni_std.data(ni_std.data>0);
showMontage(e_ratio)

% Fix label image
filename_labels = fullfile(camino_dir,'cbs_labels_1_1_0.nii.gz');
ni = niftiRead(filename_labels);
ni_labels = ni_occ;
ni_labels.fname = filename_labels;
ni_labels.data = ni.data;
writeFileNifti(ni_labels);

filename_labels = fullfile(camino_dir,'cbs_labelcp_1_1_0.nii.gz');
ni = niftiRead(filename_labels);
ni_labels = ni_occ;
ni_labels.fname = filename_labels;
ni_labels.data = ni.data;
writeFileNifti(ni_labels);
