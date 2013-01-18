function mtr = mtrCreate()
% Create MetroTrac (mtr) structure
%
%  mtr = mtrCreate()
%
% Create MetroTrac structure that contains all the information needed to
% generate pathways with the MetroTrac algorithm.
%
%
mtr.tensors_filename = '';
mtr.fa_filename = '';
mtr.pdf_filename = '';
mtr.mask_filename = '';
mtr.Xmask_filename = '';
mtr.compute_fa = 'false';
mtr.require_way = 'false';
mtr.sampler_type = 'SISR';
mtr.desired_samples = 50000;
mtr.burnin = 1;
mtr.max_nodes = 240;
mtr.min_nodes = 30;
mtr.step_size = 1;
mtr.skip_samples = 1;
%mtr.roi{1}.center = [0 0 0];
%mtr.roi{1}.length = [1 1 1];
mtr.roi{1}.coords = [1 1 1; 2 2 2];
mtr.roi{1}.valid_cortex = 'true';
mtr.roi{1}.seed_region = 'true';
%mtr.roi{2}.center = [0 0 0];
%mtr.roi{2}.length = [1 1 1];
mtr.roi{2}.coords = [1 1 1; 3 3 3];
mtr.roi{2}.valid_cortex = 'true';
mtr.roi{2}.seed_region = 'true';
mtr.translate = 0;
mtr.isr = 0;
mtr.esr = 1;
mtr.temp_swap = 0.1;
mtr.inv_temp = 1;
mtr.start_path_tries = 1;
mtr.save_out_spacing = 100;
mtr.fa_absorb = 0.01;
mtr.abs_normal = 0;
mtr.abs_penalty = 0;
mtr.smooth_std = 14;
mtr.angle_cutoff = 130;
mtr.shape_params_vec = [0.175 0.15 100];

return;