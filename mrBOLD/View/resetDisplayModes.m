function vw = resetDisplayModes(vw, numGrays, numColors)
%
% vw = resetDisplayModes(vw, numGrays, numColors)
%
% Initializes/resets displayModes and colormaps for each of the
% possible displayModes.  See refreshScreen.
%
% djh, 1/98
% ras, 09/04 -- added option to up the # of grays/colors, 
% trying to move towards using truecolor images

if (notDefined('numGrays')), numGrays = 128; end
if (notDefined('numColor')), numColors = 128; end

vw.ui.anatMode.clipMode = 'auto';
vw.ui.anatMode.numGrays = numGrays;
vw.ui.anatMode.numColors = numColors;
vw.ui.anatMode = setColormap(vw.ui.anatMode,'grayCmap');

vw.ui.coMode.clipMode = [0 1];
vw.ui.coMode.numGrays = numGrays;
vw.ui.coMode.numColors = numColors;
vw.ui.coMode = setColormap(vw.ui.coMode,'blueredyellowCmap');

% correlation coefficient
vw.ui.corMode.clipMode = [-1 1];
vw.ui.corMode.numGrays = numGrays;
vw.ui.corMode.numColors = numColors;
vw.ui.corMode = setColormap(vw.ui.corMode,'cool_hotCmap');

vw.ui.ampMode.clipMode = 'auto';
vw.ui.ampMode.numGrays = numGrays;
vw.ui.ampMode.numColors = numColors;
vw.ui.ampMode = setColormap(vw.ui.ampMode,'hotCmap');

% projected amplitude
vw.ui.projampMode.clipMode = 'auto';
vw.ui.projampMode.numGrays = numGrays;
vw.ui.projampMode.numColors = numColors;
vw.ui.projampMode = setColormap(vw.ui.projampMode,'cool_hotCmap');

vw.ui.phMode.clipMode = [0 2*pi];
vw.ui.phMode.numGrays = numGrays;
vw.ui.phMode.numColors = numColors;
vw.ui.phMode = setColormap(vw.ui.phMode,'hsvCmap');

vw.ui.mapMode.clipMode = 'auto';
vw.ui.mapMode.numGrays = numGrays;
vw.ui.mapMode.numColors = numColors;
vw.ui.mapMode = setColormap(vw.ui.mapMode,'hotCmap');

return
