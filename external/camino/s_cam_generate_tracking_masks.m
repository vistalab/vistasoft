%% Define params
s_cam_definitions;

%% Interpolate all data used for camino masks
mkdir(mask_dir);
files_to_interp = {roi_map_filename};%,ecc_map_filename,var_map_filename,seg_filename,t1_filename};
for ff = 1:length(files_to_interp)
    filename = files_to_interp{ff};
    %[foo1, xform_filename, ext, foo2] = fileparts(filename);
    %xform_filename = ['xform_', xform_filename, ext];
    camAlignImageToDTI( fullfile(dti_dir,b0_filename), ...
            fullfile(ret_dir,filename),...  
            fullfile(mask_dir,filename));
end

%% Load all reinterpolated data
ni_seg = niftiRead(fullfile(mask_dir,seg_filename));
ni_var = niftiRead(fullfile(mask_dir,var_map_filename));
ni_ecc = niftiRead(fullfile(mask_dir,ecc_map_filename));
ni_rois = niftiRead(fullfile(mask_dir,roi_map_filename));

%% Gray Matter Mask
% RH
ni_gm = ni_seg;
ni_gm.fname = fullfile(mask_dir,'gm_rh.nii.gz');
% Grab only right hemisphere GM
ni_gm.data(ni_seg.data~=6) = 0;
ni_gm.data(ni_gm.data>0) = 1;
% Only GM within occipital lobe
ni_gm.data(:,occ_exit:end,:)=0;
% Write file
writeFileNifti(ni_gm);

% LH
ni_gm = ni_seg;
ni_gm.fname = fullfile(mask_dir,'gm_lh.nii.gz');
% Grab only right hemisphere GM
ni_gm.data(ni_seg.data~=5) = 0;
ni_gm.data(ni_gm.data>0) = 1;
% Only GM within occipital lobe
ni_gm.data(:,occ_exit:end,:)=0;
% Write file
writeFileNifti(ni_gm);

%% Do the White Matter mask
% RH
ni_wm = ni_seg;
ni_wm.fname = fullfile(mask_dir,'wm_rh.nii.gz');
% Initialize 
ni_wm.data=zeros(size(ni_seg.data));
% Get the white matter of RH
ni_wm.data(ni_seg.data==4)=1;
% exit plane
ni_wm.data(:,occ_exit+1:end,:)=0;
%write the file
writeFileNifti(ni_wm);

% RH
ni_wm = ni_seg;
ni_wm.fname = fullfile(mask_dir,'wm_lh.nii.gz');
% Initialize 
ni_wm.data=zeros(size(ni_seg.data));
% Get the white matter of LH
ni_wm.data(ni_seg.data==3)=1;
% exit plane
ni_wm.data(:,occ_exit+1:end,:)=0;
%write the file
writeFileNifti(ni_wm);

%% Also create med-res white matter mask for seeds
%camAlignImageToDTI( fullfile(dti_dir,b0_filename), fullfile(mask_dir,'wm_rh.nii.gz'), fullfile(mask_dir,'wm_rh_lowres.nii.gz'), [1 1 1]);
%camAlignImageToDTI( fullfile(dti_dir,b0_filename), fullfile(mask_dir,'wm_lh.nii.gz'), fullfile(mask_dir,'wm_lh_lowres.nii.gz'), [1 1 1]);

%% Do the White Matter exit plane
% RH
ni_exit = ni_seg;
ni_exit.fname = fullfile(mask_dir,'wm_rh_exit.nii.gz');
% Initialize 
ni_exit.data=zeros(size(ni_seg.data));
% Get the white matter of RH
ni_exit.data(ni_seg.data==4)=1;
% exit plane
ni_exit.data(:,occ_exit+1:end,:)=0;
ni_exit.data(:,1:occ_exit-1,:)=0;
%write the file
writeFileNifti(ni_exit);

% RH
ni_exit = ni_seg;
ni_exit.fname = fullfile(mask_dir,'wm_lh_exit.nii.gz');
% Initialize 
ni_exit.data=zeros(size(ni_seg.data));
% Get the white matter of LH
ni_exit.data(ni_seg.data==3)=1;
% exit plane
ni_exit.data(:,occ_exit+1:end,:)=0;
ni_exit.data(:,1:occ_exit-1,:)=0;
%write the file
writeFileNifti(ni_exit);

