function val = viewGetEm(vw,param,varargin)
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
    
    case 'datavalindex'
        if (~isfield(vw,'emStruct'))
            error('emStruct structure required in the generalGray view');
        end
        val=vw.emStruct.curDataValIndex;
        
    case 'analysisdomain'
        if (~isfield(vw.ui,'analysisDomainButtons'))
            error('This option requires a generalGray vw');
        end
        
        if (get(vw.ui.analysisDomainButtons(1),'Value')), val='time';
        else             val='frequency';
        end
        
        
    otherwise
        error('Unknown viewGet parameter');
        
end

return
