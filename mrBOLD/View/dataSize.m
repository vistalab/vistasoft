function dims = dataSize(vw,scan)
%
% dims = dataSize(vw,[scan])
% 
% Returns the size of the data arrays, i.e., size of co for
% a single scan.
%
% scan: required for inplane views, but not used for volumes/grays/flats
%
% For INPLANE, returns [cropTSeriesSize,nSlices]
% For VOLUME/GRAY, returns size(view.coords)
% For FLAT, returns [imageSize,2]
%
% djh, 2/22/2001
if notDefined('vw'),    vw   = getCurView;              end
if notDefined('scan'),  scan = viewGet(vw, 'curScan');  end

switch vw.viewType
    case 'Inplane'
        dims = [viewGet(vw, 'sliceDims', scan) viewGet(vw, 'number of slices')];
    case {'Volume','Gray'}
        dims = [1 size(vw.coords,2)];
    case 'Flat'
        dims = [vw.ui.imSize,numSlices(vw)];
end
return
