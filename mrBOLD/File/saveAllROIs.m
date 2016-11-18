function saveAllROIs(view, local, forceSave)
%
% saveAllROIs(view, [local], [forceSave=0])
%
% Saves ROI to a file.
%
% rmk, 1/18/99
% ras, 10/27/06: added local flag, cancel option.
% ras, 11/16/06: fixed bug w/ local directory; added ability to 
%   update forceSave flag if user wants to select 'Yes To All'
%   in saving over existing ROIs. (see saveROI)
if notDefined('local'), local = isequal(view.viewType, 'Inplane'); end
if notDefined('forceSave'), forceSave = 0; end

if view.selectedROI==0
    myErrorDlg('No ROIs to save')
end

for r = 1:length(view.ROIs)
    [view, status, forceSave] = saveROI(view, view.ROIs(r), local, forceSave);
    if status==0        % abort saving
        return
    end
end

return


