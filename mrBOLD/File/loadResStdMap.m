function view=loadResStdMap(view)
%
% view=loadMeanMap(view)
%
% Checks view.mapName field of the view structure.  
% If view.mapName is not "resStdMap", then load it,
% and call setParameterMap.
%
% If you change this function make parallel changes in:
%   loadCorAnal, loadResStdMap, loadStdMap, loadMeanMap
%
% djh, 7/16/99, modified from loadCorAnal

if ~strcmp(view.mapName,'resStdMap')
   pathStr=fullfile(dataDir(view), 'resStdMap.mat');
   if ~exist(pathStr,'file')
     warning(['No ',pathStr,' file.  Run compute resStd map from Analysis menu.']);
     return
   else
      disp(['loading resStdMap from ',pathStr]);
      load(pathStr);
      view=setParameterMap(view,map,'resStdMap');
   end
end
