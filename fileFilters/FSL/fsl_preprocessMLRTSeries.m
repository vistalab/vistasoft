function vw=fsl_preprocessMLRTSeries(vw,scansToProcess)
% PURPOSE: Does mcflirt (and one day slice time correction) on time series data in MLR
% See also fsl_runMelodicMLRTSeries
% ARW 120604
%
% Script to do FLIRT and MELODIC time series denoising on tSERIES data
% held in mlr.
% This routine is designed to be called from mlr (in the project directory)
% and so it requires mrSESSION
% In overview:
% All the FSL routines require a set of 3D analyze-format files or a single
% 4D analyze format file.
% 1: First stage is to convert all the tSeries into 4d analyze format.
% 2: Then feed those analyze files through flirt to do motion correction.
%   the resulting analyze files are called 'xxx_mcf'
% 3: Then feed those motion corrected files through melodic to generate the
%   ICA independent components
% A second script / function (fsl_filterICAComponents)
% Can then be used to reconstruct a new set of tSeries based on the
% pre-computed ICA components
% Note - we use read_avw and save_avw functions to do the reading and
% writing (instead of the spm functions).
% Remixed data sets are saved out to a new datatype RemixedOrig
mrGlobals;

thisDir=pwd;

fslBase='/raid/MRI/toolbox/FSL/fsl';
if (ispref('VISTA','fslBase'))
    disp('Settingn fslBase to the one specified in the VISTA matlab preferences:');
    fslBase=getPref('VISTA','fslBase');
    disp(fslBase);
end
fslPath=fullfile(fslBase,'bin'); % This is where FSL lives - should also be able to get this from a Matlab pref
reconPath='/raid/MRI/toolbox/Recon'; % required for the recon program to convert .mag files into Analyze format
dataDir=[thisDir,filesep,'Raw']; % The raw directory containing the e-files and .mag files
if (~exist('vw','var')  | (isempty(vw)))
    vw=getSelectedInplane;
end

if (vw.curDataType~=1)
    error('The data type must be Original (dataTYPE == 1)');
end
if (~exist('scansToProcess','var')  | (isempty(scansToProcess)))
    
    disp('Select scans to process');
    
    scansToProcess=selectScans(vw,'Scans to process');
end

nSlices=mrSESSION.inplanes.nSlices;
nScansToProcess=length(scansToProcess);

