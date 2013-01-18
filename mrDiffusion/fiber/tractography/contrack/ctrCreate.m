function ctr = ctrCreate(user_defaults)
% Create ConTrac (ctr) structure
%
%   ctr = ctrCreate(user_defaults)
%
% Creates a structure of parameters needed to run ConTrac/MetroTrack.
% 
% Originally by BW?
%
% Modified by DY 7/25/2008 to include calls to ctrSet to install default
% values and allows for the user to pass in a new set of default values
% (user_defaults) if they want, but more needed to make this work. Right
% now, they pass in default values to ctrSet according to what I happen to
% want to be defaults at the moment. 

% Initialize the CTR struct
ctr=struct;

% Set the defaults
% If user_defaults passed in, use them. Otherwise, use defaults below.
if ~notDefined('user_defaults')
    d=user_defaults;
else
    d.version=1; % We are at version 1 on July 18, 2008
    d.image_directory='none';
    d.tensors_filename='none';
    d.fa_filename='none';
    d.pdf_filename='none';
    d.mask_filename='none';
    d.Xmask_filename='none';
    d.script_filename='none';
    d.compute_fa='false';
    d.require_way='false';
    d.sampler_type     = 'SISR';
    d.desired_samples  = 50000;
    d.burnin           = 1;
    d.max_nodes    = 240;
    d.min_nodes    = 3;
    d.step_size    = 1;
    d.skip_samples = 1;
    d.roi{1}.coords = [1 1 1; 2 2 2];
    d.roi{2}.coords = [1 1 1; 3 3 3];
    d.roi{1}.valid_cortex = 'true';
    d.roi{2}.valid_cortex = 'true';
    d.roi{1}.seed_region  = 'true';
    d.roi{2}.seed_region  = 'true';
    d.translate = 0;
    d.isr       = 0;
    d.esr       = 1;
    d.temp_swap = 0.1;
    d.inv_temp  = 1;
    d.start_path_tries = 1;
    d.save_out_spacing = 50;
    d.fa_absorb   = 0.01;
    d.abs_normal  = 0;
    d.abs_penalty = 0;
    d.smooth_std  = 14;
    d.angle_cutoff = 130;
    d.shape_params_vec = [0.175 0.15 100];
end

ctr=ctrSet(ctr,'version',d.version);
ctr=ctrSet(ctr,'tensors_filename',d.tensors_filename);
ctr=ctrSet(ctr,'image_directory',d.image_directory);
ctr=ctrSet(ctr,'fa_filename',d.fa_filename);
ctr=ctrSet(ctr,'pdf_filename',d.pdf_filename);
ctr=ctrSet(ctr,'mask_filename',d.mask_filename);
ctr=ctrSet(ctr,'Xmask_filename',d.Xmask_filename);
ctr=ctrSet(ctr,'script_filename',d.script_filename);
ctr=ctrSet(ctr,'compute_fa',d.compute_fa);
ctr=ctrSet(ctr,'require_way',d.require_way);
ctr=ctrSet(ctr,'sampler_type',d.sampler_type);
ctr=ctrSet(ctr,'desired_samples',d.desired_samples);
ctr=ctrSet(ctr,'burnin',d.burnin);
ctr=ctrSet(ctr,'max_nodes',d.max_nodes);
ctr=ctrSet(ctr,'min_nodes',d.min_nodes );
ctr=ctrSet(ctr,'step_size',d.step_size);
ctr=ctrSet(ctr,'skip_samples',d.skip_samples);
ctr=ctrSet(ctr,'roi',d.roi{1}.coords,1,'coords');
ctr=ctrSet(ctr,'roi',d.roi{2}.coords,2,'coords');
ctr=ctrSet(ctr,'roi',d.roi{1}.valid_cortex,1,'valid_cortex');
ctr=ctrSet(ctr,'roi',d.roi{2}.valid_cortex,2,'valid_cortex');
ctr=ctrSet(ctr,'roi',d.roi{1}.seed_region,1,'seed_region');
ctr=ctrSet(ctr,'roi',d.roi{2}.seed_region,2,'seed_region');
ctr=ctrSet(ctr,'translate',d.translate);
ctr=ctrSet(ctr,'isr',d.isr);
ctr=ctrSet(ctr,'esr',d.esr);
ctr=ctrSet(ctr,'temp_swap',d.temp_swap);
ctr=ctrSet(ctr,'inv_temp',d.inv_temp);
ctr=ctrSet(ctr,'start_path_tries',d.start_path_tries);
ctr=ctrSet(ctr,'save_out_spacing',d.save_out_spacing);
ctr=ctrSet(ctr,'fa_absorb',d.fa_absorb);
ctr=ctrSet(ctr,'abs_normal',d.abs_normal);
ctr=ctrSet(ctr,'abs_penalty',d.abs_penalty);
ctr=ctrSet(ctr,'smooth_std',d.smooth_std);
ctr=ctrSet(ctr,'angle_cutoff',d.angle_cutoff);
ctr=ctrSet(ctr,'shape_params_vec',d.shape_params_vec);
return