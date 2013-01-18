function ctr = ctrSet(ctr,param,val,varargin)
% Set data for ConTrac (ctr) structure
%
%  val = ctrSet(ctr,param,val,varargin)
%
% Set the parameters of a ctr structure.
% Access this structure should go through this routine and through
%    ctrGet.
%
%
% Parameters:
%
%
%

if notDefined('ctr'), error('No MetroTrac structure defined.'); end
if notDefined('param'), error('No parameter defined'); end
if notDefined('val'), val = []; end

switch lower(param)
    case {'version'}
        ctr.version = val;
    case {'name'}
        ctr.name = val;
    case {'type'}
        ctr.type = val;
    case {'image_directory'}
        ctr.image_directory = val;
    case {'tensors_filename'}
        ctr.tensors_filename = val;
    case {'fa_filename'}
        ctr.fa_filename = val;
    case {'pdf_filename'}
        ctr.pdf_filename = val;
    case {'mask_filename'}
        ctr.mask_filename = val;
    case {'xmask_filename'}
        ctr.Xmask_filename = val;
    case {'compute_fa'}
        ctr.compute_fa = val;
    case {'require_way'}
        ctr.require_way = val;
    case {'sampler_type'}
        ctr.sampler_type = val;
    case {'desired_samples'}
        ctr.desired_samples = val;
    case {'burnin'}
        ctr.burnin = val;
    case {'max_nodes'}
        ctr.max_nodes = val;
    case {'min_nodes'}
        ctr.min_nodes = val;
    case {'step_size'}
        ctr.step_size = val;
    case {'skip_samples'}
        ctr.skip_samples = val;
    case {'roi'}
        % Example
        % ctrSet(ctr,'roi',val,whichROI,'coords');
        % ctrSet(ctr,'roi',val,whichROI,'valid_cortex');
        if length(varargin) ~= 2, error('Incomplete ctrSet'); end
        arg1 = varargin{1};
        arg2 = varargin{2};
        switch lower(arg2)
            case {'coords'}
                ctr.roi{arg1}.coords = val;
            case {'valid_cortex'}
                ctr.roi{arg1}.valid_cortex = val;
            case {'seed_region'}
                ctr.roi{arg1}.seed_region = val;
        end
    case {'translate'}
        ctr.translate = val;
    case {'isr'}
        ctr.isr = val;
    case {'esr'}
        ctr.esr = val;
    case {'temp_swap'}
        ctr.temp_swap = val;
    case {'inv_temp'}
        ctr.inv_temp = val;
    case {'start_path_tries'}
        ctr.start_path_tries = val;
    case {'save_out_spacing'}
        ctr.save_out_spacing = val;
    case {'fa_absorb'}
        ctr.fa_absorb = val;
    case {'abs_normal'}
        ctr.abs_normal = val;
    case {'abs_penalty'}
        ctr.abs_penalty = val;
    case {'smooth_std'}
        ctr.smooth_std = val;
    case {'angle_cutoff'}
        ctr.angle_cutoff = val;        
    case {'shape_params_vec'}
        ctr.shape_params_vec = val;
end

return;
