function status=mrInitRetFromFSL_NIC(procScans,SessionName,subjectName)
%   status=mrInitRetFromFSL(foundScans,SessionName,subjectName)
%   creates a MLR session out of a mixture of Dicom and analyze files
%   this mixture is the result of the prepareUCSF script that preprocesses
%   the functional data from the UCSF scanner, but leaves the inplanes
%   as Dicom.
%   2006.04.20 Mark Schira (mark@ski.org) wrote it.
% 061407: ARW Modified it to use the new pipeline for processing data from
% the NIC.
% Found scans will contain a sparse list of processed scans that can be
% found in ./Reconned.
% The functional data will be in _4d.hdr files. The inplanes will be in a
% _3d file. There may be other data sets there (T1s etc taken during the
% same session). 
% First we will identify the inplane scans. Then we will do the
% functionals.

mrGlobals
HOMEDIREC = pwd;

doCrop=0;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the inplane anatomies 
% We can read the volume siye from the header. Maybe other info as well.
% The inplane data should be in the dataPath named anat.hdr/img

InplaneDir=0;
% find the InplaneDir
for thisScan=1:length(procScans)
    if (~isempty(procScans{thisScan}))
    if strcmp(procScans{thisScan}.Action,'Inplanes')
        InplaneDir=thisScan; %take the last if several are set
    end
    end
     
end
%get the anatomy
%anatDir=[HOMEDIREC,filesep,procScans{InplaneDir}.DirName];
if (~InplaneDir)
    % Prompt for an analyze file that serves as an inplane ref
    [fname,pathname]=uigetfile('*.nii','Pick Analyze/Nifti format 3d file');
    fname=fullfile(pathname,fname);
else
    fname=[procScans{InplaneDir}.Filename3d,'.nii'];
end

[anat, inplanes] = GetAnatomyFromAnalyze(fname);
% %since cropping is anoying
inplanes.cropSize=inplanes.fullSize;
inplanes.crop=cat(1,[1 1],inplanes.fullSize);

%AnatomySize=size(anat);
% Save anat
anatFile = fullfile(HOMEDIREC, 'Inplane', 'anat.mat');
save(anatFile, 'anat', 'inplanes');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the functionals
functScans=[];
for thisScan=1:length(procScans)
    if (~isempty(procScans{thisScan}))
        if strcmp(procScans{thisScan}.Action,'Functional')
            functScans=cat(2,functScans,thisScan); %take the last if several are set

        end
    end

end


% put information about the functionals here. I tried to make this independent of the DICOM format but in the end I needed to get at least the TR from that header. 
% I know that the individual analyze vols should have the TR as the 4th
% dimension. Something to work on...

for thisScan=1:length(functScans)
    scanParams(thisScan).hdr=spm_vol([procScans{functScans(thisScan)}.Filename4d,'.nii']);
    scanParams(thisScan).imatrix=spm_imatrix(scanParams(thisScan).hdr(1).mat); % imatrix decomposes the analyze (nifti) header into its components.
    scanParams(thisScan).fullSize=scanParams(thisScan).hdr(1).dim; %#ok<AGROW>
    
    scanParams(thisScan).junkFirstFrames=procScans{functScans(thisScan)}.SkipVols;
    scanParams(thisScan).nFrames=procScans{functScans(thisScan)}.Volumes-procScans{functScans(thisScan)}.SkipVols;
% We don't crop these days. Perhaps we could get rid of that crop param
% altogether?
    scanParams(thisScan).cropSize=scanParams(thisScan).fullSize(1:2);
    scanParams(thisScan).crop=cat(1,[1 1],scanParams(1).fullSize(1:2));
    scanParams(thisScan).TR=procScans{functScans(thisScan)}.hdr{1}.RepetitionTime;
    scanParams(thisScan).PfileName=procScans{functScans(thisScan)}.hdr{1}.SeriesNumber;
    scanParams(thisScan).framePeriod=scanParams(thisScan).TR/1000; % this is in seconds
    scanParams(thisScan).slices=1:procScans{functScans(thisScan)}.Slices;
	 scanParams(thisScan).effectiveResolution = abs(scanParams(thisScan).imatrix(7:9));		% voxel dimensions (mm)
end


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
if ieNotDefined('dataTYPES')
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



for thisScan=1:length(functScans)
    analyzeNum=functScans(thisScan);
    inFile=procScans{analyzeNum}.Filename4d; % This has a trailing .hdr part
    %make sure there is a .hdr at the end...
    [pathstr, name, ext, versn]=fileparts(inFile);
    inFile=[pathstr,filesep,name,'.hdr'];
    disp(inFile)
    volsToSkip=mrSESSION.functionals(thisScan).junkFirstFrames;
    scaleFact=[1];
    v=read4dAnalyzeToTseries(v,inFile,thisScan,volsToSkip,0,1,0); % No slice flip, 3 90 deg rotations
end

for thisScan=1:length(dataTYPES(1).blockedAnalysisParams)
    dataTYPES(1).blockedAnalysisParams(thisScan).temporalNormalization=0; 
    dataTYPES(1).blockedAnalysisParams(thisScan).nCycles=procScans{functScans(thisScan)}.Cycles;
    dataTYPES(1).eventAnalysisParams(thisScan).eventAnalysis=0;
end
saveSession;

status=1;


