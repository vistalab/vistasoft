function view = computeSpatialGradient(view)
%
% view = computeSpatialGradient(view)
%
% Loads the meanMap, then uses estFilIntGrad to compute the spatial gradient.
%
% To use this spatial gradient for inhomogeneity correction,
% - set dataTYPES(*).blockedAnalysis(*).inhomoCorrect = 2
% - load spatial gradient (from the File menu)
% - compute corAnal (from the Analysis menu)
%
% djh, 7/11/01
% Ress, 04/05 Modified to allow NaNs in meanMap.

% Tried various alternatives for computing spatial gradient:
% - more blurring in estFilIntGrad
%   [not much difference]
% - aniso3
%   [looks essentially like no blurring]
% - do nothing
%   [looks a lot like estFilIntGrad, except for a scale factor]

% Load meanMap from spatialGradMap.mat, if it exists
view = loadMeanMap(view);

% Initialize to empty cell array
nScans = numScans(view);
map = cell(1,nScans);

%% Compute the robust estimate of spatial gradient from meanMap
% put up a mrvWaitbar if needed
verbose = prefsVerboseCheck;
if verbose
    waitHandle = mrvWaitbar(0,'Computing spatial gradient from mean images.  Please wait...');
end

% main loop: across scans
for iScan = 1:nScans
    map1 = view.map{iScan};
    map1(~isfinite(map1)) = min(map1(:));
    map{iScan} = estFilIntGrad(map1);
    %map{iScan} = estPolIntGrad(view.map{iScan},[3,3,3],1);
    %map{iScan} = aniso3(view.map{iScan},'tukeyPsi',100,100);

    % a 2nd check for non-finite values is necessary (e.g., for motioncomp
    % data)
    map{iScan}( isnan(map{iScan}) | isinf(map{iScan}) ) = min(map1(:));

    if verbose, mrvWaitbar(iScan/nScans); end
end

if verbose
    close(waitHandle);
end

% Initial save; so if setParameterMap fails we're not screwed
mapName = 'spatialGrad';
save( fullfile(dataDir(view), 'spatialGrad.mat'), 'map', 'mapName' );

% Set parameter map
view = setParameterMap(view,map,'spatialGrad');

% Save file (again)
saveParameterMap(view);

return