%% Occ Lobe Mask
% RH
ni_occ = ni_seg;
ni_occ.fname = fullfile(mask_dir,'occ_rh_mask.nii.gz');
ni_gm = niftiRead(fullfile(mask_dir,'gm_rh.nii.gz'));
% Grab only right hemisphere GM and WM
ni_occ.data(ni_seg.data~=6 & ni_seg.data~=4) = 0;
ni_occ.data(ni_occ.data>0) = 1;
% Make sure all the GM voxels are included
ni_occ.data(ni_gm.data>0) = 1;
% Only GM within occipital lobe
ni_occ.data(:,occ_exit+1:end,:)=0;
% Write file
writeFileNifti(ni_occ);

% LH
ni_occ = ni_seg;
ni_occ.fname = fullfile(mask_dir,'occ_lh_mask.nii.gz');
ni_gm = niftiRead(fullfile(mask_dir,'gm_lh.nii.gz'));
% Grab only left hemisphere GM and WM
ni_occ.data(ni_seg.data~=5 & ni_seg.data~=3) = 0;
ni_occ.data(ni_occ.data>0) = 1;
% Make sure all the GM voxels are included
ni_occ.data(ni_gm.data>0) = 1;
% Only GM within occipital lobe
ni_occ.data(:,occ_exit+1:end,:)=0;
% Write file
writeFileNifti(ni_occ);

%% Create a background mask in native diffusion space
%ni_b0 = niftiRead(fullfile(dti_dir,b0_filename));
%lowres_pixdim = ni_b0.pixdim;
%camAlignImageToDTI( fullfile(dti_dir,b0_filename), fullfile(mask_dir,'occ_rh_mask.nii.gz'), fullfile(mask_dir,'bgmask_rh.nii.gz'), lowres_pixdim);
%camAlignImageToDTI( fullfile(dti_dir,b0_filename), fullfile(mask_dir,'occ_lh_mask.nii.gz'), fullfile(mask_dir,'bgmask_lh.nii.gz'), lowres_pixdim);

%% Define outside occ lobe for exclusion purposes
% RH
ni_occ = niftiRead( fullfile(mask_dir,'occ_rh_mask.nii.gz') );
ni_not_occ = niftiRead(fullfile(mask_dir,'occ_rh_mask.nii.gz'));
ni_not_occ.fname = fullfile(mask_dir,'not_occ_rh_mask.nii.gz');
ni_not_occ.data(ni_occ.data==0) = 1;
ni_not_occ.data(ni_occ.data==1) = 0;
writeFileNifti(ni_not_occ);
% LH
ni_occ = niftiRead( fullfile(mask_dir,'occ_lh_mask.nii.gz') );
ni_not_occ = niftiRead(fullfile(mask_dir,'occ_lh_mask.nii.gz'));
ni_not_occ.fname = fullfile(mask_dir,'not_occ_lh_mask.nii.gz');
ni_not_occ.data(ni_occ.data==0) = 1;
ni_not_occ.data(ni_occ.data==1) = 0;
writeFileNifti(ni_not_occ);

%% Image that defines the occipital exit plane and GM as two ROIs
% RH
ni_occ_exit = niftiRead(fullfile(mask_dir,'wm_rh_exit.nii.gz'));
ni_occ_exit.fname = fullfile(mask_dir,'occ_rh_exit.nii.gz');
ni_gm = niftiRead(fullfile(mask_dir,'gm_rh.nii.gz'));
ni_occ_exit.data(ni_gm.data>0) = 2;
writeFileNifti(ni_occ_exit);
% Now the mask
ni_occ_exit_mask = ni_occ_exit;
ni_occ_exit_mask.fname = fullfile(mask_dir,'occ_rh_exit_mask.nii.gz');
ni_occ_exit_mask.data(ni_occ_exit_mask.data>0) = 1;
writeFileNifti(ni_occ_exit_mask);

% LH
ni_occ_exit = niftiRead(fullfile(mask_dir,'wm_lh_exit.nii.gz'));
ni_occ_exit.fname = fullfile(mask_dir,'occ_lh_exit.nii.gz');
ni_gm = niftiRead(fullfile(mask_dir,'gm_lh.nii.gz'));
ni_occ_exit.data(ni_gm.data>0) = 2;
writeFileNifti(ni_occ_exit);
% Now the mask
ni_occ_exit_mask = ni_occ_exit;
ni_occ_exit_mask.fname = fullfile(mask_dir,'occ_lh_exit_mask.nii.gz');
ni_occ_exit_mask.data(ni_occ_exit_mask.data>0) = 1;
writeFileNifti(ni_occ_exit_mask);

