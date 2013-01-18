function averageTSeriesAcrossSessions(avgTypeName);
%function averageTSeriesAcrossSessions([avgTypeName]);
%
% This function is stand-alone but can be called from Gray's Analysis/Average menu.
% Purpose: Average scans across different sessions into a new datatype.
%
% To do this, you first select dir to save the new averaged scans. If you
% call this function from Gray's menu, it will simply save to a new dataType
% in the Gray. Then, you select sessions that you wish to average together,
% then define how you want to average the scans together with button box.
% The computer will then work to make a gray window with the desired averages.
%
% When finished, notice dataTYPES(avgType).sessionNotes for name codes.
%
% 2004.02.14 Junjie: Ask me for more details!

if (~exist('avgTypeName','var') | isempty(avgTypeName)), avgTypeName='Avg-XSess'; end

%select Session to save the averaged data
avgSession = uigetdir(pwd,['Select the dir to save averages across sessions. ',...
        'Please either select an empty dir or a dir with valid Gray view']);
if isempty(avgSession)|avgSession==0; return; end;
if ~isempty(dir(fullfile(avgSession,'mrSESSION.mat'))) & isempty(dir(fullfile(avgSession,'Gray','coords.mat')));
    errordlg(char({'You selected a dir with mrSESSION but no valid Gray view';...
            'Please either select a dir with no mrSESSION so that we copy mrSESSION in';...
            'or select a dir aligned with vaild Gray/coords.mat'}));return;
