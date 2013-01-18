function fList = GetRecon(rawDir, fList, rotFlag, shifts, littleEndian)
% Reads recon data from Glover's recon files
%
%  fList = GetRecon(rawDir, fList, rotFlag, shifts, littleEndian)
%
% Output data are saved in Inplane directory under TSeries and optional
% complexTSeries subdirectories. 
% 
% rawDir:  Directory with the data
% fList:   0 means you need to find them all.  This should probably be
% empty, not 0
%
% rotFlag: Optional 90-degree rotation can be obtained by setting
%
% shifts:  Optional functional-image shift can also be obtained (to
%    deal with fallback errors or otherwise) by specifying a
%    2D shifts vector. Format is [yShift, xShift] in mm. Positive
%    shifts are to the right and upward.
%
% littleEndian:  Byte format
%
% Returns the list of selected Pfiles.  This may be a subset of all the
% Pfiles.
%
% DBR 8/00
%
% djh & dbr, 7/18/02, Fixed major bug in shifting. It was shifting
% only some of the images because of confusion about junkframes.
% kgs 08/04: added rotFlag
% ras 12/04: added scanList
% ras 03/05: added littleEndian (for scanner upgrade), got 
% rid of obsolete compFlag

global mrSESSION HOMEDIR

if isempty(mrSESSION),    load mrSESSION;                       end
if isempty(HOMEDIR),     HOMEDIR = pwd;                         end
if notDefined('rawDir'), rawDir = fullfile(HOMEDIR, 'Raw');     end
if notDefined('littleEndian'),    littleEndian = 1;             end
if notDefined('rotFlag'),     rotFlag = 0;                      end
if notDefined('shifts')
    shifts = [0, 0];
    shiftFlag = 0;
else
    shiftFlag = 1;
end

rawDir = fullfile(rawDir,'Pfiles');

% User selects Pfiles:
if notDefined('fList') || fList==0
    pFileList = SelectPfiles(mrSESSION.functionals);
    fList = find(pFileList);
end

% Set up directories:
parentDir = fullfile(HOMEDIR, 'Inplane', 'Original');
tSeriesDir = fullfile(parentDir, 'TSeries');

if ~exist(tSeriesDir,'dir')
    fprintf('\ntSeries directory %s does not exist.\n',tSeriesDir);
    mkdir(tSeriesDir);
end

if fList==0, fList = 1:length(mrSESSION.functionals); end

% determine byte format (Endian Flag)
% (this depends on when the scan was run: scans run before 3/2005 at the
% Stanford Lucas Center use big-endian format; newer ones use little-endian
% format)
if littleEndian==1,     endianFlag = 'ieee-le';
else                   endianFlag = 'ieee-be';
end

nScans = length(fList);
for iScan=1:nScans
    % Scan loop:
    scan = fList(iScan);
    scanParams = mrSESSION.functionals(scan);
    
    % if no crop, the first row may accidentally be set to 0
    if isequal(scanParams.crop(1,:),[0 0])
        scanParams.crop(1,:) = [1 1];
    end
    
    pixelShifts = round(shifts./scanParams.voxelSize(1:2));
    % check whether scanParams.PfileName is absolute path   
    if isempty(fileparts(scanParams.PfileName))
        fName = fullfile(rawDir, scanParams.PfileName);
    else
        fName = scanParams.PfileName;
    end
    
    disp(['Scan ', int2str(scan), ' [', fName, ']'])
    % sName = ['Scan', int2str(scan)];
    % We assign the output name based on how many we recon, not how many
    % possible Pfiles we could have reconned.
    sName = ['Scan', int2str(iScan)];
    MakeDir(sName,tSeriesDir);
    scanDir = fullfile(tSeriesDir, sName);
    
%     if isfield(scanParams,'cropSize')
%         nRows = scanParams.cropSize(1);
%         nCols = scanParams.cropSize(2);
%     else
%         nRows = scanParams.fullSize(1);
%         nCols = scanParams.fullSize(2);
%     end
    
    for iSlice=1:length(scanParams.slices)
        % Slice loop:
        disp(['   slice ', int2str(scanParams.slices(iSlice))]);
        
        % Load fullsize images
        tSeries = LoadRecon(scanParams,fName,iSlice,rotFlag,endianFlag);
        
        % Remove junk frames
        f0 = scanParams.junkFirstFrames+1;
        nFrames = scanParams.nFrames;
        fEnd = f0 + nFrames - 1;
        tSeries = tSeries(f0:fEnd, :, :);
        
        % Shift
        if shiftFlag
            for iF=1:nFrames
                tSeries(iF, :, :) = shift(squeeze(tSeries(iF, :, :)), pixelShifts); 
            end
        end
        
        % Crop
        x0 = scanParams.crop(1, 1);
        xN = scanParams.crop(2, 1);
        y0 = scanParams.crop(1, 2);
        yN = scanParams.crop(2, 2);
        tSeries = tSeries(:, y0:yN, x0:xN);
        
        % Reshape to standard t-series shape
        tSeries = reshape(tSeries, nFrames, (yN-y0+1)*(xN-x0+1)); %#ok<NASGU>
        
        % Save tSeries file
        tsName = ['tSeries', int2str(scanParams.slices(iSlice))];
        tSeriesFile = fullfile(scanDir, tsName);
        save(tSeriesFile,'tSeries');
    end
end
