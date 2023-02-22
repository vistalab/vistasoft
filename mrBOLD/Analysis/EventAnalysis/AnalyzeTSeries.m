function AnalyzeTSeries(experiments, cothresh, phWindow, fileNameSuffix)
% Michael Silver testing CVS - 7/15/02
%
% AnalyzeTSeries(experiments, [cothresh, phWindow, fileNameSuffix])
%
% Loops through sessions, computing mean time-series for each scan and ROI.
% For each ROI and each session, saves analysis structure in file
% under Analysis subdirectory. 
%
% INPUTS
% experiments: structure describing scanning sessions pertaining to a particular
% type of experiment. It is composed of the following fields:
%
% datadir: main directory containing session subdirectories that pertain to a
%   particular experiment. Usually, this is formed by creating an experimental
%   directory in /usr/local/mri (e.g., /usr/local/mri/mumble) containing symbolic
%   links to actual session data directories scattered about the NFS. Alternatively,
%   it can be a cell vector containing the same number of elements as the sessions
%   field (below). As still another alternative, this can be empty (datadir = ''),
%   and each entry in the sessions field can be a fully qualified directory spec..
%
% sessions: string cell vector containing subdirectory specifications 
%   for each session, e.g.: sessions{1} = '121897'. If datadir is empty,
%   use a fully qualified directory specification, e.g. sessions{1} = 
%   '/maroon/u10/mri/mumble/121897'
%
% ROI: Cell array of ROI struct arrays. If a single ROI struct is specified, it is
% applied to all sessions. If the length of ROIs matches the length of sessions,
% then the separate ROI will be applied to each session. Each struct array provides the
% name, subROIs (e.g., for left/right retinotopies), and reference-scan index 
% appropriate for that ROI.  Example: say ROIs = ROI{1}; then
%   ROIs(1).name = 'V1';
%   ROIs(1).subROIs = ['V1L';'V1R'];
%   ROIs(1).scanList = 2:6;   
%   ROIs(2).name = 'MT';
%   ROIs(2).subROIs = ['MTL';'MTR'];
%   ROIs(2).refScan = 2;
%
% map: force mapping from anatomically defined Gray ROIs to Inplane.
%          Mapping is always done if Inplane ROI isn't present. Defaults to FALSE.
% weight: use residual std. deviations to weight the mean time series. Defaults
%             to FALSE (0).
%
% Other optional input variables --
% cothresh: correlation threshold, defaults to zero
% phWindow: phase window, defaults to [0 2*pi]
% fileNameSuffix: to specify unique filenames (filenames default to ROI.name).
%
% analysis structure has fields:
%   sessiondr:
%   ROIname:
%   subROIs:
%   refScan:
%   cothresh:
%   phWindow:
%   tSeries: cell array containing the mean time series for each
%            scan in a session.
%
% dbr, 12/11/98 Modified from analyzeSessions (djh, 10/30/98).
% huk/den 03/09/01 changed all calls to makeDir to mymkdir

global mrSESSION

if ~exist('fileNameSuffix','var')
  fileNameSuffix = '';
end

if isfield(experiments, 'map')
  mapFlag = experiments.map;
else
  mapFlag = 0;
end

if ~exist('phWindow', 'var'), phWindow = [0 2*pi]; end

if ~exist('cothresh', 'var'), cothresh = 0; end

if isfield(experiments, 'weight')
  weightFlag = experiments.weight;
else
  weightFlag = 0;
end

% Extract session specs:
sessions = experiments.sessions;
if ~iscell(sessions)
  sessions = {sessions};
end
nSessions = length(sessions);

% Extract data-directory spec, and expand to same size as session
% specs if necessary:
datadir = experiments.datadir;
if ~iscell(datadir)
  datadir = {datadir};
end
nDirs = length(datadir);
if nDirs ~= nSessions
  if nDirs == 1
    for iDir = 2:nSessions
      datadir{iDir} = datadir{1};
    end
  else
    myErrorDlg('Length of data-directory field must be unity or same as # of sessions!');
  end
end


ROICells = experiments.ROI;
if ~iscell(ROICells)
  ROICells = {ROICells};
end
nROI = length(ROICells);
if nROI ~= nSessions
  if nROI == 1
    for iROI = 2:nSessions
      ROICells{iROI} = ROICells{1};
    end
  else
    Alert('Length of ROI field must be same as # of sessions!');
    return
  end
end