% Generate 4d Analyze files from the tSeries data.
for thisScanIndex=1:nScansToProcess
    
    thisScan=scansToProcess(thisScanIndex);
    cropSize=mrSESSION.functionals(thisScan).cropSize;
    nFrames=mrSESSION.functionals(thisScan).nFrames;
    
    dataBlock=zeros(cropSize(1),cropSize(2),nSlices,nFrames); % Pre-allocate a large data array
    
    for thisSlice=1:nSlices
        thistSeries = loadtSeries(vw,thisScan,thisSlice);
        % For historical reasons, tSeries come in as nFrames*(y*x)
        % So a 128*128 pixel by 72 frame data set for a single slice would
        % come out as size=72*16384
        % When we make the big data block, we need it to be
        % x*y*nSlices*nFrames
        ts=reshape(thistSeries',cropSize(1),cropSize(2),nFrames);
        dataBlock(:,:,thisSlice,:)=ts;
        fprintf('.');
    end
    fprintf('\nCreated data block %d\n',thisScan);
    
    % Now save that 4d avw file out somewhere...
    % We're going to create a subdirectory in the Inplane/xxxx/TSeries
    % folder
    avw_dirName=['Inplane/Original/TSeries/Scan',int2str(thisScan),'/Analyze'];
    if (~isdir(avw_dirName))
        fprintf('\nCreating directory %s\n',avw_dirName);
        mkdir(avw_dirName);
    end
    % And save it out...
    fName=[avw_dirName,filesep,'data'];
    voxSize=mrSESSION.functionals(1).effectiveResolution;
    dType='f';
    save_avw(dataBlock,fName,dType,voxSize);
    disp(thisScan);
end % Do the next one

% Now run motion correction

for thisScanIndex=1:nScansToProcess
    % This will align within scans
    thisScan=scansToProcess(thisScanIndex);
    avw_dirName=['Inplane/Original/TSeries/Scan',int2str(thisScan),'/Analyze'];
    fName=[avw_dirName,filesep,'data'];
    shellCmd=[fslPath,filesep,'mcflirt -in ',fName,' -stats -report -verbose 3'];
    disp(shellCmd);
    system(shellCmd);
    
end


return;
% Debugging stuff...
% Next we would like to compute the transform of the mean of each series to
% the T1 image. And then apply this xform to the 4d fMRI data so that they
% are in good alignment with the T1...
% The first step is to create an analyze image from anat.mat
% This means that the anatomy has to be loaded in the current view
vw=loadAnat(vw);
thisAnat=vw.anat;
% For consistnecy, use save_avw to save this to disk.
% This whole thing could be a function makeInplaneAnalyzeAnatomy...
adim=mrSESSION.inplanes.voxelSize;
anatfName='./Inplane/avw_anat';
save_avw(thisAnat,anatfName,'s',[adim(:);0]);
% That was fun. But generally we collect functional data at a lower
% resolution
% That means that we need to downsample anat to the size of the functional
nSlices=size(thisAnat,3);
loresAnat=zeros(size(thisAnat,1)/2,size(thisAnat,2)/2,nSlices);

for thisSlice=1:nSlices
    %a=decimateNd(thisAnat(:,:,thisSlice),2);
    loresAnat(:,:,thisSlice)=decimateNd(thisAnat(:,:,thisSlice),2);
end

loresAnatfName=[anatfName,'_lores'];
loresDim=adim(:).*[3; 3; 1];
save_avw(loresAnat,loresAnatfName,'s',[loresDim(:);0]);

% data...
% Now run BET on this to make a refweight
shellCmd=[fslPath,filesep,'bet ',loresAnatfName,' ',[loresAnatfName,'_bet']];%
disp(shellCmd);
tic;
system(shellCmd);
toc;
% Now... when we did the motion correction, we automatically saved out a
% file called
% data_mcf_meanvol for each function tSeries.
% We now want to loop through anduse FLIRT to generate a xform matrix to
% align each of these mean vols to the anatomy.
% Then... we run through again and APPLY this xform to the (4D) data_mcf
% datasets.
% Let's try and see how flirt does
for thisScanIndex=1:nScansToProcess
    thisScan=scansToProcess(thisScanIndex);
    avw_dirName=['Inplane/Original/TSeries/Scan',int2str(thisScan),'/Analyze'];
    fName=[avw_dirName,filesep,'data_mcf_meanvol'];
    shellCmd=[fslPath,filesep,'flirt  -in ',fName,' -ref ',loresAnatfName,' -out ',[fName,'_reg'],' -verbose 2  -dof 6 -searchrx -1 1 -searchry -1 1 -searchrz -1 1 -refweight ',[loresAnatfName,'_bet']];
    % searchrx -1 1 -searchry -1 1 -searchrz -1 1
    disp(shellCmd);
    tic;
    system(shellCmd);
    toc;
end

% Now run MELODIC
for thisScanIndex=1:nScansToProcess
    thisScan=scansToProcess(thisScanIndex);
    avw_dirName=['Inplane/Original/TSeries/Scan',int2str(thisScan),'/Analyze'];
    fName=[avw_dirName,filesep,'data_mcf'];
    shellCmd=[fslPath,filesep,'melodic -i ',fName,' --tr=3 --Omean --report --Ostats'];
    
    disp(shellCmd);
    tic;
    system(shellCmd);
    toc;
end

% Now run remixMLRByICAe
% example:
% remixMLRByICA('./Inplane/Original/TSeries/Scan1/Analyze/',1,80,10)
% Now re-convert remixed data
% Make the new data type and fill in the directories...
typeName='remixedOrig';
if ~existDataType(typeName), addDataType(typeName); end
vw = selectDataType(vw,existDataType(typeName));

% ----------------------
tSerDir=tSeriesDir(vw);
% The new dataType will be a clone of Original
% If we have remixed the tSeries for scan 'n' then
% we will place the remixed tSeries in the new dataTYPE
% and we will be able to compute a coranal for it.
% Otherwise, that scan will be empty in the new dataTYPE.

% We have to populate the dataTYPES structure with reasonable numbers
% even if the individual scans have no tSeries data
dataTYPES(vw.curDataType).scanParams=dataTYPES(1).scanParams;
dataTYPES(vw.curDataType).blockedAnalysisParams=dataTYPES(1).blockedAnalysisParams;
dataTYPES(vw.curDataType).eventAnalysisParams=dataTYPES(1).eventAnalysisParams;

for thisScanIndex=1:nScansToProcess
    
    thisScan=scansToProcess(thisScanIndex);
    avw_dirName=['Inplane',filesep,'Original',filesep,'TSeries',filesep,'Scan',int2str(thisScan),filesep,'Analyze'];
    fName=[avw_dirName,filesep,'remixed_data'];
    disp(fName);
    [img, dims,scales,bpp,endian]=read_avw(fName);
    
    % Make the tSeries directory if it doesn't already exist
    % Make the Scan subdirectory for the new tSeries (if it doesn't exist)
    scandir = fullfile(tSerDir,['Scan',num2str(thisScan)]);
    if ~exist(scandir,'dir')
        fprintf('\nMaking scan directory %s\n',scandir);
        mkdir(tSerDir,['Scan',num2str(thisScan)]);
    end
    
    thisTSerFull = [];
    dimNum = 0;
    
    for thisSlice=1:nSlices
        thisTSer=img(:,:,thisSlice,:);
        thisTSer=reshape(thisTSer,(dims(1)*dims(2)),dims(4));
        thisTSer=thisTSer';
        dimNum = numel(size(thisTSer));
        thisTSerFull = cat(dimNum + 1, thisTSerFull, thisTSer);
        disp(thisSlice);
    end
    
    if dimNum == 3
        thisTSerFull = reshape(thisTSerFull,[1,2,4,3]);
    end %if
    
    savetSeries(thisTSerFull,vw,thisScan);
    
end
