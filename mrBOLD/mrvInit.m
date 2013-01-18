function mrvInit(varargin)
% Initialize functional data and inplane anatomicals for mrVista
%
%    mrvInit(varargin)
%
% This function replaces mrInitRet.  
%
% mrvInit can be run in batch mode with function arguments.  If there are
% no arguments, then the user is presented with a menu of options (GUI).
%
% At present, mrvInit starts with reconstructed P*.mag files and
% corresponding inplane-anatomy images. The directories are initialized,
% the time series are derived, and so forth.   Possible initialization
% steps are 
%
%  - Set up proper directory structure
%  - create anatomy file for inplanes
%  - crop data (inplanes and functionals)
%  - Store parameters used for data analysis (dataTYPES, mrSESSION)
%  - create Readme
%  - extract time series from mag files
%    - Remove drift
%    - Calculate percent
%  - compute block time series analysis (coherence analysis)
%
% Processing information is stored in the structure mrSESSION and dataTYPES
% variables.
%
% Example:
%   mrvInit('session',1,'tseries',1);
%   mrvInit('session',0,'tseries',1);
%
%   tmp = dir('Raw\Pfiles\P*.mag'); 
%   for ii=1:length(tmp), pFiles{ii} = tmp(ii).name; end
%   mrvInit('pFileNames',pFiles,'session',0,'tseries',1);
%
%   pFiles = {'P19456.7.mag'};
%   mrvInit('pFileNames',pFiles,'session',0,'tseries',1);
%
%   mrvInit('session',0,'tseries',1,'pFileNames',pFiles);

error('Deprecated. Use mrInit.');

mrGlobals

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Opening dialogs

if isempty(varargin)
    initOptions = {'Setup Raw/ Directory',...
        'Resize inplane images',...
        'Crop inplane images',...
        'Create/edit data structures',...
        'Extract time series',...
        'Perform blocked analysis'};

    initReply = buttondlg('mrInitRet', initOptions);
    if isempty(find(initReply, 1)), return; end
    doRawDir  = initReply(1);
    doResize  = initReply(2);
    doCrop    = initReply(3);
    doSession = initReply(4);
    doTSeries = initReply(5);
    doCorrel  = initReply(6);
else
    for ii=1:2:length(varargin)
        switch lower(varargin{ii})
            case 'directory'
                HOMEDIR = varargin{ii+1};
                ask = 0;
            case 'raw'
                doRawDir = varargin{ii+1};
            case 'resize'
                doResize = varargin{ii+1};
            case 'crop'
                doCrop = varargin{ii+1};
            case 'session'
                doSession = varargin{ii+1};
            case 'tseries'
                doTSeries = varargin{ii+1};
            case 'coherence'
                doCorrel = varargin{ii+1};
            case 'pfilenames'
                pFileNames = varargin{ii+1};
            case 'glm'
                error('Not yet implemented')
            otherwise
        end
    end
end

% Default actions
if notDefined('doRawDir'),   doRawDir = 0; end
if notDefined('doResize'),   doResize = 0; end
if notDefined('doCrop'),     doCrop = 0; end
if notDefined('doSession'),  doSession = 1; end
if notDefined('doTSeries'),  doTSeries = 1; end
if notDefined('doCorrel'),   doCorrel = 0; end
if notDefined('ask'),        ask = 1; end
if notDefined('pFileNames'), pFileNames = []; end

% Determine and possibly create the relevant directories
dirS = GetDirectory(HOMEDIR,ask);
rawDir  = dirS.raw;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up the Raw/ subdirectory if selected
if doRawDir==1, SetupRawDir; end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the inplane anatomies and the Pfile header info

% Get the scan params from the Pfile headers
scanParams = GetScanParams(rawDir);

% Load the inplane-anatomy images and initialize the inplanes structure
[anat, inplanes] = InitAnatomy(HOMEDIR, rawDir, doCrop);
if isempty(anat), disp('Aborted'), return;
else              disp('Created anatomy file');
end

if doResize, [anat, inplanes] = ReduceFOV(anat, inplanes); end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do crop

% At this point we should have a valid inplane anatomy, and the
% doCrop flag indicates if it can and should be cropped
if doCrop
    % Sometimes inplanes.FOV is not an integer...
    if inplanes.FOV ~= round(inplanes.FOV);
        disp(['Original inplane FOV was ',num2str(inplanes.FOV),' mm, now rounded to ',int2str(round(inplanes.FOV)),' mm.']);
        inplanes.FOV = round(inplanes.FOV);
    end


    % Calculate the cropRatio from inplanes.fullSize and functionals(:).fullSize
    cropRatio = 1;
    for scan = 1:length(scanParams)
        cropRatio = max([cropRatio, inplanes.fullSize ./ scanParams(scan).fullSize]);
    end

    % Crop the inplane anatomy if requested or not previously done:
    [anat, inplanes] = CropInplanes(rawDir, anat, inplanes, cropRatio);
    if isempty(anat), disp('Crop inplanes aborted'); return;
    else disp('Cropping complete');
    end

    % Delete tSeries (if there are any); they are out of date because the crop has changed
    datadir = fullfile(HOMEDIR,'Inplane','Original','TSeries');
    [nscans,scanDirList] = countDirs(fullfile(datadir,'Scan*'));
    if nscans > 0
        deleteFlag = questdlg('The existing tSeries are out of date because the crop has changed. Delete existing TSeries?',...
            'Delete tSeries','Yes','No','Yes');
        if strcmp(deleteFlag,'Yes')
            for s=1:nscans
                delete(fullfile(datadir,scanDirList{s},'*.mat'));
            end
        end
    end