if isfield(experiments, 'scanList')
  scanLists = experiments.scanList;
  if ~iscell(scanLists), scanLists = {scanLists}; end
end

curDir = pwd;

for s = 1:nSessions
  session = sessions{s};
  disp(['Session: ', session]);
  sessiondr = fullfile(datadir{s}, session);
  
  analDir = fullfile(sessiondr, 'Analysis');
  if ~exist(analDir, 'dir')
    disp('Creating ''Analysis'' subdirectory...');
    mymkdir(sessiondr,'Analysis'); %changed by huk
  end
  load(fullfile(sessiondr, 'mrSESSION.mat'));
  hiddenInplane = initHiddenInplane;
  
  ROIs = ROICells{s};
  nROIs = length(ROIs);
  if ~all(isempty([ROIs.refScan]))
    hiddenInplane = loadCorAnal(hiddenInplane);
  end
  
  % Check if requested ROIs are in Inplane ROI directory.
  subFlag = isfield(ROIs, 'subROIs');
  ROInames = {};
  for iR=1:nROIs
    thisROI = {ROIs(iR).name};
    if subFlag
      if ~isempty(ROIs(iR).subROIs), thisROI = ROIs(iR).subROIs; end
    end
    ROInames = [ROInames, thisROI];
  end
  dS = dir(fullfile(sessiondr, 'Inplane', 'ROIs'));
  inplaneROInames = {dS.name};
  for r=1:nROIs
    present(r) = any(strcmp([ROInames{r}, '.mat'], inplaneROInames));
  end
  if mapFlag | ~all(present)
    % Map this session's ROIs:
    exp1 = experiments;
    exp1.ROI = ROIs;
    exp1.sessions = session;
    MapGrayROIs(exp1);
  end
  
  for r=1:nROIs
    % Load all of the ROIs into the view and restrict as necessary:
    roiName = ROIs(r).name;
    if isfield(ROIs, 'subROIs')
      subROIs = ROIs(r).subROIs;
    else
      subROIs = [];
    end
    
    % Load the ROI, forming it from subROIs if necessary:
    if isempty(subROIs)
      hiddenInplane = loadROI(hiddenInplane, roiName);
    else
      hiddenInplane = loadCombinedROIs(hiddenInplane, subROIs, roiName, 1);
    end
    
    if isfield(ROIs, 'refScan') & (abs(cothresh) > 0 | diff(phWindow) < 2*pi)
      refScan = ROIs(r).refScan;
    else
      refScan = [];
    end
    
    if ~isempty(refScan)
      % Restrict the ROI based on correlation and phase limits:
      hiddenInplane = restrictROI(hiddenInplane, refScan, cothresh, phWindow);
    end
  end
  
  if weightFlag
    % Load the residual standard deviations if we need them:
    hiddenInplane = loadResStdMap(hiddenInplane);
  end
  
  % Extract the mean time series for selected scans using the restricted ROIs:
  if exist('scanLists', 'var')
    scanList = scanLists{s};
  else
    scanList = 1:length(mrSESSION.functionals);
  end
  nScans = length(scanList);
  tSeries = cell(nROIs, mrSESSION.nScans);
  for iS=1:nScans
    sno = scanList(iS);
    disp(['    Scan: ', int2str(sno)]);
    if weightFlag
      tSeries(1:nROIs, sno) = weightedMeanTSeries(hiddenInplane, sno, refScan)';
    else
      tSeries(1:nROIs, sno) = meanTSeries(hiddenInplane, sno)';
    end
  end
  
  subs = isfield(ROIs, 'subROIs');
  refs = isfield(ROIs, 'refScan');
  for r=1:nROIs
    % Organize the results in the analysis structure:
    ROIsize = size(hiddenInplane.ROIs(r).coords, 2);
    analysis.sessiondr = sessiondr;
    analysis.ROIname = ROIs(r).name;
    if subs subROIs = ROIs(r).subROIs; else subROIs = []; end
    analysis.subROIs = subROIs;
    if refs refScan = ROIs(r).refScan; else refScan = []; end
    analysis.refScan = refScan;
    analysis.cothresh = cothresh;
    analysis.phWindow = phWindow;
    analysis.ROIsize = ROIsize;
    analysis.tSeries = tSeries(r, :);
    
    % Save the analysis structure in a file with the same name as the ROI:
    fileName = [ROIs(r).name, fileNameSuffix];
    saveStr = ['save ', fullfile(analDir, fileName), ' analysis'];
    disp(saveStr);
    eval(saveStr); 
  end
end

