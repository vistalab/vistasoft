function v = computeProjectedMap(v, field);
% computeProjectedMap - load projected correlation/amp field into parameter field
%
% view = computeProjCorMap(view, field);
%
% field = 'co' [default], or 'amp'
%
% BW?
% RAS: sets display mode fields properly as well. I kind of liked having a
% separate display mode for this. If we go through all the trouble of
% maintaining these unwieldy co, amps, and ph fields, we might as well make
% use of that specialized meta-information, so we can threshold with ph,
% field, etc., and not lose field information here.
if notDefined('v'),   error('Need view struct'); end;
if ~isfield(v,'co') || isempty(v.co),    v = loadCorAnal(v);        end;
if ~isfield(v,'ph') || isempty(v.ph),    v = loadCorAnal(v);        end;
if ~isfield(v,'refPh'), v = setReferencePhase(v);  end;

% compute projected field
for n=1:numel(v.(field)),
    v.map{n} = v.(field){n} .* cos(v.ph{n} - v.refPh);
end;

% set field name and units
if isequal( lower(field), 'amp' )
	mapStr = 'Amplitude';
else
	mapStr = 'Coherence';
end
v.mapName = sprintf('Projected %s (reference phase=%2.1f rad)', ...
					mapStr, v.refPh);
v.mapUnits = '';				

% set field mode fields, if they exist
if checkfields(v, 'ui', 'mapMode')
	v.ui.displayMode = 'map';
	v = viewSet(v, 'overlaycmap', mrvColorMaps('coolhot', 128));
	v.ui.mapMode.clipMode = [-1 1];
	v = refreshScreen(v);
end

return;
