function vw = cmapSetLumColorPhaseMap(vw, hemi)
% luminance-modulated phase colormap
%
% vw = cmapSetLumColorPhaseMap(vw, hemi)
%
% This function reads in the cmap 'WedgeMapLeft_pRF' or 'WedgeMapRight_pRF'
% and multiplies it pointwise by a luminance harmonic (2 cycles around the
% circle). The moulation in (approximately) luminance makes the color bands
% more perceptually distinguishable.
%
% hemi is the hemisphere (not the hemifield). So hemi = 'r' will mask out
% values in the left visual field (near the horizontal meridian) and 'l'
% will make out values in the right visual field.
%
% Examples: 
%   vw = cmapSetLumColorPhaseMap(vw, 'r');
%   vw = cmapSetLumColorPhaseMap(vw, 'l');
%
% JW May,2012

% TODO: A more generic version of this function would read in any arbitrary
% cmap (perhaps whatever is currently loaded in the GUI) and scale it,
% perhaps making the number of luminace cycles and the phase of luminance
% modulation free parameters. On the other hand, color maps are more art
% than science, and the details matter: this particular map works well for
% me (JW) in helping me see reversals that are approximately equally
% salient in both dorsal (lower field) and ventral upper field) maps.


if notDefined('vw'),    vw = getCurView; end
if notDefined('hemi'),  hemi = inputdlg('Which hemisphere (r/l)?'); end
if iscell(hemi),        hemi = hemi{1}; end

switch lower(hemi(1))
    case 'l', cmap = 'WedgeMapLeft_pRF.mat';
    case 'r', cmap = 'WedgeMapRight_pRF.mat';        
end

vw = setPhWindow(vw, [0 2*pi]);
vw = cmapImportModeInformation(vw, 'phMode', cmap);


cmap    = viewGet(vw, 'cmap');
ngrays  = viewGet(vw, 'n grays');
ncols   = viewGet(vw, 'n colors');

cols    = cmap(ncols+(1:ngrays),:);
amp     = .25;
grays   = (1-amp)+(amp*sin(pi/2+linspace(0,4*pi, ncols)));
cmap2   = bsxfun(@times, cols, grays');

vw = viewSet(vw, 'cmap', cmap2);

end

% %% debug
% vw = refreshScreen(vw,0);
% vw = meshUpdateAll(vw);
% updateGlobal(vw);
% 
% figure(99) ; clf
% plot(grays, 'Color', [.7 .7 .7], 'LineWidth', 3); hold on
% plot(bsxfun(@plus, cmap(ngrays+(1:ncols),:),[1 2.1 3.2]), '-', 'LineWidth', 1)
% plot(bsxfun(@plus, cmap2,[1 2.2 3.2]), '-o', 'LineWidth', 2)
% 
