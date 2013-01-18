function [m, e, t] = PlotMultipleMeanLaminarProfiles(view)

% PlotMultipleMeanLaminarProfiles(view);
%
% Ress, 6/04

mrGlobals

% Get the list of scans in the present view:
nScans = length(dataTYPES(view.curDataType).scanParams);

% Get the volume anatomy & dimensions
if isempty(view.anat)
  view = loadAnat(view);
end

% Calculate the laminar profiles of mean T2* magnitude:
m = cell(1, nScans);
e = cell(1, nScans);
t = cell(1, nScans);
for ii=1:nScans
  [m{ii}, e{ii}, t{ii}] = MeanLaminarProfile(mean(view.mmPerVox), ii);
end

% Plot the profiles with appropriate labels
labels = {dataTYPES(view.curDataType).scanParams.annotation};
rLabel = view.ROIs(view.selectedROI).name;
PlotLaminarProfiles(t, m, e, labels, rLabel);