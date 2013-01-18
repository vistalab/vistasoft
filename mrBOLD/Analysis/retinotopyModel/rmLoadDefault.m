function view = rmLoadDefault(view, useLog)
% rmLoadDefault: load the default maps from a pRF model.
%
% view = rmLoadDefault(view, [useLog=0]);
%
% This does some of the standard rmLoad operations I use when I'm checking
% out a pRF model:
%	* loads the var explained into the coherence slot
%	* loads the polar angle into the phase slot
%	* loads the eccentricity into the amp slot
%	* loads the pRF size into the map slot
%	* sets the clip modes for co mode and map mode to reasonable values
% 
% If no pRF model is yet loaded, loads the most recently-created model.
%
% The optional 'useLog' argument specifies whether to load the eccentricity
% map in log units. [default: 1, use log units]
%
% ras, 11/2007.
if notDefined('view'),		view = getCurView;		end
if notDefined('useLog'),	useLog = 0;				end
try
	viewGet(view, 'rmModelNum');
catch ME
	error('No pRF Model loaded. Please Load a Model.');
end

view = rmLoad(view, 1, 'varexplained', 'co');
view = rmLoad(view, 1, 'sigma', 'amp');
view = rmLoad(view, 1, 'polar-angle', 'ph');
if useLog==1
	view = rmLoad(view, 1, 'logeccentricity', 'map');	
else
	view = rmLoad(view, 1, 'eccentricity', 'map');
end

params = viewGet(view, 'rmparams');

view = setPhWindow(view, [0 2*pi]);
view = setCothresh(view, .1);

% limit map (eccentricity) and amp (pRF size) to stimulus extent 
if useLog==1
	mapMax = min(1.3, log10(params.analysis.maxRF) * .75);
else
	mapMax = min(30, params.analysis.maxRF);
end
ampMax = params.analysis.maxRF;
view = setClipMode(view, 'map', [0 mapMax]); % or [0 ~20] degrees
view = setClipMode(view, 'amp', [0 ampMax]);

view.ui.coMode = setColormap(view.ui.coMode, 'blueredyellowCmap');
view.ui.mapMode = setColormap(view.ui.mapMode, 'hsvTbCmap');
view.ui.ampMode = setColormap(view.ui.ampMode, 'jetCmap');

updateGlobal(view);
view  = refreshScreen(view);

return
