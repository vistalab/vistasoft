function view = annotation43View(view);
%
% function view = annotation43View(view);
% 
% Same as makeAnnotationString, but for the volume
% 3-view window. 
%
% djh, 3/2001
% ras, 3/2003

annotationPos = [0.10 0.30 0.5 0.10];
annotationAxis = subplot('position',annotationPos);
axis off;
text(0,0,'','FontSize',12);
annotationHandle = get(annotationAxis,'Children');
view.ui.annotationHandle = annotationHandle;

% Return the current axes to the main image
% set(gcf,'CurrentAxes',view.ui.mainAxisHandle);

return