else
    %%%%% crop not selected; use full size of anats/functionals

    % set inplane crop params
    if ~isfield(inplanes,'crop') || isempty(inplanes.crop)
        % Set to full size of anats
        anatSzX = size(anat,1);
        anatSzY = size(anat,2);
        inplanes.crop = [1 1; anatSzX anatSzY];
        inplanes.cropSize = [anatSzX anatSzY];
    end

    % set functional crop params
    if ~isfield(scanParams(1),'cropSize') || isempty(scanParams(1).cropSize)
        for i = 1:length(scanParams)
            scanParams(i).crop = [1 1; scanParams(i).fullSize];
            scanParams(i).cropSize = [scanParams(i).fullSize];
        end
    end
end

% Save anat
anatFile = fullfile(HOMEDIR, 'Inplane', 'anat.mat');
save(anatFile, 'anat', 'inplanes');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create/load mrSESSION and dataTYPES, modify them, and save

% If mrSESSION already exists, load it.
sessionFile = fullfile(HOMEDIR, 'mrSESSION.mat');
if exist(sessionFile, 'file')
    loadSession;
    % if docrop, make sure that the mrSESSION is up-to-date
    if doCrop
        mrSESSION.inplanes = inplanes;
        mrSESSION = UpdateSessionFunctionals(mrSESSION,scanParams);
        saveSession;
    end
end

if doSession
    % If we don't yet have a session structure, make a new one.
    if isempty(mrSESSION)
        mrSESSION = CreateNewSession(HOMEDIR, inplanes, mrLoadRetVERSION);
    end

    % Update mrSESSION.functionals with scanParams corresponding to any new Pfiles.
    % Set mrSESSION.functionals(:).crop & cropSize fields
    mrSESSION = UpdateSessionFunctionals(mrSESSION,scanParams);

    % Dialog for editing mrSESSION params:
    [mrSESSION,ok] = EditSession(mrSESSION);
    if ~ok
        disp('Canceled');
        return
    end

    % Create/edit dataTYPES
    % There should be a group of functions for managing the dataTYPES
    % variable.
    if isempty(dataTYPES) %#ok<NODEF>
        dataTYPES = CreateNewDataTypes(mrSESSION);
    else
        dataTYPES = UpdateDataTypes(dataTYPES,mrSESSION);
    end
    dataTYPES(1) = EditDataType(dataTYPES(1));

    % Save any changes that may have been made to mrSESSION & dataTYPES
    saveSession;

    % Create Readme.txt file
    %     mrCreateReadme;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extract time series and calcaulate coherence analysis

% Create time series files
if doTSeries
    endian    = LittleEndianCheck(mrSESSION);
    
    % Determine which scans have the named pFiles
    pFileList = sessionGet(mrSESSION,'pFileList',pFileNames);
    pFileList = GetRecon(rawDir, pFileList, 0, [], endian);

    % We adjust mrSESSION here based on which pFiles were used.
    functionals = sessionGet(mrSESSION,'functionals');
    functionals = functionals(pFileList);
    mrSESSION   = sessionSet(mrSESSION,'functionals',functionals);

    % We also need to synchronize dataTYPES with mrSESSION.  In this case,
    % we need to remove several of the fields.
    scanParams = dataTYPES.scanParams;
    scanParams = scanParams(pFileList);
    dataTYPES.scanParams = scanParams;
    
    blockedAnalysisParams = dataTYPES.blockedAnalysisParams;
    blockedAnalysisParams = blockedAnalysisParams(pFileList);
    dataTYPES.blockedAnalysisParams = blockedAnalysisParams;
    
    eventAnalysisParams = dataTYPES.eventAnalysisParams;
    eventAnalysisParams = eventAnalysisParams(pFileList);
    dataTYPES.eventAnalysisParams = eventAnalysisParams;
    
    UpdateDataTypes(dataTYPES,mrSESSION);

    saveSession;

    % ras 04/2006: check for .zits files, which report outlier frames:
    zitFiles = dir(fullfile(rawDir, 'Pfiles', '*.zits'));
    if ~isempty(zitFiles), disp('Warning:  zitFiles are present'); end

end

% Perform coherence analysis
if doCorrel
    computeCorAnal(initHiddenInplane, 0, 1);
    computeMeanMap(initHiddenInplane, 0, 1);
end

return
