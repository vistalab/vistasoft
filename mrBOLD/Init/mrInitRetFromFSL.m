function status=mrInitRetFromFSL(foundScans,SessionName,subjectName)
%   status=mrInitRetFromFSL(foundScans,SessionName,subjectName)
%   creates a MLR session out of a mixture of Dicom and analyze files
%   this mixture is the result of the prepareUCSF script that preprocesses
%   the functional data from the UCSF scanner, but leaves the inplanes
%   as Dicom.
%   2006.04.20 Mark Schira (mark@ski.org) wrote it.
 
mrGlobals
HOMEDIREC = pwd;
status=1;
doCrop=0;

!rm mrSESSION.mat
trashstr=evalc('!rm -r -v ./Inplane/*');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the inplane anatomies 
% We can read the volume siye from the header. Maybe other info as well.
% The inplane data should be in the dataPath named anat.hdr/img


% find the InplaneDir
for thisScan=1:length(foundScans)
    if strcmp(foundScans(thisScan).Action,'Inplanes')
        InplaneDir=thisScan %take the last if several are set
    end
end
%get the anatomy
anatDir=[HOMEDIREC,filesep,foundScans(InplaneDir).DirName];
[anat, inplanes] = GetAnatomy(anatDir);
% %since cropping is anoying
inplanes.cropSize=inplanes.fullSize;
inplanes.crop=cat(1,[1 1],inplanes.fullSize);


%AnatomySize=size(anat);
% Save anat
anatFile = fullfile(HOMEDIREC, 'Inplane', 'anat.mat');
save(anatFile, 'anat', 'inplanes');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the functionals
functDirs=[];
for thisScan=1:length(foundScans)
    if strcmp(foundScans(thisScan).Action,'Functional')
        functDirs=cat(2,functDirs,thisScan); %take the last if several are set
    end
end

firstFunc= functDirs(1);
DicomFileBase=['E',inplanes.examNum];
scanParams = GetScanParamsDicom(HOMEDIREC,DicomFileBase,functDirs,foundScans(firstFunc).Volumes ,foundScans(firstFunc).Slices);


% put additonal info in here, so we don't have to do that later...
for thisScan=1:length(scanParams)
%     scanParams(thisScan).junkFirstFrames=foundScans(thisScan).SkipVols;
%     scanParams(thisScan).nFrames=foundScans(thisScan).Volumes-foundScans(thisScan).SkipVols;
    % *** SCN 02/02/07 - replaced above 2 lines, w/ 2 below.  foundScans has analyzeFile indexing
	 % *** + 2 more instance of similar problem below, w/ foundScans(xxx).Cycles
    scanParams(thisScan).junkFirstFrames=foundScans(functDirs(thisScan)).SkipVols;
    scanParams(thisScan).nFrames=foundScans(functDirs(thisScan)).Volumes-foundScans(functDirs(thisScan)).SkipVols;
    % %since cropping is anoying
    scanParams(thisScan).cropSize=scanParams(thisScan).fullSize;
    scanParams(thisScan).crop=cat(1,[1 1],scanParams(1).fullSize);
end


lastName=scanParams(1).lastName;
scanDate=scanParams(1).date;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create/load mrSESSION and dataTYPES, modify them, and save

% If mrSESSION already exits, load it.
sessionFile = fullfile(HOMEDIREC, 'mrSESSION.mat');
if exist(sessionFile, 'file')
    loadSession;
    % if docrop, make sure that the mrSESSION is up-to-date
    if doCrop
        mrSESSION.inplanes = inplanes;
        mrSESSION = UpdateSessionFunctionals(mrSESSION,scanParams);
        saveSession;
    end
end


% If we don't yet have a session structure, make a new one.
if (~exist('mrSESSION','var'))
    mrSESSION = CreateNewSession(HOMEDIREC, inplanes, mrLoadRetVERSION);
end

if isempty(mrSESSION)
    mrSESSION = CreateNewSession(HOMEDIREC, inplanes, mrLoadRetVERSION);
