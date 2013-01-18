function scan = rtGetFunctionals(magFile,junkFirstFrames,nFrames,nCycles,annotation);
%
% newScanNum = rtGetFunctionals(magFile,[junkFirstFrames],[nCycles],[annotation]);
%
% Extract tSeries from functional data, saving and
% returning updated mrVista global variables.
%
% ras 04/05.
mrGlobals
loadSession;

if ieNotDefined('sessDir')
    sessDir = pwd;
end

if ieNotDefined('junkFirstFrames')
    junkFirstFrames = 0;
end


if ieNotDefined('annotation')
    annotation = '(Pseudo-realtime Scan)';
end

[magDir, fName, ext] = fileparts(magFile);

%%%%%%%%%%
% Params %
%%%%%%%%%%
littleEndian = 1; % all files at the scanner shuld be little endian
rotFlag = 0;

if ieNotDefined('shifts')
    shifts = [0, 0];
    shiftFlag = 0;
else
    shiftFlag = 1;
end

% determine Endian Flag:
% (this depends on when the scan was run:
% scans run before 3/2005 at the Stanford
% Lucas Center use big-endian format; newer
% ones use little-endian format)
if littleEndian==1
    endianFlag = 'ieee-le';
else
    endianFlag = 'ieee-be';
end

% Set up directories:
parentDir = fullfile(sessDir, 'Inplane', 'Original');
tSeriesDir = fullfile(parentDir, 'TSeries');

if ~exist(fullfile(sessDir,'Inplane'),'dir')
    fprintf('\nMaking %s ...',fullfile(sessDir,'Inplane'));
    mkdir(sessDir,'Inplane');
    fprintf('Done.\n');
end

if ~exist(parentDir,'dir')
    fprintf('\nMaking %s ...',parentDir);
    mkdir(fullfile(sessDir,'Inplane'),'Original');
    fprintf('Done.\n');
end


if ~exist(tSeriesDir,'dir')
    fprintf('\nMaking tSeries directory %s... ',tSeriesDir);
    mkdir(parentDir,'TSeries');
    fprintf('Done.\n')
end

% get header info, set functional params in mrSESSION file
mrSESSION = UpdateSessionFunctionals(mrSESSION,rtReadEfileHeader(magFile));

% get new scan num
scan = length(mrSESSION.functionals);

% grab functional params for this scan
funcParams = mrSESSION.functionals(scan);

funcParams.junkFirstFrames = junkFirstFrames;

% if no crop, the first row may accidentally be set to 0
if isequal(funcParams.crop(1,:),[0 0])
    funcParams.crop(1,:) = [1 1];
end

pixelShifts = round(shifts./funcParams.voxelSize(1:2));
fprintf('Scan %i [%s]:\n',scan,magFile)
sName = ['Scan', int2str(scan)];
MakeDir(sName,tSeriesDir);
scanDir = fullfile(tSeriesDir, sName);

if isfield(funcParams,'cropSize')
    nRows = funcParams.cropSize(1);
    nCols = funcParams.cropSize(2);
else
    nRows = funcParams.fullSize(1);
    nCols = funcParams.fullSize(2);
end

% if the recon script is still writing the mag file,
% wait till it's done
testFile = fullfile(magDir,['Writing_' fName ext]);
if exist(testFile,'file')
    fprintf('Waiting for recon to finish on %s...\n',magFile);
    while exist(testFile,'file')
        % wait
    end
end

% We'll try and update the mean map as we go as well
mapPath = fullfile('Inplane','Original','meanMap.mat');
if exist(mapPath,'file')
    load(mapPath,'map','mapName');
else
    map = cell(1,scan);
    mapName = 'meanMap';
end
map{scan} = zeros(nRows,nCols,length(funcParams.slices));

for iSlice=1:length(funcParams.slices)
    % Slice loop:
    disp(['   slice ', int2str(funcParams.slices(iSlice))]);

    % Load fullsize images
    tSeries = LoadRecon(funcParams,magFile,iSlice,rotFlag,endianFlag);

    % Remove junk frames
    f0 = funcParams.junkFirstFrames+1;
    if ieNotDefined('nFrames')
        nFrames = size(tSeries,1) - f0 + 1;% funcParams.nFrames;
    end
    fEnd = f0 + nFrames - 1;
    mrSESSION.functionals(end).nFrames = nFrames;
    tSeries = tSeries(f0:f0+nFrames-1, :, :);

    % Shift
    if shiftFlag
        for iF=1:nFrames
            tSeries(iF, :, :) = shift(squeeze(tSeries(iF, :, :)), pixelShifts); 
        end
    end

    % Crop
    x0 = funcParams.crop(1, 1);
    xN = funcParams.crop(2, 1);
    y0 = funcParams.crop(1, 2);
    yN = funcParams.crop(2, 2);
    tSeries = tSeries(:, y0:yN, x0:xN);

    % Reshape to standard t-series shape
    tSeries = reshape(tSeries, nFrames, (yN-y0+1)*(xN-x0+1));

    % Save tSeries file
    tsName = sprintf('tSeries%i.mat', funcParams.slices(iSlice));
    tSeriesFile = fullfile(scanDir, tsName);
    save(tSeriesFile,'tSeries');

    % also update mean map
    map{scan}(:,:,iSlice) = reshape(mean(tSeries),[nRows nCols]);
end

% save mean map
save(mapPath,'map','mapName');
disp('Updated mean map for this scan.')

% add dataTYPES entry for this scan

dataTYPES(1).scanParams(scan) = rtScanParamsDefaults(scan,annotation);
dataTYPES(1).blockedAnalysisParams(scan) = rtBlockedAnalysisDefaults;
dataTYPES(1).blockedAnalysisParams(scan).nCycles = nCycles;
dataTYPES(1).eventAnalysisParams(scan) = er_defaultParams;

% Save the session
saveSession;

disp('Done Adding Scan!')

return
% /-----------------------------------------------------------------/ %



% /-----------------------------------------------------------------/ %
function params = rtBlockedAnalysisDefaults;
% Default values for the blocked analyses.
params.blockedAnalysis = 1;
params.detrend = 1;
params.inhomoCorrect = 1;
params.temporalNormalization = 0;
params.nCycles = 6;
return
% /-----------------------------------------------------------------/ %




% /-----------------------------------------------------------------/ %
function params = rtScanParamsDefaults(scan,annotation);
% Default scan parameters for a new scan.
global mrSESSION;
params.annotation = annotation;
params.nFrames = mrSESSION.functionals(scan).nFrames;
params.framePeriod = mrSESSION.functionals(scan).framePeriod;
params.slices = mrSESSION.functionals(scan).slices;
params.cropSize = mrSESSION.functionals(scan).cropSize;
params.PfileName = mrSESSION.functionals(scan).PfileName
params.parfile = '';
params.scanGroup = sprintf('Original: %i',scan);
return
