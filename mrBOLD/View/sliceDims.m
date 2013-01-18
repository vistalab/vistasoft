function dims = sliceDims(view,scan)
%
% dims = sliceDims(view,[scan])
%
% Returns the size for a single slice of the data array
% i.e., corresponding to a single tSeries file.
%
% scan: required for inplane views, but not used for volumes/grays/flats
%
% For INPLANE, returns [cropTSeriesSize]
% For FLAT, returns [imageSize]
%
% djh, 2/22/2001
if ieNotDefined('scan')
    scan = getCurScan(view);
end

warning('vistasoft:obsoleteFunction', 'sliceDims.m is obsolete.\nUsing\n\tdims = viewGet(vw, ''sliceDims'', scan)\ninstead.');

dims = viewGet(view, 'sliceDims', scan);

return


% global dataTYPES;
% switch view.viewType
% case 'Inplane'
%     dims = [dataTYPES(view.curDataType).scanParams(scan).cropSize];
% case {'Volume','Gray'}
%     dims = [1,size(view.coords,2)];
% case 'Flat'
%     dims = [view.ui.imSize];
% end
% return
