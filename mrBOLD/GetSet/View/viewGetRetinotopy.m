function val = viewGetRetinotopy(vw,param,varargin)
% Get data from various view structures
%
% This function is wrapped by viewGet. It should not be called by anything
% else other than viewGet.
%
% This function retrieves information from the view that relates to a
% specific component of the application.
%
% We assume that input comes to us already fixed and does not need to be
% formatted again.

if notDefined('vw'), vw = getCurView; end
if notDefined('param'), error('No parameter defined'); end

mrGlobals;
val = [];


switch param
    
    case 'framestouse'
        % Return a vector of time frames in the current or specified
        % scan to be used for coranal (block) analyses
        %   frames = viewGet(vw,'frames to use');
        %   scan = 1; frames = viewGet(vw,'frames to use',scan);
        if isempty(varargin) || isempty(varargin{1})
            scan = viewGet(vw, 'CurScan');
        else
            scan = varargin{1};
        end
        dt         = viewGet(vw, 'dtStruct');
        blockParms = dtGet(dt,'bparms',scan);
        if checkfields(blockParms, 'framesToUse')
            val = blockParms.framesToUse;
        else
            val = 1: viewGet(vw,'nFrames',scan);
        end
        
    case 'rmfile'
        % Return the path to the currently loaded retinotopy model.
        %   rmFile = viewGet(vw, 'retinotopy model file');
        if checkfields(vw, 'rm', 'retinotopyModelFile')
            val = vw.rm.retinotopyModelFile;
        else
            val = [];
        end
    case 'rmmodel'
        % Return the currently loaded retinotopy model struct.
        %   rm = viewGet(vw, 'retinotopy model');
        if checkfields(vw, 'rm', 'retinotopyModels')
            val = vw.rm.retinotopyModels;
        else
            val = [];
        end
        
    case 'rmcurrent'
        % Return the currently selected retinotopy model struct. Note that
        % there may be multiple models loaded.
        %   rm = viewGet(vw, 'rm current model');
        if checkfields(vw, 'rm', 'retinotopyModels')
            val = vw.rm.retinotopyModels{ viewGet(vw, 'rmModelNum') };
        else
            val = [];
        end
    case 'rmmodelnames'
        % Return the description of currently loaded retinotopy models.
        %   models = viewGet(vw, 'rm model names');
        %   models = viewGet(vw, 'retinotopy model names');
        models = viewGet(vw, 'Retinotopy Model');
        val = cell(1,numel(models));
        for n = 1:numel(models)
            val{n} = rmGet(models{n},'description');
        end
    case 'rmparams'
        % Return the retinotopy model parameters.
        %   params = viewGet(vw, 'Retinotopy Parameters');
        if checkfields(vw,'rm')
            val = vw.rm.retinotopyParams;
        end
    case 'rmstimparams'
        % Return the retinotopy model stimulus parameters. This is a subset
        % of the retinopy model parameters.
        %   stimParams = viewGet(vw, 'RM Stimulus Parameters');
        if checkfields(vw,'rm','retinotopyParams','stim')
            val = vw.rm.retinotopyParams.stim;
        end
    case 'rmmodelnum'
        % Return the retinotopy model number that is currently selected.
        % (There may be more than one model loaded.)
        %   modelNum = viewGet(vw, 'Retinotopy Model Number');
        if checkfields(vw, 'rm', 'modelNum') && ...
                ~isempty(vw.rm.modelNum)
            val = vw.rm.modelNum;
        else
            val = rmSelectModelNum(vw);
        end
    case 'rmhrf'
        % Return the hrf struct for the current retinopy model. This struct
        % contains a descriptor (such as 'two gammas (SPM style)') and the
        % parameters associated with this function.
        %   rmhrf = viewGet(vw, 'Retinotopy model HRF');
        if checkfields(vw,'rm','retinotopyParams','stim')
            val1 = vw.rm.retinotopyParams.stim.hrfType;
            switch(lower(val1))
                case {'one gamma (boynton style)','o','one gamma' 'b' 'boynton'}
                    val2 = vw.rm.retinotopyParams.stim.hrfParams{1};
                case {'two gammas (spm style)' 't' 'two gammas' 'spm'}
                    val2 = vw.rm.retinotopyParams.stim.hrfParams{2};
                case {'impulse' 'no hrf' 'none'}
                    val2 = [];
                otherwise
                    val2 = [];
            end
            val = {val1 val2};
        end
        
        
    otherwise
        error('Unknown viewGet parameter');
        
end

return
