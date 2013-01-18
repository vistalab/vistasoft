function view = switch2Vol(view)
%
% Switches Volume view to volume mode:
% - changes view.subdir to 'Volume'
% - sets view.ui.grayVolButtons=2
% - computes/loads view.coords
% - empties co, amp, ph, map
%
% djh, 7/98
% ress, 6/03: added UI controls for 3D buttons

if isempty(view)
  myErrorDlg('Volume window must be open to switch it to volume mode.');
end
if ~strcmp(view.viewType,'Volume') & ~strcmp(view.viewType,'Gray')
  myErrorDlg('Only volume window can be switched to volume mode.');
end

% Set viewType
view.viewType = 'Volume';
view.subdir = 'Volume';

% Compute/load VOLUME.coords
view = getVolCoords(view);

% Empty data matrices
view.co = [];
view.amp = [];
view.ph = [];
view.map = [];

% Only do this for VOLUME, not for hiddenVolume
if findstr(view.name,'VOLUME')
  % Set view.ui.grayVolButtons
  selectButton(view.ui.grayVolButtons,2);
  % Hide the 3D buttons:
%   HideButtons(view.ui.gray3dButtons);
%   view = Disable3D(view);
  % Load user preferences
  view = loadPrefs(view);
end
