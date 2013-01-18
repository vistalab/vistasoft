function val = ctrGet(ctr,param,varargin)
% Retrieve data from ConTrack structure
%
%  val = ctrGet(ctr,param,varargin)
%
% Read the parameters of a ctr structure.
% Access this structure should go through this routine and through
%   ctrSet.
%
% Parameters:
%
%
%

if notDefined('ctr'), error('No ConTrack structure defined.'); end
if notDefined('param'), error('No parameter defined'); end

val = [];

switch lower(param)
    case {'version'}
        val = ctr.version;
    case {'name'}
        val = ctr.name;
    case {'type'}
        val = ctr.type;
    case {'image_directory'}
        val = ctr.image_directory;
    case {'tensors_filename'}
        val = ctr.tensors_filename;
    case {'fa_filename'}
        val = ctr.fa_filename;
    case {'pdf_filename'}
        val = ctr.pdf_filename;
    case {'mask_filename'}
        val = ctr.mask_filename;
    case {'xmask_filename'}
        val = ctr.Xmask_filename;
    case {'require_way'}
        val = ctr.require_way;
    case {'compute_fa'}
        val = ctr.compute_fa;
    case {'sampler_type'}
        val = ctr.sampler_type;
    case {'desired_samples'}
        val = ctr.desired_samples;
    case {'burnin'}
        val = ctr.burnin;
    case {'max_nodes'}
        val = ctr.max_nodes;
    case {'min_nodes'}
        val = ctr.min_nodes;
    case {'step_size'}
        val = ctr.step_size;
    case {'skip_samples'}
        val = ctr.skip_samples;
    case {'roi'}
        if length(varargin) ~= 2, error('Incomplete ctrGet for ROI'); end
        arg1 = varargin{1};
        arg2 = varargin{2};
        switch lower(arg2)
            case {'coords'}
                val = ctr.roi{arg1}.coords;
            case {'valid_cortex'}
                val = ctr.roi{arg1}.valid_cortex;
            case {'seed_region'}
                val = ctr.roi{arg1}.seed_region;
        end
    case {'translate'}
        val = ctr.translate;
    case {'isr'}
        val = ctr.isr;
    case {'esr'}
        val = ctr.esr;
    case {'temp_swap'}
        val = ctr.temp_swap;
    case {'inv_temp'}
        val = ctr.inv_temp;
    case {'start_path_tries'}
        val = ctr.start_path_tries;
    case {'save_out_spacing'}
        val = ctr.save_out_spacing;
    case {'fa_absorb'}
        val = ctr.fa_absorb;
    case {'abs_normal'}
        val = ctr.abs_normal;
    case {'abs_penalty'}
        val = ctr.abs_penalty;
    case {'smooth_std'}
        val = ctr.smooth_std;
    case {'angle_cutoff'}
        val = ctr.angle_cutoff;
    case {'shape_params_vec'}
        val = ctr.shape_params_vec;
end

return;
