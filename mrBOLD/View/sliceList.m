function slices = sliceList(view,scan)
%
% slices = sliceList(view,[scan])
%
% scan: required for inplane views, but not used for volumes/grays/flats.
%
% For inplanes, this returns the slices in the specified functional scan.
% For volumes/grays, this is a hack that returns 1 because the data are stored in a vector.
% For flats, there are effectively 2 anatomy slices, one for each hemisphere.
%
% djh, 2/21/2001

global dataTYPES
%TODO: replace this with dtGet and viewGet
switch view.viewType
    case 'Inplane'
        slices = dataTYPES(view.curDataType).scanParams(scan).slices;
    case {'Volume' 'Gray'}
        slices = 1;
    case 'Flat'
        slices = [1 2];
end

return;
