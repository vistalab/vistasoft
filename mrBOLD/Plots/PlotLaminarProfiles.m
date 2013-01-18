function [m, e, t] = PlotLaminarProfiles(t, amps, errs, annotation, ROIlabel)

% PlotLaminarProfiles(positions, amplitudes, errors, annotation)
%
% Create a single plot containing line graphs for several laminar profiles.
% Inputs must all be cell vectors of the same dimensions. Each plot will
% have a different symbol, but all will be done in black with a solid line.
% If annotation is specified as a cell vector of strings, a legend is created.
%
% Ress, 6/04

if ~iscell(t), t = {t}; end
if ~iscell(amps), amps = {amps}; end
if ~iscell(errs), errs = {errs}; end

ss = 'osdv^<>phx*+';
cc = 'rgbcmkrgbcymk';
figure; hold on
name = 'Laminar profiles';
if exist('ROIlabel', 'var'), name = [name, ': ', ROIlabel]; end
title(name);
ylabel('Amplitude (arb units)');
xlabel('Distance from gray-white interface (mm)');
nPlots = length(t);
face = 0;
for ii=1:nPlots
  if face == 0
    face = 1;
    mFace = 'none';
  else
    face = 0;
    mFace = 'k';
  end
  s = [cc(ii) ss(ii) '-'];
  plot(t{ii}, amps{ii}, s, ...
    'MarkerSize', 8, ...
    'LineWidth', 1.5, ...
    'MarkerFaceColor', mFace);
end

if exist('annotation', 'var')
  if ~isempty(annotation), legend(annotation); end
end

for ii=1:nPlots
  errorbar(t{ii}, amps{ii}, errs{ii}, 'k-');
end
