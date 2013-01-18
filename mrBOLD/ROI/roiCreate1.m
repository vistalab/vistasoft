function roi = roiCreate1;
% Return an empty ROI structure. Named 'roiCreate1'to contrast with the
% mrVista2 version of this, 'roiCreate', which has an expanded definition.
%
% ras, 02/2007
roi.name = 'Empty ROI';
roi.coords = [];
roi.color = 'b';
roi.viewType = '';
roi.comments = '';
roi.created = datestr(now);
roi.modified = datestr(now);

roi = sortFields(roi);

return

