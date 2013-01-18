function mask = inplaneOverlayMask(view, img, hImg);
%
% mask = inplaneOverlayMask(view, img, <hImg>);
%
% Compute a binary mask indicating which pixels in the current
% overlay image for a view exceed the thresholds set by the UI.
%
% img is a data matrix containing the overlay data.
%
% hImg is an optional handle to an overlay image. If this is passed,
% will update the image's Alpha map such that the pixels exceeding
% threshold are opaque and everything else is transparent.
%
% ras, 05/2006.
if nargin<1, view = getCurView; end

if ~exist('img', 'var') | isempty(img), 
    if checkfields(view, 'ui', 'image')
        img = view.ui.image;
    else
        error('Need an overlay data argument (img).')
    end
end

% Select pixels that satisfy cothresh, phWindow, and mapWindow
cothresh = getCothresh(view);
phWindow = getPhWindow(view);
mapWindow = getMapWindow(view);
    
pts = [];
% if ~isempty(img)
%     pts = ones(size(img));
%     curCo = cropCurSlice(view,'co',slice);
%     curPh = cropCurSlice(view,'ph',slice);
%     curMap = cropCurSlice(view,'map',slice);
% 
%     if ~isempty(curCo) & cothresh>0
%         ptsCo = curCo > cothresh;
%         pts = pts & ptsCo;
%     end
% 
%     if ~isempty(curPh)
%         if diff(phWindow) > 0
%             ptsPh = (curPh>=phWindow(1) & curPh<=phWindow(2));
%         else
%             ptsPh = (curPh>=phWindow(1) | curPh<=phWindow(2));
%         end
%         pts = pts & ptsPh;
%     end
% 
%     if ~isempty(curMap)
%         ptsMap = (curMap>=mapWindow(1) & curMap<=mapWindow(2));
%         pts = pts & ptsMap;
%     end
% end

switch view.ui.displayMode
    case 'anat', mask = logical(zeros(size(img)));
    case 'map',
        mask = (img >= mapWindow(1)) & (img <= mapWindow(2));
    case 'amp',
        % tough ...
        mask = (img >= mapWindow(1)) & (img <= mapWindow(2));
    case 'ph',
        mask = (img >= mapWindow(1)) & (img <= mapWindow(2));
    case 'co',
        mask = (img >= mapWindow(1)) & (img <= mapWindow(2));
end

return
