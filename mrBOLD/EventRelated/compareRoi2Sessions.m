function [dataA, dataB] = compareRoi2Sessions(roiName,params);
%
% [dataA, dataB] = compareRoi2Sessions(roiName,[params]);
%
% Compare time series data from an ROI from two sessions (A and B),
% returning tSeries data for both sessions in which each 
% column corresponds to the same location in the volume. 
%
% Saves the results in a file in the first session's
% session directory. The default name for such a file
% is '[roiName]_[sessA]_[sessB].mat'. Also saves
% voxel data for each ROI in each session's Volume
% directory.
%
%
%
%
% ras 06/05.
if ieNotDefined('roiName')
    % choose from dialog    
    mrGlobals
    if isempty('vANATOMYPATH')
        if exist('mrSESSION.mat','file')
            load mrSESSION
            vANATOMYPATH = getVAnatomyPath(mrSESSION.subject);
        else
            error('Need to either specify an ROI name, or load a session!')
        end
    end
    roiPath = fullfile(fileparts(vANATOMYPATH),'GrayROIs');
    w = what(roiPath); 
    roiList = w.mat;
    for i = 1:length(roiList)
        roiList{i} = roiList{i}(1:end-4);
    end
    [sel, ok] = listdlg('PromptString','Select ROIs',...
        'ListSize',[400 600],'SelectionMode','multiple',...
        'ListString',roiList,'InitialValue',1,'OKString','OK');
    if ~ok  return;  end
    
    roiName = roiList(sel);
end

if ieNotDefined('params')
    params = twoSessDialog;
end   

% get arguments from params struct
sessA = params.sessA;
sessB = params.sessB;
dtA = params.dtA;
dtB = params.dtB;
scansA = params.scansA;
scansB = params.scansB;

if iscell(roiName) & length(roiName)>1 
    % allow for many ROIs to be run, recursively:
    % but will only return the last one
    for i = 1:length(roiName) 
        [dataA, dataB] = compareRoi2Sessions(roiName{i},params);
    end
    return
end

% record curr val of global variables for later
mrGlobals
if ~isempty('mrSESSION')
	callingDir = pwd;
	callingSess = mrSESSION;
	callingDt = dataTYPES;
	if exist('vANATOMYPATH','var')
        callingVAnatPath = vANATOMYPATH;
	else
        callingVAnatPath = '';
	end
    restoreCallingPath = 1;
else
    restoreCallingPath = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% init session A
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cd(sessA);
mrGlobals;
HOMEDIR = pwd;
loadSession;

% check for alignment field
if ~checkfields(mrSESSION,'alignment') 
    error('Session A doesn''t have an alignment!')
end

hI = initHiddenInplane;
hI = selectDataType(hI,dtA);
hI = setCurScan(hI,scansA);

hV = initHiddenVolume;
hV = selectDataType(hV,dtA);
hV = setCurScan(hV,scansA);

hV = loadROI(hV,roiName);

dataA = ip2VolVoxelData(hI,hV,hV.ROIs);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% init session B
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cd(sessB);
mrGlobals;
HOMEDIR = pwd;
loadSession;

% check for alignment field
if ~checkfields(mrSESSION,'alignment') 
    error('Session B doesn''t have an alignment!')
end

hI = initHiddenInplane;
hI = selectDataType(hI,dtB);
hI = setCurScan(hI,scansB);

hV = initHiddenVolume;
hV = selectDataType(hV,dtB);
hV = setCurScan(hV,scansB);

hV = loadROI(hV,roiName);

dataB = ip2VolVoxelData(hI,hV,hV.ROIs);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now the main part: set the tSeries and coords  %
% fields of dataB to match dataA                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% restore calling values of global variables
if restoreCallingPath==1
    HOMEDIR = callingDir;
	mrSESSION = callingSess;
	dataTYPES = callingDt;
	vANATOMYPATH = callingVAnatPath;
end

return
% /----------------------------------------------------------------/ %


function params = twoSessDialog;
% put up a dialog and get info on
% selecting two scans, data types from
% each scans, and scan groups from each
% scan.

% get sessions
sessA = uigetdir(pwd,'Select a first session...');
sessB = uigetdir(pwd,'Select a second session...');

% load/test for mrSESSION files
load(fullfile(sessA,'mrSESSION.mat'))
sessInfo{1} = dataTYPES;
load(fullfile(sessB,'mrSESSION.mat'))
sessInfo{2} = dataTYPES;

% make a confirmation dialog as we go (fancy...)
inpt(1).fieldName = 'sessA'; % this is just for feedback to the user
inpt(1).style = 'text';
inpt(1).string = 'Session A:';
inpt(1).value = sessA;

inpt(2).fieldName = 'sessB';
inpt(2).style = 'text';
inpt(2).string = 'Session B:';
inpt(2).value = sessB;

inpt(3).fieldName = 'dtA';
inpt(3).style = 'popup';
inpt(3).string = 'Session A Data Type:';
inpt(3).list = {sessInfo{1}.name};
inpt(3).value = 2;

inpt(4).fieldName = 'dtB';
inpt(4).style = 'popup';
inpt(4).string = 'Session B Data Type:';
inpt(4).list = {sessInfo{2}.name}
inpt(4).value = 2;

% get dataTypes
params = generalDialog(inpt,'Compare ROI, 2 Sessions',[.15 .4 .7 .4]);

% find numeric index for each data type
dtNumA = cellfind(inpt(3).list,params.dtA);
dtNumB = cellfind(inpt(4).list,params.dtB);

% get scans
inpt(3).style = 'text'; % set as feedback for user
inpt(3).value = params.dtA;
inpt(4).style = 'text';
inpt(4).value = params.dtB;

inpt(5).fieldName = 'scansA';
inpt(5).style = 'popup';
inpt(5).string = 'Choose a Scan in Scan Group A:';
inpt(5).list = {sessInfo{1}(dtNumA).scanParams.annotation};
inpt(5).value = 2;

inpt(6).fieldName = 'scansB';
inpt(6).style = 'popup';
inpt(6).string = 'Choose a Scan in Scan Group B:';
inpt(6).list = {sessInfo{2}(dtNumB).scanParams.annotation};
inpt(6).value = 2;
params = generalDialog(inpt,'Compare ROI, 2 Sessions',[.15 .2 .7 .6]);

% format nicely
params.scansA = str2num(params.scansA);
params.scansB = str2num(params.scansB);

return