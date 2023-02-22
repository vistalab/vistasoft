function view=loadStdMap(view)
%
% view=loadStdMap(view)
%
% Checks view.mapName field of the view structure.  
% If view.mapName is not "meanMap", then load it,
% and call setParameterMap.
%
% If you change this function make parallel changes in:
%   loadCorAnal, loadResStdMap, loadStdMap, loadMeanMap
%
% djh, 2/21/2001, modified from loadMeanMap

if ~strcmp(view.mapName,'stdMap')
   pathStr=fullfile(dataDir(view),'stdMap.mat');
   if ~exist(pathStr,'file')
      warning(['No ',pathStr,' file.  Run compute std map from Analysis menu.']);
   else
      disp(['loading stdMap from ',pathStr]);
      load(pathStr);
      view=setParameterMap(view,map,'stdMap');
   end
end
