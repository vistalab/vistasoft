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
% This function has been deprecated. Please use 'viewGet(vw,'Size')
% instead.

dims = viewGet(vw,'Size');

return
