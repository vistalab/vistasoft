function vw = switch2Vol(vw)
%
% Switches Volume view to volume mode:
% - changes vw.subdir to 'Volume'
% - sets vw.ui.grayVolButtons=2
% - computes/loads vw.coords
% - empties co, amp, ph, map
%
% djh, 7/98
% ress, 6/03: added UI controls for 3D buttons

if isempty(vw)
  myErrorDlg('Volume window must be open to switch it to volume mode.');
end
if ~strcmp(vw.viewType,'Volume') && ~strcmp(vw.viewType,'Gray')
  myErrorDlg('Only volume window can be switched to volume mode.');
end

% Set viewType
vw = viewSet(vw, 'viewType', 'Volume');
vw = viewSet(vw, 'subdir', 'Volume');

% Compute/load VOLUME.coords
vw = getVolCoords(vw);

% Empty data matrices
vw = viewSet(vw, 'co',  []);
vw = viewSet(vw, 'amp',  []);
vw = viewSet(vw, 'ph',  []);
vw = viewSet(vw, 'map',  []);


% Only do this for VOLUME, not for hiddenVolume
if strfind(viewGet(vw, 'name') ,'VOLUME')
  % Set vw.ui.grayVolButtons
  selectButton(vw.ui.grayVolButtons,2);
  % Hide the 3D buttons:
%   HideButtons(vw.ui.gray3dButtons);
%   vw = Disable3D(vw);
  % Load user preferences
  vw = loadPrefs(vw);
end
