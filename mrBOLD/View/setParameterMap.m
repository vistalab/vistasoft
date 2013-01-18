function vw = setParameterMap(vw, parMap, mapName, mapUnits)
%
% vw = setParameterMap(vw, parMap, [mapName], [mapUnits])
%
% Sets the field vw.map = parMap, after checking that parMap has the
% correct size.
% sets vw.mapName=mapNname;
%
% djh, 12/30/98
% rmk, 1/15/99 added map name parameter
% djh, 4/99.  Added calls to reset the mapWin sliders according
%   to the min/max of the parameter map.
% djh, 7/99.  Updated code that checks the size.  It was only
%   written for the inplane vw.
% dbr, 12/99. Fixed single-scan singlet dimension problem.
% djh, 2/22/2001. Changed to cell array.
% ras, 02/04. If there are more scans specified in dataTYPES for this data
% type than exist in the map dir, will just pad it out. Did this b/c I
% often add new averages scans as I extend my analyses; I realize it may
% allow mismatched param maps to go by unnoticed, but figure that's less
% likely.
% ras, 04/04. Also: if any par maps are loaded for other scans, don't
% delete those -- just punch in maps for scans assigned to the parMap.
% ras, 05/04: Made the test more stringent for distinguishing hidden v 
% non-hidden views.
if notDefined('mapName');	mapName='';		end
if notDefined('mapUnits');	mapUnits='';	end

if length(parMap) < viewGet(vw, 'numScans')
    parMap{viewGet(vw, 'numScans')} = [];
end

checkSize(vw,parMap);

% clear out the old map field
vw.map = cell(1, viewGet(vw, 'numScans'));

for s = 1:viewGet(vw, 'numScans')
    if ~isempty(parMap{s})
		vw.map{s} = parMap{s};
        mapName(mapName=='_') = '-'; % dodge the TeX interpreter :)
		vw.mapName = mapName;
		vw.mapUnits = mapUnits;
    end
end

if isfield(vw, 'ui') && isfield(vw.ui,'windowHandle'); % test for non-hidden vw    
    vw = setDisplayMode(vw, 'map');
end

return