end

% Update mrSESSION.functionals with scanParams corresponding to any new Pfiles.
% Set mrSESSION.functionals(:).crop & cropSize fields
mrSESSION = UpdateSessionFunctionals(mrSESSION,scanParams,0);

% this lines replace then EditSession command. One gui-window less to bother
mrSESSION.description=SessionName;
mrSESSION.subject=subjectName;

saveSession;

% Create/edit dataTYPES
if isempty(dataTYPES)
    dataTYPES = CreateNewDataTypes(mrSESSION);
else
    dataTYPES = UpdateDataTypes(dataTYPES,mrSESSION);
end



% Save any changes that may have been made to mrSESSION & dataTYPES
saveSession;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extract time series 
mrVista('inplane');
v=getSelectedInplane;

% Create time series files
mrVista('inplane');
v=getSelectedInplane;
% GetAnalyzeRecon(dataDir,functHeader,rawFuncScans); % Set this fleg to 0 for no roation or 1 for 90 degrees of CW rotation.
% We can read in the Analyze format data files and write them out very quickly. Since we are not cropping, there is no reason
% to have a big complicated function here.
for thisScan=1:length(functDirs)
    analyzeNum=functDirs(thisScan);
    inFile=foundScans(analyzeNum).Filename4d;
    %make sure there is a .hdr at the end...
    [pathstr, name, ext, versn]=fileparts(inFile);
    inFile=[pathstr,filesep,name,'.hdr'];
    disp(inFile)
    volsToSkip=mrSESSION.functionals(thisScan).junkFirstFrames;
    scaleFact=[1];
    v=read4dAnalyzeToTseries(v,inFile,thisScan,volsToSkip,1,1,0);
end
for thisScan=1:length(dataTYPES(1).blockedAnalysisParams)
    dataTYPES(1).blockedAnalysisParams(thisScan).temporalNormalization=0; 
%     dataTYPES(1).blockedAnalysisParams(thisScan).nCycles=foundScans(thisScan).Cycles;
    dataTYPES(1).blockedAnalysisParams(thisScan).nCycles=foundScans(functDirs(thisScan)).Cycles;
    dataTYPES(1).eventAnalysisParams(thisScan).eventAnalysis=0;
end
saveSession;

newTypeNum = addDataType('FSL_prepro'); 
disp('Originals saved, now saving FSL_prepro');
dataTYPES(newTypeNum).scanParams=dataTYPES(1).scanParams;
dataTYPES(newTypeNum).blockedAnalysisParams=dataTYPES(1).blockedAnalysisParams;
dataTYPES(newTypeNum).eventAnalysisParams=dataTYPES(1).eventAnalysisParams;
v = selectDataType(v,newTypeNum);

for thisScan=1:length(functDirs)
    analyzeNum=functDirs(thisScan);
    inFile=foundScans(analyzeNum).lastfile;
    %make sure there is a .hdr at the end...
    [pathstr, name, ext, versn]=fileparts(inFile);
    inFile=[pathstr,filesep,name,'.hdr'];
    disp(inFile)
    volsToSkip=mrSESSION.functionals(thisScan).junkFirstFrames;
    scaleFact=[1];
    v=read4dAnalyzeToTseries(v,inFile,thisScan,volsToSkip,1,1,0);
end
for thisScan=1:length(dataTYPES(1).blockedAnalysisParams)
    dataTYPES(newTypeNum).blockedAnalysisParams(thisScan).temporalNormalization=0; 
%     dataTYPES(newTypeNum).blockedAnalysisParams(thisScan).nCycles=foundScans(thisScan).Cycles;
    dataTYPES(newTypeNum).blockedAnalysisParams(thisScan).nCycles=foundScans(functDirs(thisScan)).Cycles;
    dataTYPES(newTypeNum).eventAnalysisParams(thisScan).eventAnalysis=0;
end

saveSession;
clx;

status=1;














