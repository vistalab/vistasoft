function vw = viewSetColorbar(vw,param,val,varargin)
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
    
    case 'cmap'
        % RFBEDIT: Adding flexibility for hidden views
        nGrays      = viewGet(vw, 'curnumgrays');
        displayMode = viewGet(vw, 'displayMode');
        
        % allow transposed version (3 x n) instead of usual matlab cmap order (n x 3)
        if size(val, 2) > 3 && size(val, 1)==3,	val = val'; end
        if max(val(:)) > 1, val = val ./ 255;		end
        
        displayMode = [displayMode 'Mode'];
        vw.ui.(displayMode).cmap(nGrays+1:end,:) = val;
        vw.ui.(displayMode).name = 'user';
        
    case 'cmapmode'
        vw.ui.mapMode = setColormap(vw.ui.mapMode, val); 
    otherwise
        error('Unknown view parameter %s.', param);
        
end %switch

return