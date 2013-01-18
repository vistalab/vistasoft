function view = switch2Gray(view)
%
% Switches Volume view to gray mode:
% - changes view.subdir to 'Gray'
% - sets view.ui.grayVolButtons=2
% - computes/loads view.coords
% - loads user preferences
% - empties co, amp, ph, map
%
% djh, 7/98
% ress, 6/03: Added 3D button UI controls

if isempty(view)
    myErrorDlg('Volume window must be open to switch it to gray mode.');
end
if ~strcmp(view.viewType,'Volume') & ~strcmp(view.viewType,'Gray')
    myErrorDlg('Only volume window can be switched to gray mode.');
end

% set viewType
view = viewSet(view,'viewType','Gray');
view = viewSet(view,'subdir','Gray');

% Compute/load VOLUME.coords
view = getGrayCoords(view);

% Empty data matrices already set in openRaw...
% view.co = [];
% view.amp = [];
% view.ph = [];
% view.map = [];

% Only do this for VOLUME, not for hiddenVolume
if findstr(view.name, 'VOLUME')
    if checkfields(view, 'ui', 'grayVolButtons')
          % Set view.ui.grayVolButtons
          selectButton(view.ui.grayVolButtons, 1);
    end
end

return;
