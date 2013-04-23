function vw = viewSetEm(vw,param,val,varargin)
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
    
    case 'datavalindex'
        % Only works on the generalGray view type
        if ~isequal(vw.viewType, 'generalGray')
            error('Can only set DataValIndex in General Gray views.')
        end
        vw.emStruct.curDataValIndex=val;
        
    otherwise
        error('Unknown view parameter %s.', param);
        
end %switch

return