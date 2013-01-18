function view = createBlobROI(view);
% Grow an ROI covering a 3D 'Blob' of contiguous activation on a 
% mrVista view's current map.
%
%  view = createBlobROI(view);
%
% ras, 02/19/06.
view = newROI(view);
view = addROIgrow(view);

return
