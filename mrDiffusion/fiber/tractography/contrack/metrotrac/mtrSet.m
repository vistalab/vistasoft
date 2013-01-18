function mtr = mtrSet(mtr,param,val,varargin)
% Set data for MetroTrac (mtr) structure
%
%  val = mtrSet(mtr,param,val,varargin)
%
% Set the parameters of a mtr structure.
% Access this structure should go through this routine and through
%    mtrGet.
%
%

if ieNotDefined('mtr'), error('No MetroTrac structure defined.'); end
if ieNotDefined('param'), error('No parameter defined'); end
if ieNotDefined('val'), val = []; end

switch lower(param)
    case {'name'}
        mtr.name = val;
    case {'type'}
        mtr.type = val;
    case {'tensors_filename'}
        mtr.tensors_filename = val;
    case {'fa_filename'}
        mtr.fa_filename = val;
    case {'pdf_filename'}
        mtr.pdf_filename = val;
    case {'mask_filename'}
        mtr.mask_filename = val;
    case {'xmask_filename'}
        mtr.Xmask_filename = val;
    case {'compute_fa'}
        mtr.compute_fa = val;
    case {'require_way'}
        mtr.require_way = val;
    case {'sampler_type'}
        mtr.sampler_type = val;
    case {'desired_samples'}
        mtr.desired_samples = val;
    case {'burnin'}
        mtr.burnin = val;
    case {'max_nodes'}
        mtr.max_nodes = val;
    case {'min_nodes'}
        mtr.min_nodes = val;
    case {'step_size'}
        mtr.step_size = val;
    case {'skip_samples'}
        mtr.skip_samples = val;
    case {'roi'}
        if length(varargin) ~= 2, error('Incomplete mtrSet'); end
        arg1 = varargin{1};
        arg2 = varargin{2};
        switch lower(arg2)
            case {'coords'}
                mtr.roi{arg1}.coords = val;
            case {'valid_cortex'}
                mtr.roi{arg1}.valid_cortex = val;
            case {'seed_region'}
                mtr.roi{arg1}.seed_region = val;
        end
    case {'translate'}
        mtr.translate = val;
    case {'isr'}
        mtr.isr = val;
    case {'esr'}
        mtr.esr = val;
    case {'temp_swap'}
        mtr.temp_swap = val;
    case {'inv_temp'}
        mtr.inv_temp = val;
    case {'start_path_tries'}
        mtr.start_path_tries = val;
    case {'save_out_spacing'}
        mtr.save_out_spacing = val;
    case {'fa_absorb'}
        mtr.fa_absorb = val;
    case {'abs_normal'}
        mtr.abs_normal = val;
    case {'abs_penalty'}
        mtr.abs_penalty = val;
    case {'smooth_std'}
        mtr.smooth_std = val;
    case {'angel_cutoff'}
        mtr.angle_cutoff = val;        
    case {'shape_params_vec'}
        mtr.shape_params_vec = val;
end

return;
