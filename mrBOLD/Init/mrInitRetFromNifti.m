function status=mrInitRetFromNifti(scan,subjectName,SessionName) %procScans,SessionName,subjectName)
% mrInitRetFromNifti - creates a MLR session out of SPM nifti files
%
%   status=mrInitRetFromNifti(foundScans,SessionName,subjectName)
% 
% modified from mrInitRetFromSPM

mrGlobals
HOMEDIREC = pwd;

doCrop=0;


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the inplane anatomies 
% We can read the volume siye from the header. Maybe other info as well.
% The inplane data should be in the dataPath named anat.hdr/img

InplaneDir=0;

% find the InplaneDir
for thisScan=1:length(scan)
    if (~isempty(scan(thisScan)))
        if strcmp(scan(thisScan).Action,'Inplanes')
            InplaneDir=thisScan; %take the last if several are set
        end
    end
end

%get the anatomy
%anatDir=[HOMEDIREC,filesep,procScans{InplaneDir}.DirName];
if (~InplaneDir)
    % Prompt for an analyze file that serves as an inplane ref
    [fname,pathname]=uigetfile('*.nii','Pick Analyze/Nifti format 3d file');
	 if isnumeric(fname)
		 % try again?
	    [fname,pathname]=uigetfile('*.nii','Pick Analyze/Nifti format 3d file');
		 if isnumeric(fname)
			 return
		 end
	 end
    fname=fullfile(pathname,fname);
else
    fname=[scan{InplaneDir}.Filename3d,'.nii'];
end

[anat, inplanes] = GetAnatomyFromAnalyze2(fname);

% since cropping is anoying
inplanes.cropSize=inplanes.fullSize;
inplanes.crop=cat(1,[1 1],inplanes.fullSize);

% Save anat
anatFile = fullfile(HOMEDIREC, 'Inplane', 'anat.mat');
save(anatFile, 'anat', 'inplanes');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the functionals
% functScans=[];
% for thisScan=1:length(procScans)
%     if (~isempty(procScans{thisScan}))
%         if strcmp(procScans{thisScan}.Action,'Functional')
%             functScans=cat(2,functScans,thisScan); %take the last if several are set
% 
%         end
%     end
% 
% end


% put information about the functionals here. 
% I tried to make this independent of the DICOM format but in the end I needed to get at least the TR from that header. 
% I know that the individual analyze vols should have the TR as the 4th
% dimension. Something to work on...

% loop over different scan directories
timesRot90 = 1;
for thisScan=1:numel(scan)
    Directory = fullfile(scan(thisScan).RawDir,scan(thisScan).DirName);
    files     = dir(fullfile(Directory,'*.nii'));
    
    % get header of the first 3D file
    scanParams(thisScan).hdr = spm_vol(fullfile(Directory,files(1).name));
    
    % imatrix decomposes the analyze (nifti) header into its components.
    scanParams(thisScan).imatrix  = spm_imatrix(scanParams(thisScan).hdr(1).mat);
    
    % dimensions
    scanParams(thisScan).fullSize = scanParams(thisScan).hdr(1).dim;
    if rem(timesRot90,2)
        scanParams(thisScan).fullSize = scanParams(thisScan).fullSize([2 1 3]);
    end
    
    if isempty(scan(thisScan).SkipVols), scan(thisScan).SkipVols = 0; end
    
    scanParams(thisScan).junkFirstFrames=scan(thisScan).SkipVols;
    
    scanParams(thisScan).nFrames=scan(thisScan).Volumes-scan(thisScan).SkipVols;
    % We don't crop these days. Perhaps we could get rid of that crop param
    % altogether?
    scanParams(thisScan).cropSize=scanParams(thisScan).fullSize(1:2);
    scanParams(thisScan).crop=cat(1,[1 1],scanParams(1).fullSize(1:2));
    
    % get TR form header (Donders Institute)
    scanParams(thisScan).TR = scan(thisScan).TR.*1000; % ms
    scanParams(thisScan).framePeriod=scanParams(thisScan).TR/1000; % this is in seconds
    
    scanParams(thisScan).PfileName = scan(thisScan).DirName;
    scanParams(thisScan).slices    = 1:scan(thisScan).Slices;
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

for thisScan=1:numel(scan)
    Directory = fullfile(scan(thisScan).RawDir,scan(thisScan).DirName);
    
    inFile    = dir(fullfile(Directory,'*.nii'));
    inFile    = strvcat(inFile(:).name);
    dirs      = char(ones(size(inFile,1),1)*double([Directory filesep]));
    inFile   = [dirs inFile];
    
    
    volsToSkip=mrSESSION.functionals(thisScan).junkFirstFrames;
    %scaleFact=[1];
    v=read3dAnalyzeToTseries(v,inFile,thisScan,volsToSkip,0,timesRot90,0); % No slice flip, 3 90 deg rotations

    dataTYPES(1).blockedAnalysisParams(thisScan).temporalNormalization=0; 
    dataTYPES(1).blockedAnalysisParams(thisScan).nCycles=scan(thisScan).Cycles;
    if isempty(dataTYPES(1).blockedAnalysisParams(thisScan).nCycles)
        dataTYPES(1).blockedAnalysisParams(thisScan).nCycles = 8;
    end
    dataTYPES(1).eventAnalysisParams(thisScan).eventAnalysis=0;
end
saveSession;

status=1;


