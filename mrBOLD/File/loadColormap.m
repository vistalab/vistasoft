function view = loadColormap(view, cmapFile);
%
% view = loadColormap(view, <cmapFile>);
%
% Loads a colormap as the (color/overlay part of the) cmap for the 
% view's current mode. The cmapFile should be a path to a .mat file 
% containing the saved variable 'cmap', as an Nx3 color lookup table.
% A dialog pops up if no cmap file is provided.
%
% Note that this only loads the color parts of the current view, for
% maps and other overlays; the grayscale part is not changed.
%
% This code is also somewhat redundant with (but distinct from)
% cmapExportModeInformation and cmapImportModeInformation. Sorry,
% I hadn't realized those existed when I wrote this (and wrote code
% for which this was useful).
%
% ras, 01/06 
if notDefined('cmapFile')
    [f p] = myUiGetFile(dataDir(view), '*.mat', ...
                        'Pick a file with a saved colormap');
    cmapFile = fullfile(p, f);
end

if ~exist(cmapFile, 'file') | exist([cmapFile '.mat'], 'file')
    error(sprintf('File %s not found.', cmapFile));
end

A = load(cmapFile);

if ~isfield(A, 'cmap') | ~isnumeric(A.cmap)
    error('Cmap file must have a numeric ''cmap'' variable defined.');
end

mode = sprintf('%sMode', view.ui.displayMode);
nG = view.ui.(mode).numGrays;

view.ui.(mode).cmap = [view.ui.(mode).cmap(1:nG,:); A.cmap];
view.ui.(mode).numColors = size(A.cmap, 1);

view = refreshScreen(view);

return
