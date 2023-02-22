function copyScan(sessionDir,dataType,scan)
%
% function copyScan(sessionDir,dataType,scan)
%
% Copy a scan from a different session.
% Creates dataType 'Copied' if it doesn't already exist.
% 
% sessionDir: path string to the other session
% dataType, scan: specifies where to find the tSeries within that session
% 
% Output is a new set of tSeries files in a new Scan subdirectory
% under the Copied dataType directory.
%
% djh, 2/28/2001

mrGlobals

% Make sure dataType 'Copied' exists
if ~existDataType('Copied')
    addDataType('Copied');
end

% Open hidden gray
hiddenView = initHiddenGray;
hiddenView = selectDataType(hiddenView,existDataType('Copied'));

% update dataTYPES.scanParams with the new scan, 
% copying scanParams, blockedAnalysisParams, & eventAnalysisParams
% from the other session.
newScanNum = numScans(hiddenView)+1;
ndataType = hiddenView.curDataType;
% load dataTYPES from other session
s = load(fullfile(sessionDir,'mrSESSION.mat'));
% get scanParams, blockedAnalysisParams, & eventAnalysisParams from other session
ndataTypeOtherSession = existDataType(dataType,s.dataTYPES);
scanParams = s.dataTYPES(ndataTypeOtherSession).scanParams(scan);
% blast slices & cropSize because inplane view of new scan is bogus
scanParams.slices = [];
scanParams.cropSize = [];
blockedAnalysisParams = s.dataTYPES(ndataTypeOtherSession).blockedAnalysisParams(scan);
eventAnalysisParams = s.dataTYPES(ndataTypeOtherSession).eventAnalysisParams(scan);
dataTYPES(ndataType).scanParams(newScanNum) = scanParams;
dataTYPES(ndataType).blockedAnalysisParams(newScanNum) = blockedAnalysisParams;
dataTYPES(ndataType).eventAnalysisParams(newScanNum) = eventAnalysisParams;
dataTYPES(ndataType).scanParams(newScanNum).annotation = ['Copied from ',sessionDir,', dataType: ',dataType,', scan: ',num2str(scan)];

% Load gray coords from other session.
% Compute intersection of their coords with my gray coords.
grayCoordsFile = fullfile(sessionDir,'Gray','coords.mat');
s = load(grayCoordsFile);
[c,ia,ib] = intersectCols(hiddenView.coords,s.coords);
% Load the tSeries from the other session 
tSeriesPath = fullfile(sessionDir,'Gray',dataType,'TSeries',['Scan',num2str(scan)],'tSeries1.mat');
s = load(tSeriesPath);

tSeries = NaN*ones([size(s.tSeries,1) size(hiddenView.coords,2)]);
tSeries(:,ia) = s.tSeries(:,ib);
%This should be able to be used the same as before as the gray view has not
%yet been updated
savetSeries(tSeries,hiddenView,newScanNum,1);
saveSession

% Loop through the open views, switch their curDataType appropriately, 
% and update the dataType popups
INPLANE = resetDataTypes(INPLANE,ndataType);
VOLUME = resetDataTypes(VOLUME,ndataType);
FLAT = resetDataTypes(FLAT,ndataType);

return;

function viewList=resetDataTypes(viewList,ndataType)
% Loops through the views, updating the dataType to reflect the additional scan.
% The call to selectDataType updates the dataType popup.
for s=1:length(viewList)
    if ~isempty(viewList{s}) 
        if viewList{s}.curDataType == ndataType
            viewList{s} = selectDataType(viewList{s},1); 
            viewList{s} = selectDataType(viewList{s},ndataType); 
        end
    end
end
return

% Debug/test

clear all; close all;
sessionDirs = {'e:/mri/test','j:/djhRetinotopy/030701a'};
newSession = 'e:/mri/foo';
mergeSessions(sessionDirs,newSession);
chdir(newSession)
mrLoadRet
copyScan(sessionDirs{1},'Original',1);
copyScan(sessionDirs{1},'Original',2);
copyScan(sessionDirs{2},'Averages',1);
copyScan(sessionDirs{2},'Averages',2);
