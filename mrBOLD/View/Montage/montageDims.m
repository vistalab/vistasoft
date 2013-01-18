function [selectedSlices, nrows, ncols] = montageDims(vw);
%
% [selectedSlices, nrows, ncols] = montageDims(vw);
%
% Return the dimensions of a montage view (for inplanes, flat
% levels). selectedSlices is a vector of the slices currently
% being displayed in the montage, nrows and ncols are the rows
% and columns in the image. Takes into account an optional
% 'columnMajor' setting, so montages can run across rows 
% or columns (though the interface to set this isn't written
% yet).
% 
% ras, 05/05
viewType = viewGet(vw,'viewType');
ui = viewGet(vw,'ui');
switch viewType
    case 'Inplane',
        firstSlice = viewGet(vw, 'curSlice');
        nSlices = get(ui.montageSize.sliderHandle,'Value');
        selectedSlices = firstSlice:firstSlice+nSlices-1;
    case 'Flat',
        selectedSlices = getFlatLevelSlices(vw);    
        nSlices = length(selectedSlices);
    otherwise,
        error('drawROIsMontage: no support for this vw type.');
end

selectedSlices = selectedSlices(selectedSlices <= viewGet(vw, 'numSlices'));
nSlices = length(selectedSlices);

if isfield(vw.ui,'settings') && isfield(vw.ui.settings,'columnMajor') ...
    && vw.ui.settings.columnMajor==1
    % montage is column-major
	ncols = ceil(sqrt(nSlices));
	nrows = ceil(nSlices/ncols);
else
    % montage is row-major
	nrows = ceil(sqrt(length(selectedSlices)));
	ncols = ceil(nSlices/nrows);
end

return