%% Create label map, each voxel in GM map has some meaningful number
% Sweep out various variance explained thresholds
var_thresh = 0.1:0.05:0.3;
for vv = var_thresh
    filename = fullfile(mask_dir,sprintf('atlas_%s_%.2f.nii.gz',var_atlas_root,vv));
    data = ni_var.data;
    data(ni_var.data>vv) = 1;
    data(data<1) = 0;
    dtiWriteNiftiWrapper(data,ni_var.qto_xyz,filename);
    filename = fullfile(mask_dir,sprintf('atlas_%s_%s_%.2f.nii.gz',ecc_atlas_root,var_atlas_root,vv));
    ecc = ni_ecc.data;
    ecc = ecc.*data;
    ecc(ecc>0 & ecc<=5) = 5;
    ecc(ecc>50 & ecc<=10) = 10;
    ecc(ecc>10) = 15;
    dtiWriteNiftiWrapper(ecc,ni_var.qto_xyz,filename);
end

% Ventral ROIs
data = zeros(ni_rois.dim);
data_nov1 = zeros(ni_rois.dim);
for ll = roi_ventral_lbls
    data(ni_rois.data==ll) = 1;
    if ll~=1 && ll~=2
        data_nov1(ni_rois.data==ll) = 1;
    end
end
filename = fullfile(mask_dir,sprintf('atlas_%s.nii.gz',roi_ventral_atlas_root));
dtiWriteNiftiWrapper(data,ni_rois.qto_xyz,filename);
filename = fullfile(mask_dir,sprintf('atlas_%s.nii.gz',roi_ventral_nov1_atlas_root));
dtiWriteNiftiWrapper(data_nov1,ni_rois.qto_xyz,filename);
% Ecc Ventral
var = 0.2;
filename = fullfile(mask_dir,sprintf('atlas_%s_%s_%.2f.nii.gz',ecc_atlas_root,var_atlas_root,var));
ecc = niftiRead(filename);
ecc.data(data==0) = 0;
filename = fullfile(mask_dir,sprintf('atlas_%s_%s_%s_%.2f.nii.gz',roi_ventral_atlas_root,ecc_atlas_root,var_atlas_root,var));
dtiWriteNiftiWrapper(ecc.data,ecc.qto_xyz,filename);

% Dorsal ROIs
data = zeros(ni_rois.dim);
data_nov1 = zeros(ni_rois.dim);
for ll = roi_dorsal_lbls
    data(ni_rois.data==ll) = 1;
    if ll~=1 && ll~=2
        data_nov1(ni_rois.data==ll) = 1;
    end
end
filename = fullfile(mask_dir,sprintf('atlas_%s.nii.gz',roi_dorsal_atlas_root));
dtiWriteNiftiWrapper(data,ni_rois.qto_xyz,filename);
filename = fullfile(mask_dir,sprintf('atlas_%s.nii.gz',roi_dorsal_nov1_atlas_root));
dtiWriteNiftiWrapper(data_nov1,ni_rois.qto_xyz,filename);
% Ecc Dorsal
var = 0.2;
filename = fullfile(mask_dir,sprintf('atlas_%s_%s_%.2f.nii.gz',ecc_atlas_root,var_atlas_root,var));
ecc = niftiRead(filename);
ecc.data(data==0) = 0;
filename = fullfile(mask_dir,sprintf('atlas_%s_%s_%s_%.2f.nii.gz',roi_dorsal_atlas_root,ecc_atlas_root,var_atlas_root,var));
dtiWriteNiftiWrapper(ecc.data,ecc.qto_xyz,filename);

% Visual Field Cluster ROIs

% C1
data = zeros(ni_rois.dim);
for ll = roi_c1_lbls
    data(ni_rois.data==ll) = 1;
