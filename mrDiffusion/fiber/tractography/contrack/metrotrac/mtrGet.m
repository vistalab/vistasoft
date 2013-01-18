function val = mtrGet(mtr,param,varargin)
% Retrieve data from MetroTrac (mtr) structure
%
%  val = mtrGet(mtr,param,varargin)
%
% Read the parameters of a mtr structure.
% Access this structure should go through this routine and through
%    mtrSet.
%
%

if ieNotDefined('mtr'), error('No MetroTrac structure defined.'); end
if ieNotDefined('param'), error('No parameter defined'); end

val = [];

switch lower(param)
    case {'name'}
        val = mtr.name;
    case {'type'}
        val = mtr.type;
    case {'tensors_filename'}
        val = mtr.tensors_filename;
    case {'fa_filename'}
        val = mtr.fa_filename;
    case {'pdf_filename'}
        val = mtr.pdf_filename;
    case {'mask_filename'}
        val = mtr.mask_filename;
    case {'xmask_filename'}
        val = mtr.Xmask_filename;
    case {'require_way'}
        val = mtr.require_way;
    case {'compute_fa'}
        val = mtr.compute_fa;
    case {'sampler_type'}
        val = mtr.sampler_type;
    case {'desired_samples'}
        val = mtr.desired_samples;
    case {'burnin'}
        val = mtr.burnin;
    case {'max_nodes'}
        val = mtr.max_nodes;
    case {'min_nodes'}
        val = mtr.min_nodes;
    case {'step_size'}
        val = mtr.step_size;
    case {'skip_samples'}
        val = mtr.skip_samples;
    case {'roi'}
        if length(varargin) ~= 2, error('Incomplete mtrGet for ROI'); end
        arg1 = varargin{1};
        arg2 = varargin{2};
        switch lower(arg2)
            case {'coords'}
                val = mtr.roi{arg1}.coords;
            case {'valid_cortex'}
                val = mtr.roi{arg1}.valid_cortex;
            case {'seed_region'}
                val = mtr.roi{arg1}.seed_region;
        end
    case {'translate'}
        val = mtr.translate;
    case {'isr'}
        val = mtr.isr;
    case {'esr'}
        val = mtr.esr;
    case {'temp_swap'}
        val = mtr.temp_swap;
    case {'inv_temp'}
        val = mtr.inv_temp;
    case {'start_path_tries'}
        val = mtr.start_path_tries;
    case {'save_out_spacing'}
        val = mtr.save_out_spacing;
    case {'fa_absorb'}
        val = mtr.fa_absorb;
    case {'abs_normal'}
        val = mtr.abs_normal;
    case {'abs_penalty'}
        val = mtr.abs_penalty;
    case {'smooth_std'}
        val = mtr.smooth_std;
    case {'angle_cutoff'}
        val = mtr.angle_cutoff;
    case {'shape_params_vec'}
        val = mtr.shape_params_vec;
end

return;
