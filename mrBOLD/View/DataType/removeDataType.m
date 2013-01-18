function removeDataType(dataTypeName, queryFlag);
%
%     removeDataType(dataTypeName,[queryFlag=1]);
% 
% Remove a dataType from mrSESSION and updates open views appropriately.
% This routine depends on dataTYPES being a global variable.
%
% See also: removeDataTypeByIndex
%
% djh, 3/2001
% dar, 3/2007 - added queryflag (default = 1) to pass to saveSession &
% cleanSession - default loads a dialoge asking if you want to overwrite /
% delete.
mrGlobals
if strcmp(dataTypeName,'Original')
    error('removeDataType: Cannot remove original dataType.\n');
end
if ~exist('queryFlag','var')
    queryFlag=1;
end
dataTypeNum = existDataType(dataTypeName);

% if query flag is 1, ask the user: and DON'T DELETE THE DATA
% TYPE if the user says 'no'.
if queryFlag==1
	q = sprintf('Completely delete data type %s?', dataTypeName);
    confirm = questdlg(q, mfilename);
	if ~isequal(confirm, 'Yes')
		fprintf('[%s]: Aborted removal.', mfilename);
		return
	end
end

% If the dataType exists, (1) remove it from mrSESSION, (2) remove it from the
% popup menu options, (3) adjust the value of the curDataType
% and (4) check whether or not to delete the corresponding subdirectories
if dataTypeNum
    % Adjust the mrSESSION structure
    fprintf('removeDataType: removing %s dataType\n',dataTypeName);
    other = setdiff(1:length(dataTYPES),dataTypeNum);
    dataTYPES = dataTYPES(other);
    
    saveSession;

    if dataTypeNum > 1 % should always happen, except unusual circumstances
        dataTypeNum = dataTypeNum - 1;
    end
    
    % Delete all the data files for this dataType
    cleanDataType(dataTypeName, 0);
    
    % Loop through the open views, switch their curDataType appropriately, 
    % and update the dataType popups
    INPLANE = resetDataTypes(INPLANE, dataTypeNum);
    VOLUME = resetDataTypes(VOLUME, dataTypeNum);
    FLAT = resetDataTypes(FLAT, dataTypeNum);
	
	% ras 02/07: check if a mrVista2 session is open (this shouldn't
	% break anything if the toolbox is not installed)
	global GUI;
	if ~isempty(GUI), try, sessionGUI_selectDataType(dataTypeNum); end; end
else
    fprintf('removeDataType: %s dataType not found.\n',dataTypeName);
end
return;
