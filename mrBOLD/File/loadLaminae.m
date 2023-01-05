function view = LoadLaminae(view)
% view = LoadLaminae(view);
%
% Loads laminar-distance map and inserts it into the view.
%
% Ress, 6/04
fName = fullfile(viewDir(view), 'lamina.mat');
if ~exist(fName, 'file')
   Alert(['No laminar distance map file: ', fName]);
else
  fprintf('Loading from %s ... ', fName);
  load(fName);
  fprintf('done.\n');
  view.laminae = laminae;
end
