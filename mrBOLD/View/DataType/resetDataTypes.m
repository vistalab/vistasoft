function viewList = resetDataTypes(viewList, dataType)
%
%  viewList = resetDataTypes(viewList, dataType)
%
% Author:  Wandell
% Purpose:
%    Loops through the views in viewList, updating the dataType popup to
% reflect the additional scan.
%    The call to selectDataType updates the dataType popup.
%    Broken out of averageTSeries.
%
% ras, 01/06 -- updated the logic: if a view wasn't pointed to 
% dataType (the 2nd input arg), it wouldn't remove an invalid choice
% from the list. Also errored if you removed a data type that
% wasn't the last data type. Really, it needs to update all the
% views in the view list.
% So, now I think it works, but the second arg is no longer needed.
% Kept it in just to prevent errors in code that calls this.
mrGlobals;
N = length(dataTYPES);

for s=1:length(viewList)
    if ~isempty(viewList{s}) 
        if viewList{s}.curDataType > N
            dataType = N;
        else
            dataType = viewList{s}.curDataType;
        end
        
        try
            viewList{s} = selectDataType(viewList{s}, dataType); 
        catch
            % don't sweat it...really, this shouldn't stop anything
        end
    end
end

return