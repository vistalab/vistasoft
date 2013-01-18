function setROIPopup(view,options,choice)
%
% setROIPopup(view,[options],[choice])
%
% Sets the ROI popup menu options and updates the choice.  If options 
% or choice are not provided, they are grabbed from the view structure.
%
% options: cell-aray list of popup menu options
%
% choice: option number that is currently chosen.
% from the popupHandle.
%
% If you change this function make parallel changes in:
% setDataTypePopup
%
% gmb, 4/24/98
%
% djh, modified 10/29/98 to do nothing for hiddenInplane, hiddenVolume
% djh, modified 12-8-98 to fix 'non-empty String' bug

% If no ui field, do nothing
if ~isfield(view,'ui') | strcmp(view.name,'hidden')
    return;
end

if ~exist('options','var')
   if ~isempty(view.ROIs)
    options = {view.ROIs.name};
  else
    options = 'none';
    choice = 1;
  end
end

if ~exist('choice','var')
  choice = view.selectedROI;
end

% Get handles and set their values
popupHandle = view.ui.ROI.popupHandle;
labelHandle = view.ui.ROI.labelHandle;
set(popupHandle,'String',options);
set(popupHandle,'Value',choice);


