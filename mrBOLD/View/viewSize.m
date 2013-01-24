function dims = viewSize(vw)
%Returns the full size of the view.
% 
% dims = viewSize(vw)
%
% Used to transform coordinates from one viewType to another.
%
% For INPLANE, returns     [cropInplaneSize,nSlices]
% For VOLUME/GRAY, returns [volSize] (loaded from vAnatomy header)
% For FLAT, returns        [imageSize,2]
%

global mrSESSION;
% global vANATOMYPATH; - 

switch viewGet(vw,'viewType')
    case 'Inplane'
    dims = viewGet(vw,'dim');
case {'Volume','Gray','generalGray'}
    if isfield(vw, 'anat')
        if ~isempty(vw.anat), dims = size(vw.anat); end
    end
    if ~exist('dims','var')
        pth = getVAnatomyPath; % assigns it if it's not set
        [mmPerPix, dims] = readVolAnatHeader(pth);
    end
case 'Flat'
    dims = [vw.ui.imSize,2];
case 'SS'
    dims = [mrSESSION.inplanes.cropSize];
end

return
