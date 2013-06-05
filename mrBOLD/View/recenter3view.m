function vw = recenter3view(vw,orientation)
% view = recenter3view(view,orientation);
%
% recenters a 3-view window based on the current location of the 
% mouse pointer with respect to the anatomy windows. This is set
% as a button-down callback function with respect to each anatomy view:
% so when the user presses at a particular location in a 3-view window,
% it will pick that location and redraw the 3-view centered there. (If the
% pointer happens to be outside the window or there is no 3-view window
% open, this function exits quietly).
% 
% orientation is an integer from 1-3 that specifies which view
% the user has clicked on. 
%       1 -- view is axial
%       2 -- view is coronal
%       3 -- view is sagittal
%
% See also: volume3view.m
%
% 3/06/03 by ras
% 01/04 ras: (chagrin) turns out the whole 1st half of this code, which was
% a convoluted way of figuring out where the user pressed, is completely
% superfluous if you just use the axes' 'CurrentPoint' property.

% % check if window exists
% winTag = ['3VolumeWindow: ',view.name];
% winExists = findobj('Tag',winTag);
% 
% % if window doesn't exist, exit quietly
% if isempty(winExists)
%     return;
% end

pts = get(gca,'CurrentPoint');
locX = round(pts(1,1));
locY = round(pts(1,2));

% figure out R/L, A/P, S/I coordinates, based on view
switch orientation
    case 1, % axial view
        locRL = locX;
        locAP = locY;        
        locSI = vw.loc(1);
    case 2, % coronal view
        locRL = locX;
        locAP = vw.loc(2);        
        locSI = locY;
    case 3, % sagittal view
        locRL = vw.loc(3);
        locAP = locX;       
        locSI = locY;
end

% might have imgs L/R flipped into radiological conventions
if (orientation<3) && isfield(vw.ui,'flipLR') && vw.ui.flipLR==1
    locRL = size(vw.anat,3) - locRL + 1;
end

% make the selected orientation the current one
setCurSliceOri(vw,orientation);

% mark the current location
loc = [locSI locAP locRL];

% if we're zoomed in, update the zoom bounds so that the crosshairs are
% centered:
maxZoom = [1 1 1; viewGet(vw,'Size')]';
if ~isequal(vw.ui.zoom, maxZoom)
	rng = diff(vw.ui.zoom, 1, 2) ./ 2;
	newZoom = [loc(:)-rng loc(:)+rng];
	
	vw.ui.zoom = newZoom;
end

% refresh volume 3-view
vw = volume3View(vw, loc);

return


