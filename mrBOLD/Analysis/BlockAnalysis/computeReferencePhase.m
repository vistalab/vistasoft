function refPh = referencePhase(sessions,roiName,viewType,dataType,fileNameSuffix)

% function refPh = referencePhase(sessions,ROIname,[viewType],[dataType],[fileNameSuffix])
%
% Loops through sessions, averaging across scans to compute
% the average response phase. Uses the output of analyzeSessions so
% you have to run that first on the same sessions and ROI.
%
% datadr: top level data directory, e.g., datadr = /usr/local/mri/mrLoadRet2/'
%
% sessions: struct array with subdir and referenceScans fields, e.g.,
%     sessions(1).subdir = '121897';
%     sessions(1).referenceScans = [1:10];
% where the referenceScans field lists all the scans in that session that
% will be included in the calculation of the referencePhase. This
% might include only one scan per session or it might include all of the scans
% to get the grand mean.
%
% roiName: name of the ROI
%
% fileNameSuffix: specifies data file output from analyzeSessions.
% Default is:
%     fileNameSuffix = ''; 
% so that the default filename is: roiName.mat
%
% djh, 2/2/2001

mrGlobals

if ~exist('viewType','var')
    viewType = 'Inplane';
end
if ~exist('dataType','var')
    dataType = 'Original';
end
if ~exist('fileNameSuffix','var')
    fileNameSuffix = '';
end

% Loop through sessions
repeats = [];
for s = 1:length(sessions)
	HOMEDIR = sessions(s).path;
    loadSession(HOMEDIR); %changed from loadsession to loadSession (BZL)
    
    % Open hidden view of the chosen viewType (either 'Inplane' or 'Gray')
    switch viewType
    case 'Inplane'
        view = initHiddenInplane;
    case 'Gray'
        view = initHiddenGray;
    otherwise
        error('analyzeSessions: supports only Inplane and Gray views.');
    end
    
    % Select chosen data type
    view = selectDataType(view,existDataType(dataType));
    
    fileName = [roiName,fileNameSuffix];
    load(fullfile(dataDir(view),'Analysis',fileName));
    % Loop through scans
    for scan=sessions(s).referenceScans
        amp = analysis.amps(scan);
        ph = analysis.phs(scan);
        repeats = [repeats, amp*exp(j*ph)];
    end
end
meanRef = mean(repeats(isfinite(repeats)));
refPh = angle(meanRef);