end
avgstr = {'Averages across sessions will be in the';['dataType ''',avgTypeName,''' in Gray view of dir'];['''',avgSession,'''']};
confirm = strcmp(questdlg(char(avgstr),'Confirm','OK','Cancel','OK'),'OK');
if ~confirm; return; end;

%select session to average together, and detect if Gray is built in each session.
%We detect Gray/coords.mat files -- hope this is the best way.
selectedSessions = uigetmanydirs(fullfile('Gray','coords.mat'));
nSessions = length(selectedSessions);

%ask if average over Originals
manualDataType = strcmp(questdlg('Use Original as dataType for all sessions?','Original?','Yes','No, I decide','Yes'),'No, I decide');
%ask which scans shall be selected
useDataTYPE = ones(1,nSessions);% default use original datatype

%load through sessions for each scan's name. To avoid conflicting with
%current mrSESSION in the view, load it into tmp.
ABCs = {'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'};
for iSession = 1:nSessions;
    try
        tmp = load(fullfile(selectedSessions{iSession},'mrSESSION.mat'));
    catch
        error(['mrSESSION.mat not existent in dir ',selectedSessions{iSession}]);
    end
    if ~isfield(tmp.mrSESSION,'mrLoadRetVersion');
        error(['Please do convert2to3 for ',selectedSessions{iSession}]);
    end
    if manualDataType %ask preferred dataType for each session
        s = listdlg('PromptString','Select a dataTYPE:',...
            'SelectionMode','single','CancelString','Ok',...
            'ListString',{tmp.dataTYPES.name});
        if isempty(s),s=1;end;
        useDataTYPE(iSession) = s;
    end
    options(iSession).str = {tmp.dataTYPES(useDataTYPE(iSession)).scanParams.annotation}';
    % now, I should use mrSESSION.sessionCode as description of each
    % session. However this is not updated with dir name, so I decide to
    % use the dir name instead.
    options(iSession).title = [ABCs{iSession},'=',...
            selectedSessions{iSession}(max(findstr(selectedSessions{iSession},filesep))+1:end)];
end

%If Gray/coords.mat not exist in avgSession, copy it and mrSESSION from the first scan session.
if isempty(dir(fullfile(avgSession,'Gray','coords.mat')));
    [success,message]=copyfile(fullfile(selectedSessions{1},'mrSESSION.mat'),fullfile(avgSession,'mrSESSION.mat'));
    if ~success; error(message);end;
    warning off MATLAB:MKDIR:DirectoryExists;[success,message]=mkdir(avgSession,'Gray');warning on MATLAB:MKDIR:DirectoryExists;
    if ~success; error(message);end;
    [success,message]=copyfile(fullfile(selectedSessions{1},'Gray','coords.mat'),fullfile(avgSession,'Gray','coords.mat'));
    if ~success; error(message);end;
end

%Now, let's define how we average.
selectAverage = 1; nAvgScans = 0; clear avgRawScans;
while selectAverage
    selected = buttonMatrixDlg(['Select scans for Average # ',int2str(nAvgScans+1)],options);
    if isempty(selected);
        selectAverage = 0;
    else
        nAvgScans = nAvgScans + 1;
        avgRawScans(nAvgScans,:) = selected;
        % avgRawScans is a matrix of cells -- yes, very complicated.
    end
end
if nAvgScans == 0;
    error('No average across scans is ordered. Quit.');
end

%Initialize average.
chdir(avgSession);
avg_h = initHiddenGray;%hidden View
templateCoords = avg_h.coords;
mrGlobals; % must make them global at this point.
loadSession;
if ~existDataType(avgTypeName), addDataType(avgTypeName); end
avg_h = selectDataType(avg_h,existDataType(avgTypeName));
ndataType = avg_h.curDataType;
dataTYPES(ndataType).sessionNotes = {options.title}';% a new field
avg.mrSESSION = mrSESSION;
avg.dataTYPES = dataTYPES; % make a copy to edit it.
% Get the tSeries directory for this dataType (make the directory if it doesn't already exist).
avgTSeriesDir = fullfile(avgSession,'Gray',avgTypeName,'TSeries');
%set vANATOMYPATH only once, here, since we do not average across subjects
vANATOMYPATH = getvAnatomyPath(mrSESSION.subject);

% Now start averaging
for iAvgScan = 1:nAvgScans
    clear avgTSeries commonNFrames; % clear only at start of each loop.
    scanNotes = [];
    for iSession = 1:nSessions;
        selectedScans = find(avgRawScans{iAvgScan,iSession});
        if ~isempty(selectedScans);%loop into one session only if selected
            HOMEDIR=selectedSessions{iSession}; chdir(HOMEDIR);
            mrGlobals;
            loadSession;
            ip = openInplaneWindow;
            gr = openGrayWindow;
            selectDataType(INPLANE{ip},useDataTYPE(iSession));
            selectDataType(VOLUME{gr},useDataTYPE(iSession));
            % Now find the common gray coordinates and indices of not-belongs
            % use setdiff because coords are redundant, have repeated elements.
            belongInds = find(ismember(templateCoords',VOLUME{gr}.coords','rows'));
            commonCoords = templateCoords(:,belongInds);
            notBelongInds = setdiff(1:size(templateCoords,2),belongInds);
            
            % The following is copied from ip2volTSeries.m, but we now take
            % only tSeries for wanted coords.
            vol2InplaneXform = inv(mrSESSION.alignment);
            vol2InplaneXform = vol2InplaneXform(1:3,:);
            coordsXformedTmp = vol2InplaneXform*[commonCoords;ones(1,size(commonCoords,2))];
            coordsXformed = coordsXformedTmp;
            for curScan = selectedScans(:)';
                % Check that all scans in scanList have the same numFrames
                if ~exist('commonNFrames','var');
                    commonNFrames = numFrames(VOLUME{gr},curScan);
                elseif commonNFrames ~= numFrames(VOLUME{gr},curScan);
                    error('Scans you choose to average together must have same number of frames.');
                end
                
                % Scale and round the coords
                coordsXformed(1:2,:)=coordsXformedTmp(1:2,:)/upSampleFactor(INPLANE{ip},curScan);
                coordsXformed=round(coordsXformed);
                
                % Set tseries as zero at start. Then always fill it with NaN for voxels that
                % are out of gray in any session, thus data comes only from common coords.
                if ~exist('avgTSeries','var'),
                    avgTSeries = zeros(commonNFrames,size(templateCoords,2));
                end
                
                % Loop through slices, loading the inplane tSeries and transforming it.
                for curSlice = sliceList(INPLANE{ip},curScan);
                    inplaneTSeries = loadtSeries(INPLANE{ip},curScan,curSlice);
                    grayIndices = find(coordsXformed(3,:)==curSlice);
                    if ~isempty(grayIndices)
                        ipIndices = sub2ind(sliceDims(INPLANE{ip},curScan),...
                            coordsXformed(1,grayIndices),coordsXformed(2,grayIndices));
                        tplateInds = belongInds(grayIndices); % indices in templateCoords
                        avgTSeries(:,tplateInds) = inplaneTSeries(:,ipIndices)+avgTSeries(:,tplateInds);
                    end
                end
                scanNotes = [scanNotes,ABCs{iSession},int2str(curScan),', '];
            end
            avgTSeries(:,notBelongInds) = NaN;
            lastSESSION = iSession; % last session that looped through (not all sessions are looped through).
            clear INPLANE VOLUME; close all;
        end% end of loop in one session
    end
    %The parameters are supposed to be the same for all averaged scans, so just copy from last dataType
    avg.dataTYPES(ndataType).scanParams(iAvgScan) = dataTYPES(useDataTYPE(lastSESSION)).scanParams(curScan);
    avg.dataTYPES(ndataType).blockedAnalysisParams(iAvgScan) = dataTYPES(useDataTYPE(lastSESSION)).blockedAnalysisParams(curScan);
    avg.dataTYPES(ndataType).eventAnalysisParams(iAvgScan) = dataTYPES(useDataTYPE(lastSESSION)).eventAnalysisParams(curScan);
    avg.dataTYPES(ndataType).scanParams(iAvgScan).annotation = ['Average# ',int2str(iAvgScan),' of Scans ',scanNotes];
    % Make the Scan subdirectory for the new tSeries (if it doesn't exist)
    scandir = fullfile(avgTSeriesDir,['Scan',num2str(iAvgScan)]);
    if ~exist(scandir,'dir');
        [p f] = fileparts(scandir);
        mkdir(p,f);
    end
    saveStr = fullfile(avgTSeriesDir,['Scan',num2str(iAvgScan)],'tSeries1.mat');
    tSeries = avgTSeries; save(saveStr,'tSeries');
end    
dataTYPES = avg.dataTYPES; mrSESSION = avg.mrSESSION;
chdir(avgSession);
save(fullfile(avgSession,'mrSESSION.mat'),'mrSESSION','dataTYPES');

% At the end, open the Gray window with the dataType
clx;
disp('Open with mrVista(''Gray'')');
mrGlobals;
mrVista('Gray');
VOLUME{1}.curDataType = length(dataTYPES);
setDataTypePopup(VOLUME{1});
VOLUME{1}=selectDataType(VOLUME{1},VOLUME{1}.curDataType);
VOLUME{1}=refreshScreen(VOLUME{1});
disp('Averages finished. Hint: you can Save Preferences');
return
