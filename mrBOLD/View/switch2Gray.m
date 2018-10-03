function vw = switch2Gray(vw)
%
% Switches Volume view to gray mode:
% - changes vw.subdir to 'Gray'
% - sets vw.ui.grayVolButtons=2
% - computes/loads vw.coords
% - loads user preferences
% - empties co, amp, ph, map
%
% djh, 7/98
% ress, 6/03: Added 3D button UI controls

if isempty(vw)
    myErrorDlg('Volume window must be open to switch it to gray mode.');
end

vwType = viewGet(vw, 'view type');

if ~strcmp(vwType,'Volume') && ~strcmp(vwType,'Gray')
    myErrorDlg('Only volume window can be switched to gray mode.');
end

% set viewType
vw = viewSet(vw,'view type','Gray');
vw = viewSet(vw,'subdir','Gray');

% Compute/load VOLUME.coords
vw = getGrayCoords(vw);

% Empty data matrices already set in openRaw...
% vw.co = [];
% vw.amp = [];
% vw.ph = [];
% vw.map = [];

% Only do this for VOLUME, not for hiddenVolume
if strcmp(vwType, 'VOLUME')
    if checkfields(vw, 'ui', 'grayVolButtons')
          % Set vw.ui.grayVolButtons
          selectButton(vw.ui.grayVolButtons, 1);
    end
end

return;
