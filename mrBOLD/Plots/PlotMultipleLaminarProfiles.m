function [m, e, t] = PlotMultipleLaminarProfiles(ss)

% PlotMultipleLaminarProfiles(scanList);
%
% Ress, 6/04

mrGlobals

% Get view:
selectedVOLUME = viewSelected('Volume');
if ~isfield(VOLUME{selectedVOLUME}, 'mmPerVox'), VOLUME{selectedVOLUME} = loadAnat(VOLUME{selectedVOLUME}); end
view = VOLUME{selectedVOLUME};

% Get the list of scans in the present view:
if ~exist('ss', 'var'), ss = chooseScans(view); end

% Calculate the laminar profiles
[m, e, t] = ROIlaminarProfile(ss);
if isempty(m)
  % Something went wrong, so quit:
  return
end
m = m(ss);
e = e(ss);
t = t(ss);
if isempty(m), return, end

% Plot the profiles with appropriate labels
labels = {dataTYPES(view.curDataType).scanParams.annotation};
labels = labels(ss);
rLabel = view.ROIs(view.selectedROI).name;
PlotLaminarProfiles(t, m, e, labels, rLabel);

return