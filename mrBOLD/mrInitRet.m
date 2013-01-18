% mrInitRet (Script)
%
% Initialize data for mrVista
%
% Starts with reconstructed P*.mag files and corresponding inplane-anatomy
% images.  This script orchestrates the processing for various purposes.
% The directories are initialized, the time series are derived, and so
% forth.   These steps include
%
% - Set up directory structure
% - create inplane anatomy files 
% - crop data (inplanes and functionals)
% - Store parameters used for data analysis (dataTYPES, mrSESSION)
% - extract time series from mag files
%    - Remove drift
%    - Calculate percent
% - compute block time series analysis (coherence)
%
% The information about the processing is stored in the structure mrSESSION
% and dataTYPES.
%

% Programming Notes:
%
% DBR, 3/99  Rewritten based on an earlier version by GB, and
%    much hacked subsequently.
% Ress, 2/06  Added code to resize inplane images, which was anonymously
%   removed. Please DO NOT remove this code without contacting me!
% Rory, 02/06 Yeah, that was me -- sorry. But it said "ask Junjie" and
%    Junjie wasn't around. And it was never made clear what it was supposed to
%    be, or if it was just a brutal hack. Having a button definitely helps,
%    instead of having the same dialog each time.


error('Use mrInit, not this file.')

clear all
mrGlobals

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Opening dialogs

initOptions = {'Setup Raw/ Directory',...
    'Resize inplane images',...
    'Crop inplane images',...
    'Create/edit data structures',...
    'Extract time series',...
    'Perform blocked analysis'};

defaultOptions = [0 0 1 1 1 0];

initReply = buttondlg('mrInitRet', initOptions,defaultOptions);
if isempty(find(initReply, 1)), return; end

doRawDir  = initReply(1);
doResize  = initReply(2);
doCrop    = initReply(3);
doSession = initReply(4);
doTSeries = initReply(5);
doCorrel  = initReply(6);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up the Raw/ subdirectory if selected
if doRawDir==1, SetupRawDir; end

% Get a valid set of mrl directories
dirS = GetDirectory(pwd);
if isempty(dirS), disp('Aborted'); return;
else              disp('Directories created');
end

% The global HOMEDIR is set
HOMEDIR = dirS.home;
rawDir  = dirS.raw;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the inplane anatomies and the Pfile header info

% Get the scan params from the Pfile headers
scanParams = GetScanParams(rawDir);

% Load the inplane-anatomy images and initialize the inplanes structure
[anat, inplanes] = InitAnatomy(HOMEDIR, rawDir, doCrop);
if isempty(anat), disp('Aborted'), return;
else              disp('Created anatomy file');
end


if doResize, 
    fovRatio = input('Field of View ratio? ( [functional FOV, inplane FOV]) ');
    [anat, inplanes] = ReduceFOV(anat, inplanes, fovRatio); 
end

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
        disp('Aborted');
        return
    end

    % Create/edit dataTYPES
    % There should be a group of functions for managing the dataTYPES
    % variable.
    if isempty(dataTYPES), dataTYPES = CreateNewDataTypes(mrSESSION);
    else                   dataTYPES = UpdateDataTypes(dataTYPES,mrSESSION);
    end
    dataTYPES(1) = EditDataType(dataTYPES(1));

    % Save changes made to mrSESSION & dataTYPES
    saveSession;

    % Create Readme.txt file - We used to try to automate this
    %     mrCreateReadme;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extract time series and calcaulate coherence analysis

% Create time series files
if doTSeries
    endian    = LittleEndianCheck(mrSESSION);
    pFileList = GetRecon(rawDir, 0, 0, [], endian);

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
    
    dataTYPES = UpdateDataTypes(dataTYPES,mrSESSION);

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Clean up global variables.
clear all

return
