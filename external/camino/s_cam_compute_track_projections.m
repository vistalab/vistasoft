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

%% Count voxels
% Parameter for determining if a voxel has enough fibers to be connected
% Needs to be in comparison to how else the fiber is connected
fiber_cthresh = 0;
% Gray Matter
ni_gm = niftiRead(fullfile(mask_dir,'gm.nii.gz'));
num_gm_vox = sum(ni_gm.data(:)>0);
num_fibers_gen = num_gm_vox * 10;
% Eccentricity
ni_ecc = niftiRead(fullfile(mask_dir,'ecc_var_0.1.nii.gz'));
ni_ecc.data(ni_gm.data==0) = 0;
ecc_vox = ni_ecc.data(ni_ecc.data>0);
num_ret_vox = numel(ecc_vox);
ratio_ret_gm = num_ret_vox / num_gm_vox;
% ROIs
ni_roi = niftiRead(fullfile(mask_dir,'rois.nii.gz'));
ni_roi.data(ni_gm.data==0) = 0;
roi_vox = ni_roi.data(ni_roi.data>0);
num_roi_vox = numel(roi_vox);
ratio_roi_gm = num_roi_vox / num_gm_vox;

%% Occipital exiting connections
% Considering eccentricity
ni_fiber_gm_exit = niftiRead(fullfile(camino_dir,'tracts_mesd_gm_exit_1cm_ends.nii.gz'));
%ni_fiber_gm = niftiRead(fullfile(acm_dir,'tracts_pico_gm_1cm_acm_sc.nii.gz'));
num_gm_exit_vox = sum(ni_fiber_gm_exit.data(:)>fiber_cthresh & ni_gm.data(:)>0); 
ecc_exit_vox = ni_ecc.data(ni_fiber_gm_exit.data>fiber_cthresh & ni_ecc.data>0);
num_ret_exit_vox = numel(ecc_exit_vox);
ratio_ret_exit = num_ret_exit_vox / num_gm_exit_vox;
ecc_ebins = [0,2,5,10,30];
ecc_cbins = (ecc_ebins(2:end)-ecc_ebins(1:end-1))/2 + ecc_ebins(1:end-1);
n = histc(ecc_vox,ecc_ebins);
n_exit = histc(ecc_exit_vox,ecc_ebins);
figure, bar(ecc_cbins,[n(1:end-1)/sum(n) n_exit(1:end-1)/sum(n_exit)]);
legend({'all','exit'})
xlabel('Degrees Eccentricity');

% Considering ROIs
roi_exit_vox = ni_roi.data(ni_fiber_gm_exit.data>fiber_cthresh & ni_roi.data>0);
num_roi_exit_vox = numel(roi_exit_vox);
roi_ids = min(unique(roi_vox)):max(unique(roi_vox));
roi_ebins = roi_ids(1)-0.5:1:roi_ids(end)+0.5;
n = histc(roi_vox,roi_ebins);
n_exit = histc(roi_exit_vox,roi_ebins);
figure, bar(roi_ids,[n(1:end-1)/sum(n) n_exit(1:end-1)/sum(n_exit)]);
legend({'all','exit'})
xlabel('ROI ID');

% Exit vs. Stay
exit_stay_vox = double(ni_fiber_gm_exit.data(ni_fiber_gm.data>0));
stay_vox = double(ni_fiber_gm.data(ni_fiber_gm.data>0));
figure, scatter(exit_stay_vox,stay_vox)

%% Calculate endpoint connectivity maps
file_root = 't_pico_gm_rh_exit_1cm';
tractsFile = fullfile(tract_dir,[file_root '.Bfloat']);
fg_temp = mtrImportFibers(tractsFile);
fg = dtiNewFiberGroup;
fg.fibers = fg_temp.fibers;
fg = dtiXformFiberCoords(fg, xform_cam_to_acpc);
fdImg = dtiComputeFiberDensityNoGUI(fg, xform_img_to_acpc, fd_size, [], [], 1);
dtiWriteNiftiWrapper(fdImg, xform_img_to_acpc, fullfile(tract_dir,[file_root '.nii.gz']));

% Some voxel comparisons
ni_a = niftiRead(fullfile(camino_dir,'tracts_pico_gm_1cm_ends.nii.gz'));
ni_e = niftiRead(fullfile(camino_dir,'tracts_mesd_gm_exit_1cm_ends.nii.gz'));
a_vox = ni_a.data(ni_a.data>0);
e_vox = ni_e.data(ni_a.data>0);
figure, plot(a_vox,e_vox,'.');
axis equal;
axis([0,max(a_vox(:)),0,max(a_vox(:))]);