end
filename = fullfile(mask_dir,sprintf('atlas_%s.nii.gz',roi_c1_atlas_root));
dtiWriteNiftiWrapper(data,ni_rois.qto_xyz,filename);
filename = fullfile(mask_dir,sprintf('atlas_%s_%s_%.2f.nii.gz',ecc_atlas_root,var_atlas_root,var));
% C1 ECC
var = 0.2;
ecc = niftiRead(filename);
ecc.data(data==0) = 0;
filename = fullfile(mask_dir,sprintf('atlas_%s_%s_%s_%.2f.nii.gz',roi_c1_atlas_root,ecc_atlas_root,var_atlas_root,var));
dtiWriteNiftiWrapper(ecc.data,ecc.qto_xyz,filename);

% CMT
data = zeros(ni_rois.dim);
for ll = roi_cmt_lbls
    data(ni_rois.data==ll) = 1;
end
filename = fullfile(mask_dir,sprintf('atlas_%s.nii.gz',roi_cmt_atlas_root));
dtiWriteNiftiWrapper(data,ni_rois.qto_xyz,filename);
filename = fullfile(mask_dir,sprintf('atlas_%s_%s_%.2f.nii.gz',ecc_atlas_root,var_atlas_root,var));
% CMT ECC
var = 0.2;
ecc = niftiRead(filename);
ecc.data(data==0) = 0;
filename = fullfile(mask_dir,sprintf('atlas_%s_%s_%s_%.2f.nii.gz',roi_cmt_atlas_root,ecc_atlas_root,var_atlas_root,var));
dtiWriteNiftiWrapper(ecc.data,ecc.qto_xyz,filename);

% CVO
data = zeros(ni_rois.dim);
for ll = roi_cvo_lbls
    data(ni_rois.data==ll) = 1;
end
filename = fullfile(mask_dir,sprintf('atlas_%s.nii.gz',roi_cvo_atlas_root));
dtiWriteNiftiWrapper(data,ni_rois.qto_xyz,filename);
filename = fullfile(mask_dir,sprintf('atlas_%s_%s_%.2f.nii.gz',ecc_atlas_root,var_atlas_root,var));
% CVO ECC
var = 0.2;
ecc = niftiRead(filename);
ecc.data(data==0) = 0;
filename = fullfile(mask_dir,sprintf('atlas_%s_%s_%s_%.2f.nii.gz',roi_cvo_atlas_root,ecc_atlas_root,var_atlas_root,var));
dtiWriteNiftiWrapper(ecc.data,ecc.qto_xyz,filename);

% cv3ab
data = zeros(ni_rois.dim);
for ll = roi_cv3ab_lbls
    data(ni_rois.data==ll) = 1;
end
filename = fullfile(mask_dir,sprintf('atlas_%s.nii.gz',roi_cv3ab_atlas_root));
dtiWriteNiftiWrapper(data,ni_rois.qto_xyz,filename);
filename = fullfile(mask_dir,sprintf('atlas_%s_%s_%.2f.nii.gz',ecc_atlas_root,var_atlas_root,var));
% cv3ab ECC
var = 0.2;
ecc = niftiRead(filename);
ecc.data(data==0) = 0;
filename = fullfile(mask_dir,sprintf('atlas_%s_%s_%s_%.2f.nii.gz',roi_cv3ab_atlas_root,ecc_atlas_root,var_atlas_root,var));
dtiWriteNiftiWrapper(ecc.data,ecc.qto_xyz,filename);


%% Plot number of exit voxels vs. variance explained threshold
hem_names = {'lh','rh'};
var_thresh = 0.1:0.05:0.3;
exit_data = zeros(length(hem_names),length(var_thresh));
for hh = 1:2
    hem = hem_names{hh};
    % Load exit wm
    filename = fullfile(mask_dir,sprintf('wm_%s_exit.nii.gz',hem));
    ni = niftiRead(filename);
    num_vox_exit = sum(ni.data(:)>0);
    % Go through each variance explained level
    for vv = 1:length(var_thresh)
        var = var_thresh(vv);
        filename = fullfile(mask_dir,sprintf('%s_%s_%d_%s_%.2f_%s.nii.gz',cbs_root,hem,num_tracks,var_atlas_root,var,lbl_post));
        ni = niftiRead(filename);
        exit_data(hh,vv) = sum(ni.data(:)>0) / num_vox_exit;
    end
end

figure;
bar(var_thresh,exit_data');
legend(hem_names);
xlabel('Variance Explained');
title('Fraction of voxels connected to retinotopic occ. cortex');
