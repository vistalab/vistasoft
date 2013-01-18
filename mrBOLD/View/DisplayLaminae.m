function view = DisplayLaminae(view)

% view = DisplayLaminae(view);
%
% Displays the laminar-distance map as a form of parameter map.
%
% Ress, 6/04

mrGlobals

if ~isfield(view, 'laminae'), view = LoadLaminae(view); end
if ~isfield(view, 'laminae'), return, end

nScans = length(dataTYPES(view.curDataType).scanParams);
view = setParameterMap(view, repmat({view.laminae}, nScans, 1), 'laminarDistanceMap');
view = setDisplayMode(view, 'map');
view = refreshScreen(view);
