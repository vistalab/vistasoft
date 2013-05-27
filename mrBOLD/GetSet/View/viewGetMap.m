function val = viewGetMap(vw,param,varargin)
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
    
    case 'map'
        % Return the parameter map for the current data type. Map is cell
        % array 1 x nscans.
        %   map = viewGet(vw, 'map');
        val = vw.map;
    case 'mapwin'
        % Return mapWindow values from mapWindow sliders (non-hidden views)
        % or from the view.settings.mapWin field (hidden views).
        %   mapWin = viewGet(vw, 'Map Window');
        val = getMapWindow(vw);
    case 'mapname'
        % Return the name of the current paramter map (string), e.g.,
        % 'eccentricty'.
        %   mapName = viewGet(vw, 'Map Name');
        val = vw.mapName;
    case 'mapunits'
        % Return the map units for the current paramter map (string), e.g.,
        % 'degrees'. The map units are for display only; they are not used
        % for calculations.
        %   mapUnits = viewGet(vw, 'Map Units');
        val = vw.mapUnits;
    case 'mapclip'
        % Return map clip values. These are the clip values for the
        % colorbar. They are not the clip values in the slider (which are
        % called 'mapwin'). Values outside of mapclip are colored the same
        % as the minimum or maximum value according to the color lookup
        % table. Values outside of mapwin are not shown at all.
        %   mapClip = viewGet(vw, 'Map Window');
        if checkfields(vw, 'ui', 'mapMode', 'clipMode')
            val = vw.ui.mapMode.clipMode;
            if isempty(val), val = 'auto';  end
        else
            warning('vista:viewError', 'No Map Mode UI information found in view. Returning empty');
            val = [];
        end
    case 'scanmap'
        % Return the parameter map for the currently selected or the
        % specified scan.
        %   scanMap = viewGet(vw, 'scan map')
        %   scan = 1; scanMap = viewGet(vw, 'scan map', scan);
        if length(varargin) < 1,    nScan = viewGet(vw, 'curScan');
        else                        nScan = varargin{1}; end
        % Sometimes there is no map loaded. If this is the case,
        % return an empty array rather than crashing
        nMaps=length(vw.map);
        if (nMaps>=nScan), val = vw.map{nScan};
        else               val=[];        end
        
    otherwise
        error('Unknown viewGet parameter');
        
end

return
