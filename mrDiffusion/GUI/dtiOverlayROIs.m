function img = dtiOverlayROIs(img,curpos,roi,cmap,dim)
% Overlay roi onto an image slice
%
%   img = dtiOverlayROIs(img,curpos,roi,cmap,dim)
%
% Used in dtiRefreshFigure to place the ROIs ontop of the background image
% for the main figure window.
%
%  img:  An image slice for some dimension
%  curpos:  The current position selected in the window
%  roi:     The coordinates of the region of interest
%  cmap:    The rgb alpha color map for the overlay
%  dim:     'x', 'y', or 'z' for the image dimension
%
% See also: dtiRefreshFigure, dtiGetCurslices
%
% Brian (c) Stanford VISTASOFT Team, 2012

sz = size(img);

switch lower(dim(1))
    case 'x'
        curSl = (roi(:,1)==curpos(1));
        inds = sub2ind(sz(1:2),roi(curSl,2),roi(curSl,3));
    case 'y'
        curSl = (roi(:,2)==curpos(2));
        inds = sub2ind(sz(1:2),roi(curSl,1),roi(curSl,3));
    case 'z'
        curSl = (roi(:,3)==curpos(3));
        inds = sub2ind(sz(1:2),roi(curSl,2),roi(curSl,1));
    otherwise
        error('Improper dimension: %s\n',dim)
end

% Someone should explain this.  Sigh.
img(inds) = img(inds)*(1-cmap(4))+ cmap(1)*cmap(4);
inds = inds + sz(1)*sz(2);
img(inds) = img(inds)*(1-cmap(4))+ cmap(2)*cmap(4);
inds = inds + sz(1)*sz(2);
img(inds) = img(inds)*(1-cmap(4))+ cmap(3)*cmap(4);

end

