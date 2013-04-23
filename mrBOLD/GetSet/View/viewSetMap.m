function vw = viewSetMap(vw,param,val,varargin)
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
    
    case 'map'
        vw.map = val;
    case 'mapname'
        if isequal(lower(val), 'dialog')
            % dedicated dialog for map name / units / clip
            vw = mapNameDialog(vw);
        else
            vw.mapName = val;
        end
    case 'mapunits'
        vw.mapUnits = val;
    case 'mapclip'
        if checkfields(vw, 'ui', 'mapMode')
            vw.ui.mapMode.clipMode = val;
            vw = refreshScreen(vw);
        else
            warning('vista:viewError', ...
                'Can''t set Map Clip Mode -- no UI information in this view.');
        end
    case 'mapwin'
        vw = setMapWindow(vw, val);
    case 'scanmap'
        if length(varargin) < 1, scan = viewGet(vw, 'curscan');
        else                     scan = varargin{1}; end
        vw.map{scan} = val;
    case 'zoom'
        vw.ui.zoom = val;
        
    otherwise
        error('Unknown view parameter %s.', param);
        
end %switch

return