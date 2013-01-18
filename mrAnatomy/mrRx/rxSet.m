function rx = rxSet(rx,property,value);
%
% rx = rxSet(rx,property,value);
%
% Set a property of an rx struct, and set
% ui controls appropriately.
%
%
% Current properties are:
%
%  'vol': new prescribed (xformed) volume.
%  'ref': new reference volume
%  'xform': new affine transform matrix.
%  
%  'rxdims': change dimensions (in voxels) of prescription.
%  'rxres','rxvoxelsize': change size of each voxel in mm for Rx.
%
%  'refdims': change dimensions (in voxels) of reference volume.
%  'refres','refvoxelsize': change size of each voxel in mm for ref.
%
%  'voldims': change dimensions (in voxels) of xformed volume.
%  'volres','volvoxelsize': change size of each voxel in mm for vol.
%
%  'targetframe': if a tSeries is loaded, swap in the [value]th
%   frame as the xformed volume.
%
%  'baseframe': if a tSeries is loaded, swap in the [value]th
%   frame as the reference volume.
%
% ras 03/05.
if nargin < 3
    help(mfilename);
    return
end

if isempty(rx)
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

switch lower(property)
    case 'vol', 
        rx.vol = value;
    case 'ref',
        rx.ref = value;
    case 'xform',
        rx = rxSetXform(rx);
    case {'rxdims','rxsize'},
        rx.rxDims = value;
        rx.rxSizeMM = rx.rxDims .* rx.rxVoxelSize;
        checkSliceSliders(rx);
    case {'voldims','volsize'},
        rx.volDims = value;
        rx.volSizeMM = rx.volDims .* rx.volVoxelSize;
    case {'refdims','refsize'},
        rx.refDims = value;
        rx.refSizeMM = rx.refDims .* rx.refVoxelSize;
    case {'rxres','rxvoxelsize'},
        rx.rxVoxelSize = value;
        rx.rxSizeMM = rx.rxDims .* rx.rxVoxelSize;
    case {'volres','volvoxelsize'},
        rx.volVoxelSize = value;
        rx.volSizeMM = rx.volDims .* rx.volVoxelSize;
    case {'refres','refvoxelsize'},
        rx.refVoxelSize = value;
        rx.refSizeMM = rx.refDims .* rx.refVoxelSize;
    case {'targetframe','tseriestarget'},
        if ~isfield(rx,'tSeries') | isempty(rx.tSeries) | size(rx.tSeries,4) < value
            return
        end
        rx = rxSet(rx,'vol',double(rx.tSeries(:,:,:,value)));
        return
    case {'baseframe','tseriesbase'},
        if ~isfield(rx,'tSeries') | isempty(rx.tSeries) | size(rx.tSeries,4) < value
            return
        end
        rx = rxSet(rx,'ref',double(rx.tSeries(:,:,:,value)));
        return
end

if ishandle(rx.ui.controlFig)
    checkSliceSliders(rx);   
    set(rx.ui.controlFig,'UserData',rx);
end

rxRefresh(rx);

return
% /-------------------------------------------/ %
       



% /-------------------------------------------/ %
function checkSliceSliders(rx);
% Check that the ui slice sliders are consistent
% with the sizes of the different volumes.
if ishandle(rx.ui.rxSlice.sliderHandle)
    nSlices = get(rx.ui.rxSlice.sliderHandle,'Max');
    if nSlices > rx.rxDims(3)
        curval = get(rx.ui.rxSlice.sliderHandle,'Value')
        if curval > nSlices
            rxSetSlider(rx.ui.rxSlice.sliderHandle,nSlices);
        end
        set(rx.ui.rxSlice.sliderHandle,'Max',rx.rxDims(3));

    end
end

if isfield(rx.ui,'volSlice') & ishandle(rx.ui.volSlice.sliderHandle)
    nSlices = get(rx.ui.volSlice.sliderHandle,'Max');
    if nSlices > rx.volDims(3)
        curval = get(rx.ui.volSlice.sliderHandle,'Value')
        if curval > nSlices
            rxSetSlider(rx.ui.volSlice.sliderHandle,nSlices);
        end
        set(rx.ui.volSlice.sliderHandle,'Max',rx.volDims(3));
    end
end


return
