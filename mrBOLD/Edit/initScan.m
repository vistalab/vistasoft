function [vw, scanNum, dtNum] = initScan(vw, dataType, scanNum, src)
% Add a scan to an existing dataType or initialize scans in a new dataType
%
%  [vw, scanNum, dtNum] = initScan(<vw>, <dataType>, <scanNum>, <src>);
%
% If the dataType field already exists, the scan is added to that dataType.
% Otherwise, this call creates a new dataType with that name that is passed
% in.
%
% The global dataTYPES are updated and everything is saved to
% mrSESSION.mat.  
% 
% The function copies the scan, blocked analysis, and event analysis
% parameters from the currently-selected scan in the view, unless the
% optional 'src' argument is specified (see below). 
% 
% If the new scan and the source scan have different fields, the updated
% dataTypes will the fields from both the original and the new. The
% unassigned fields to be empty. 
% 
% When the dataType is new and thus creates a new dataType, this function
% creates a directory for the new dataType, but doesn't add any tSeries.
%
% ARGUMENTS:
% vw: mrVista view [defaults to selected inplane].
%
% dataType: name or number of data type to which to add the new scan.
%           [defaults to current data type]
%
% scanNum: # of the new scan to add. If this scan number and data type
%          already exist, will ask the user if he/she wants to copy over
%           it. [defaults to adding an extra scan to the current data
%           type.]
%
% src: optional specification of a source scan from which to copy
%      the data type info (scanParams, blockedAnalysisParams, and 
%      eventAnalysisParams). The format of src should be a 1x2 cell:
%      the first entry can either be a data type number or name (from
%      this session), or else a dataTYPES-style struct (from the dataTYPES
%      variable from another session -- in this case, it should be only a
%      single entry in the dataTYPES struct array; see examples below). 
%      The second entry is a scan number for the source scan. 
%
% EXAMPLES:
%   initScan(INPLANE{end}, 'Averages') will add a new scan at the end
%   of Averages data type, using the currently-selected scan parameters.
%   
%   initScan(INPLANE{end}, 'Test', 1, {'Averages' 3}) will
%   initialize a new data type 'Test', using the parameters from Averages
%   scan 3.
%
%   initScan(INPLANE{end}, 'Imported', 1, {altDataTYPES(1) 4}) will create
%   a new data type 'Imported', copying the results from the data types 
%   specified in altDataTYPES, with data type 1, scan 4.
%
%
% ras, 01/09/2006
% ras, 11/15/2006: returns # of the data type.
% ras, 02/20/2007: updates GUI settings.
% ras, 06/20/2007: actually selects the new data type / scan now.
if notDefined('vw'),      vw = getSelectedInplane;              end
if notDefined('dataType'),  dataType = viewGet(vw, 'curdt');      end
if notDefined('src'),
    src = {viewGet(vw,'curdt') viewGet(vw,'curScan')};
end

mrGlobals; % introduces global dataTYPES variable
%GUI is already part of mrGlobals
%global GUI % Moved from inside if-statement
    
% ensure the data type is specified as a string, and dtNum is
% the corresponding numeric index, of the target data type:
if ischar(dataType)
    dtNum = existDataType(dataType, dataTYPES, 1);
else
	% if dataType isn't a name, it must be the number of the data type.
    dtNum = dataType;
    if dtNum > length(dataTYPES)
        dataType = inputdlg('Enter the name of the new data type:', ...
                       'initScan', 1, {'NewDataType'});
        dataType = dataType{1};
	else
		dataType = dataTYPES(dtNum).name;
	end
end

% Create the data type if it doesn't already exist
if (dtNum==0) || (dtNum > length(dataTYPES))
    fprintf('Creating data type %s\n', dataType);
    mkdir(viewDir(vw), dataType);
    fprintf('Made directory %s\n', fullfile(viewDir(vw), dataType));
    
    %dataTYPES(end+1).name = dataType;
    %dataTYPES(end+1) = dtSet(dataTYPES(end+1), 'Name', dataType);

    %dtNum = length(dataTYPES);
    
    %Create the datatype here
	dtNum = addDataType(dataType);
    
    % also update data type popups: do this for mrVista GUIs
    INPLANE = resetDataTypes(INPLANE, dtNum);
    VOLUME  = resetDataTypes(VOLUME, dtNum);
    FLAT    = resetDataTypes(FLAT, dtNum);
    
    if ~isempty(GUI)    % mrVista session GUI is open
        sessionGUI_selectDataType;
    end        
end
vw = viewSet(vw, 'curDataType', dtNum);

% default scan number -- couldn't put this above the creation of
% a new data type
if notDefined('scanNum')
    scanNum = viewGet(vw, 'numScans',dataType) + 1;    
end
vw = viewSet(vw, 'curScan', scanNum);

%%%%% if multiple scans selected, recursively step through each
if length(scanNum) > 1
    for i=1:length(scanNum)
        vw = initScan(vw, dataType, scanNum(i), src);
    end
    return
end


%%%%%parse the specification of the source data type / scan: 
if ~iscell(src)
    help(mfilename);
    error('Invalid specification for source data type / scan.')
end

if isnumeric(src{1})
    srcDt = dataTYPES(src{1});
elseif ischar(src{1})
    srcDt = dataTYPES(existDataType(src{1}, dataTYPES));
elseif isstruct(src{1})
    srcDt = src{1}(1);
end

srcScan = src{2};

%srcScanParams = srcDt.scanParams(srcScan);
srcScanParams = dtGet(srcDt, 'Scan Params', srcScan); 
%srcBlockParams = srcDt.blockedAnalysisParams(srcScan);
srcBlockParams = dtGet(srcDt, 'Blocked Analysis Params', srcScan);
%srcEventParams = srcDt.eventAnalysisParams(srcScan);
srcEventParams = dtGet(srcDt, 'Event Analysis Params', srcScan);

%Error check no longer necessary with dtGet
%if checkfields(srcDt, 'retinotopyModelParams')
%end

srcRMParams = dtGet(srcDt, 'Retinotopy Model Params', srcScan);

%%%%%copy over params:
% Copy one field at a time, so we don't get type-mismatch errors.    

%TODO: Change the below to using dtSet and dtGet. Most likely, no longer
%need to copy over one parameter at a time, but can copy over an entire
%struct.

% scan params
for f = fieldnames(srcScanParams)'
    dataTYPES(dtNum).scanParams(scanNum).(f{1}) = srcScanParams.(f{1});
end
    
% blocked analysis params
for f = fieldnames(srcBlockParams)'
    dataTYPES(dtNum).blockedAnalysisParams(scanNum).(f{1}) = ...
        srcBlockParams.(f{1});
end

% event analysis params
for f = fieldnames(srcEventParams)'
    dataTYPES(dtNum).eventAnalysisParams(scanNum).(f{1}) = ...
        srcEventParams.(f{1});
end

% retinotopy model params (if any are specified)
if exist('srcRMParams', 'var') && isstruct(srcRMParams)
	for f = fieldnames(srcRMParams)'
		dataTYPES(dtNum).retinotopyModelParams(scanNum).(f{1}) = ...
			srcRMParams.(f{1});
	end
end

%%%%%Update mrSESSION
mrSessPath = fullfile(HOMEDIR, 'mrSESSION.mat');
save(mrSessPath, 'dataTYPES', '-append');
disp('Updated dataTYPES variable in mrSESSION.mat.')

% update popups for any GUIs
INPLANE = resetDataTypes(INPLANE);
VOLUME = resetDataTypes(VOLUME);
FLAT = resetDataTypes(FLAT);

return

    
