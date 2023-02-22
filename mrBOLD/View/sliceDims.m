function dims = sliceDims(vw,scan)
%
% dims = sliceDims(vw,[scan])
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
    scan =  viewGet(vw, 'curScan');
end

warning('vistasoft:obsoleteFunction', 'sliceDims.m is obsolete.\nUsing\n\tdims = viewGet(vw, ''sliceDims'', scan)\ninstead.');

dims = viewGet(vw, 'sliceDims', scan);

return


% global dataTYPES;
% switch vw.viewType
% case 'Inplane'
%     dims = [dataTYPES(vw.curDataType).scanParams(scan).cropSize];
% case {'Volume','Gray'}
%     dims = [1,size(vw.coords,2)];
% case 'Flat'
%     dims = [vw.ui.imSize];
% end
% return
