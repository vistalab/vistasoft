function analyzeSessions(sessions,ROIs,viewType,dataType,fileNameSuffix)
%
% analyzeSessions(sessions,ROIs,[viewType],[dataType],[fileNameSuffix])
%
% Loops through sessions, computing vector means for each ROI.
% For each ROI and each session, saves analysis structure in file
% under Analysis subdirectory. 
%
% sessions: struct array with fields path and referenceScans, e.g.,
%     sessions(1).path = 'x:\retinotopy\djh\121897';
%     sessions(1).referenceScans = [1:10];
% The path takes you all the way to the directory that contains the
% corAnal.mat file.
% The referenceScans field is not used by this function, but it is used
% by computeReferencePhase.m
%
% ROIs: cell array of roiNames
%   ROIs{1} = 'V1';
%   ROIs{2} = 'V1r7';
%   ROIs{3} = 'MT';
% The ROIs must already be restricted by whatever procedure you desire.
%
% viewType: either 'Inplane' or 'Gray' (default: 'Inplane')
%
% dataType: optional for specifying data type (default: 'Original')
%
% fileNameSuffix: to specify unique filenames (filenames default
% to roiName.mat
%
% analysis structure has fields:
%   session: copy of the sessions structure
%   ROI: copy of the ROI structure
%   ROIsize: number of voxels
%   amps: mean amplitude for each scan in session
%   phs: mean phase for each scan in session
%
% djh, 10/30/98
% djh, 2/5/2001,
%   - No longer restricts by the reference scans (you need to do that yourself)
%   - Changed format of the output analysis structure
% djh, 3/6/2001, updated to mrLoadRet-3.0

mrGlobals;

if ~exist('viewType','var')
    viewType = 'Inplane';
end
if ~exist('dataType','var')
    dataType = 'Original';
end
if ~exist('fileNameSuffix','var')
  fileNameSuffix = '';
end

for s = 1:length(sessions)
    
    % Change to session directory and load mrSESSION
    HOMEDIR = sessions(s).path;
    disp(['session: ',HOMEDIR]);
    loadSession(HOMEDIR);
    
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
    
    % Creates the Analysis subdirectory if it does not exist.
    if ~exist(fullfile(dataDir(view),'Analysis'),'dir')
        mkdir(dataDir(view),'Analysis');
    end
   
    % Load corAnal
    view = loadCorAnal(view);
    
    for r = 1:length(ROIs) 
        
        % load ROI
        roiName = ROIs{r};
        view = loadROI(view,roiName,1);
        ROIsize = size(view.ROIs(r).coords,2);
        
        % compute vector means
        [meanAmps,meanPhs] = vectorMeans(view);
        %[meanCos,meanAmps] = meanCos(view);
        
        analysis.session = sessions(s);
        analysis.ROI = ROIs(r);
        analysis.ROIsize = ROIsize;
        %analysis.cos = meanCos;
        analysis.amps = meanAmps;
        analysis.phs = meanPhs;
        
        fileName = [roiName,fileNameSuffix];
        pathStr = fullfile(dataDir(view),'Analysis',fileName);
        save(pathStr,'analysis');
    end
end
