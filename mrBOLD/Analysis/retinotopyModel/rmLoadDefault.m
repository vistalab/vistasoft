function vw = rmLoadDefault(vw, useLog)
% rmLoadDefault: load the default maps from a pRF model.
%
% vw = rmLoadDefault(vw, [useLog=0]);
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
if notDefined('vw'),		vw = getCurView;		end
if notDefined('useLog'),	useLog = 0;				end

% exit gracefully if a rmModel is not selected
if isempty(viewGet(vw, 'rmModel'))
    warning('No pRF model selected')
    return; 
end


vw = rmLoad(vw, 1, 'varexplained', 'co');
vw = rmLoad(vw, 1, 'sigma', 'amp');
vw = rmLoad(vw, 1, 'polar-angle', 'ph');

if useLog==1, vw = rmLoad(vw, 1, 'logeccentricity', 'map');	
else          vw = rmLoad(vw, 1, 'eccentricity', 'map'); end

params = viewGet(vw, 'rmparams');

vw = setPhWindow(vw, [0 2*pi]);
vw = setCothresh(vw, .1);

% limit map (eccentricity) and amp (pRF size) to stimulus extent 
if useLog==1, mapMax = min(1.3, log10(params.analysis.maxRF) * .75);
else      	  mapMax = min(30, params.analysis.maxRF); end
ampMax = params.analysis.maxRF;
vw = viewSet(vw, 'map clip', [0 mapMax]); % or [0 ~20] degrees
vw = viewSet(vw, 'amp clip', [0 ampMax]);

vw.ui.coMode  = setColormap(vw.ui.coMode,  'blueredyellowCmap');
vw.ui.mapMode = setColormap(vw.ui.mapMode, 'hsvTbCmap');
vw.ui.ampMode = setColormap(vw.ui.ampMode, 'jetCmap');

updateGlobal(vw);
vw  = refreshScreen(vw);

return
