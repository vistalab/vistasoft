function view=loadSpatialGradient(view)
%
% view=loadSpatialGradient(view)
%
% Checks view.mapName field of the view structure. 
% If view.mapName is not "spatialGradMap", then loads it.
%
% djh, 11/16/2000, modified from loadMeanMap
pathStr=fullfile(dataDir(view),'spatialGrad.mat');
if ~exist(pathStr,'file')
   myErrorDlg(['No ',pathStr,' file.  Run compute spatial gradient map from Analysis menu.']);
else
	if prefsVerboseCheck,
	   disp(['Loading spatialGradMap from ',pathStr]);
	end
   load(pathStr);
   view.spatialGrad = map;
end

return