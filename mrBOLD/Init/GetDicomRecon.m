function GetDicomRecon(rawDir,sessionName, functionalDirs,rotFlag)
% GetDicomRecon(rawDir, sessionName, rotFlag )
%
% Recons data (say from UCSF China Basin scanner) 
% stored in DICOM format. Uses Matlab's build in DICOM reader
% together with some other mlr routines to read the DICOM format images.
% Assumes the following:
% Images are stored in the following order: 
% 1: Localizers
% 2: Inplanes
% 3:end:  functional data
% 
% The functional data directories have a lot of DICOM images in them - one
% per slice per TR
% So for 17 slices, 160TRs you have 2720 separate images.
% The strategy here is to just read them in to one big block
% (for each scan) then write them out using saveTseries

% Output data is saved in Inplane directory
% under TSeries 
% Optional 90-degree rotation can be obtained by setting
% input rotFlag.
% Based on GetRecon by Ress and Heeger
% ARW 043004 : Wrote it
% Example: GetDicomRecon('RawDicom','E572',0);
% Note: Gets list of subdirs to recon from mrSESSION.functionals(scan)
% which has already been filled in. 
% Raw DICOM images from UCSF have the format
% [sessioName,'S',int2str(scanNum),'I',int2str(imageNum),'.DCM']

global mrSESSION HOMEDIR

if isempty(mrSESSION), load mrSESSION; end
if isempty(HOMEDIR), HOMEDIR = pwd; end
if isempty(rawDir), rawDir = fullfile(HOMEDIR, 'RawDicom'); end

if ~exist('rotFlag', 'var'), rotFlag = 0; end

% User selects Pfiles:
list = functionalDirs;



% Set up directories:

parentDir = fullfile(HOMEDIR, 'Inplane', 'Original');
tSeriesDir = fullfile(parentDir, 'TSeries');

if ~exist(tSeriesDir,'dir')
    fprintf('\ntSeries directory %s does not exist: Creating...\n ',tSeriesDir)
    mkdir(tSeriesDir);
end

nScans = length(list);
wbString=sprintf('Processing %d scans',nScans);

h=mrvWaitbar(0,wbString);

for iScan=1:nScans
    % Scan loop:
    scan = list(iScan);
    scanParams = mrSESSION.functionals(iScan);
    
    %disp(['Scan ', int2str(iScan), ' [', fName, ']'])
    sName = ['Scan', int2str(iScan)];
    MakeDir(sName,tSeriesDir);
    scanDir = fullfile(tSeriesDir, sName);
    
    % Check the crop size
    if isfield(scanParams,'cropSize')
        nRows = scanParams.cropSize(1);
        nCols = scanParams.cropSize(2);
    else
        nRows = scanParams.fullSize(1);
        nCols = scanParams.fullSize(2);
    end
    
    nFrames=scanParams.nFrames;
    nRows=scanParams.fullSize(1);
    nColumns=scanParams.fullSize(2);
    nSlices=length(scanParams.slices);
    junkFirstFrames=scanParams.junkFirstFrames;
    
    % Allocate the array
    disp('Allocating tSeriesArray');
    tSeriesArray=zeros(nFrames,nRows,nColumns,nSlices);
    tSeriesArrayCropped=zeros(nFrames,scanParams.cropSize(1),scanParams.cropSize(2),nSlices);
    
    imageNum=1+junkFirstFrames*nSlices;
    
    fprintf('\nReading %d frames\n',nFrames);
    for thisTR=1:(nFrames)
        
        for thisSlice=1:length(scanParams.slices)
            fileName=[sessionName,'S',int2str(scan),'I',int2str(imageNum),'.DCM'];
            filePath = fullfile(rawDir, int2str(scan),fileName);
            % Read in this image
            %disp(filePath);
            
            im=dicomread(filePath);
            
            
            % Crop
            x0 = scanParams.crop(1, 1);
            xN = scanParams.crop(2, 1);
            y0 = scanParams.crop(1, 2);
            yN = scanParams.crop(2, 2);
            im = im(y0:yN, x0:xN);
            
            tSeriesArrayCropped(thisTR,:,:,thisSlice)=im;
            % Go on to the next image
            imageNum=imageNum+1;
            
        end % Next slice
    end % next TR
    % Now loop through the array again, saving out tSeries plane by plane
    
    disp('Saving..');
    for thisSlice=1:length(scanParams.slices)
        
        
        % Reshape to standard t-series shape
        tSeries = reshape(tSeriesArrayCropped(:,:,:,thisSlice),nFrames,(yN-y0+1)*(xN-x0+1));
        
        % Save tSeries file
        tsName = ['tSeries', int2str(scanParams.slices(thisSlice))];
        tSeriesFile = fullfile(scanDir, tsName);
        save(tSeriesFile,'tSeries');
    end % next slice
    mrvWaitbar(iScan/nScans,h);
    
end % next scan

close(h);
