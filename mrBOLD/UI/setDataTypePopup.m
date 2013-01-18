function setDataTypePopup(view,options,choice)
%
% setDataTypePopup(view,[options],[choice])
%
% Sets the dataType popup menu options and updates the choice.  If options 
% or choice are not provided, they are grabbed from mrSESSION & from the view structure.
%
% options: cell-aray list of popup menu options (dataTypeNames)
%
% choice: option number that is currently chosen.
%
% If you change this function make parallel changes in:
% setROIPopup
%
% djh, 2/21/2001, modified from setROIPopup
global dataTYPES

% If no ui field, do nothing
if ~isfield(view,'ui'),      return;                            end

if notDefined('options'),    options = {dataTYPES.name};        end
if notDefined('choice'),     choice = view.curDataType;         end

% Get handles and set their values
popupHandle = view.ui.dataType.popupHandle;
labelHandle = view.ui.dataType.labelHandle;
set(popupHandle, 'String', options, 'Value', choice);

return;
