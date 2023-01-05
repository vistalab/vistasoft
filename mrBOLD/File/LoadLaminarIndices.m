function view = LoadLaminarIndices(view)

% view = LoadLaminarIndices(view);
%
% Load the laminar indices, if they are available as a file in the current
% view directory. If not, offer to calculate them. For backward style
% conformance, this takes an optional volume view input, and returns the
% volume with laminar coordinate indices field "laminarIndices" loaded.
% However, if the view is not supplied, the currently selected VOLUME is
% operated upon and returned. Returns an empty variable if something goes
% wrong, e.g., the user % decides not to calculate the indices, which takes
% some time.
%
% Ress, 10/05

mrGlobals

if ieNotDefined('view')
  selectedVOLUME = viewSelected('Volume');
  view = VOLUME{selectedVOLUME};
end
if ~strcmp(view.viewType, 'Gray'), view = switch2Gray(view); end
fName = fullfile(viewDir(view), 'laminarIndices.mat');
if exist(fName, 'file')
  data = load(fName);
  VOLUME{selectedVOLUME}.laminarIndices = data.laminarIndices;
else
  yn = questdlg('No laminar coordinates file. Calculate coordinates?');
  if strcmp(yn, 'Yes'), MapLaminarIndices, end
end

if isfield(VOLUME{selectedVOLUME}, 'laminarIndices')
  view = VOLUME{selectedVOLUME};
else
  view = [];
end
