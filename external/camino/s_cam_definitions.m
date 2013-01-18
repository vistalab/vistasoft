% Define the occipital exit plane
occ_exit = 80;

% Define functional map we are going to use
data_dir = '/Users/sherbond/data/camino_tuts/rb090930';
ret_dir = fullfile(data_dir,'retinotopy');
dti_dir = fullfile(data_dir,'dti150','bin');
camino_dir = fullfile(data_dir,'camino');
mask_dir = fullfile(camino_dir,sprintf('masks_occ%d_05_Aug_2010',occ_exit));
tract_dir = fullfile(camino_dir,'tracts');
acm_dir = fullfile(camino_dir,'acm');
roi_map_filename = 'ROIs-03-Aug-2010.nii.gz';
ecc_map_filename = 'eccentricity-RB-08-Dec-2009.nii.gz';
var_map_filename = 'varianceExplained-RB-08-Dec-2009.nii.gz';
var_atlas_root = 'var';
ecc_atlas_root = 'ecc';
seg_filename = 't1_class_gray.nii.gz';
b0_filename = 'b0.nii.gz';
t1_filename = 't1.nii.gz';

% ROIs
%RH
% Clusters
%Occ Pole: 2 5 6 11 12 14 17 18
%MT   21 22
%VO:  25 26
%V3ab: 10
%LH:
% Clusters
%Occ Pole: 1 3 4 8 9 13 15 16
%MT   19 20
%VO:  23 24
%V3ab: 7
roi_ventral_atlas_root = 'rois_ventral';
roi_ventral_nov1_atlas_root = 'rois_ventral_nov1';
roi_ventral_lbls = [1,2,4,6,9,12:14,23:26];

roi_dorsal_atlas_root = 'rois_dorsal';
roi_dorsal_nov1_atlas_root = 'rois_dorsal_nov1';
roi_dorsal_lbls = [1,2,3,5,7,8,10,11];

roi_c1_atlas_root = 'rois_c1';
roi_c1_lbls = [1:6,8,9,11:18];

roi_cmt_atlas_root = 'rois_cmt';
roi_cmt_lbls = [19:22];

roi_cvo_atlas_root = 'rois_cvo';
roi_cvo_lbls = [23:26];

roi_cv3ab_atlas_root = 'rois_cv3ab';
roi_cv3ab_lbls = [7,10];

% CBS Ouptut
num_tracks = 100;
cbs_root = 'ret_exit_count/cbs';
lbl_post = 'labels_1_1_0';