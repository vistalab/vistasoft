function vw = viewSetRetinotopy(vw,param,val,varargin)
%Organize methods for setting view parameters.
%
% This function is wrapped by viewSet. It should not be called by anything
% else other than viewSet.
%
% This function retrieves information from the view that relates to a
% specific component of the application.
%
% We assume that input comes to us already fixed and does not need to be
% formatted again.

if notDefined('vw'),  error('No view defined.'); end
if notDefined('param'), error('No parameter defined'); end
if notDefined('val'),   val = []; end

mrGlobals;

switch param
    
    case 'rmfile'
        vw.rm.retinotopyModelFile = val;
    case 'rmmodel'
        vw.rm.retinotopyModels = val;
    case 'rmparams'
        vw.rm.retinotopyParams = val;
    case 'rmstimparams'
        vw.rm.retinotopyParams.stim = val;
    case 'rmmodelnum'
        if isequal(val, 'dialog')
            val = rmSelectModelNum(vw);
            vw.rm.modelNum = val;
        else
            vw.rm.modelNum = val;
        end
        
        
    otherwise
        error('Unknown view parameter %s.', param);
        
end %switch

return