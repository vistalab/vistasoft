function vw = loadColormap(vw, cmapFile)
%
% vw = loadColormap(vw, <cmapFile>);
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
    [f, p] = myUiGetFile(dataDir(vw), '*.mat', ...
                        'Pick a file with a saved colormap');
    cmapFile = fullfile(p, f);
end

if ~exist(cmapFile, 'file') || exist([cmapFile '.mat'], 'file')
    error('File %s not found.', cmapFile);
end

A = load(cmapFile);

if ~isfield(A, 'cmap') || ~isnumeric(A.cmap)
    error('Cmap file must have a numeric ''cmap'' variable defined.');
end

mode = sprintf('%sMode', vw.ui.displayMode);
nG = vw.ui.(mode).numGrays;

vw.ui.(mode).cmap = [vw.ui.(mode).cmap(1:nG,:); A.cmap];
vw.ui.(mode).numColors = size(A.cmap, 1);

vw = refreshScreen(vw);

return
