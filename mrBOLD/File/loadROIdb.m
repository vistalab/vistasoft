function view = loadROIdb(view,ROIid,select,clr)
%
% view = loadROIdb(view,ROIid,[select],[color])
%
% Loads ROI from a database, adds it to the ROIs field of view, and
% selects it.
%
% ROIid: integer (id of selected ROI in the database)
% select: if non-zero, chooses the new ROI as the selectedROI
%         (default=1).
% color: sets color for drawing the ROI.  If unspecified, uses
%        the color saved in the ROI file.  If no color is saved
%        in the ROI file, uses 'b' as the default.
%
% djh, 1/24/98 
% rmk, 1/12/99 changed to accomodate loading multiple ROIs at once
% dbr, 1/13/99 allow single string spec for ROI name.
% dbr, 10/3/00 Use absolute path specification.
% ars, 7/1/03 adoptation for a database service

if(ROIid==0) % Stupid way to process [Cancel] button if it was pressed instead of ROI selection
  return;
end

if ~exist('select','var')
  select=1;
end

OpenDbConnection(view);
ROI = mysql(['SELECT ROIdata from rois WHERE id="',num2str(ROIid),'"']);
ROI = deserialize(ROI{1});
mysql('close');

if(~isfield(ROI,'viewType'))
  ROI.viewType = view.viewType;
end

if exist('clr','var')
  ROI.color=clr;
else
  if(~isfield(ROI,'color'))
    ROI.color='b';
  end
end

view = addROI(view,ROI,select);
return;