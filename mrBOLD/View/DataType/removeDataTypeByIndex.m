function removeDataType(dataTypeIndex);
%
% removeDataType(dataTypeIndex);
% 
% Removes a dataType (by index) from mrSESSION and updates open views appropriately.
% This routine depends on dataTYPES being a global variable.
%
% See also: removeDataType
%
% djh, 3/2001
% dar, 3/2007: cleaned up, now it does what it promises.
%% Initial Checks
mrGlobals
if strcmp(dataTYPES(dataTypeIndex).name,'Original') | dataTypeIndex == 1
    error('removeDataTypeByIndex: Cannot remove original dataType.');
    return;
end
%% Main
% If the dataType exists, (1) remove it from mrSESSION, (2) remove it from the
% popup menu options, (3) adjust the value of the curDataType
% and (4) check whether or not to delete the corresponding subdirectories
if dataTypeIndex <= length(dataTYPES)
    % Adjust the mrSESSION structure
    dataTypeName = dataTYPES(dataTypeIndex).name
    fprintf('removeDataTypeByIndex: removing dataType(%i): %s \n',dataTypeIndex, dataTypeName);
    dataTYPES(dataTypeIndex) = [];
    saveSession(1);
    
    % Delete all the data files for this dataType
    cleanDataType(dataTypeName,1);
    % Loop through the open views, switch their curDataType appropriately, 
    % and update the dataType popups
    INPLANE = resetDataTypes(INPLANE,dataTypeIndex);
    VOLUME = resetDataTypes(VOLUME,dataTypeIndex);
    FLAT = resetDataTypes(FLAT,dataTypeIndex);
else
    fprintf('removeDataTypeByIndex: dataType(%i): %s not found.\n',dataTypeIndex, dataTypeName);
end
return;
