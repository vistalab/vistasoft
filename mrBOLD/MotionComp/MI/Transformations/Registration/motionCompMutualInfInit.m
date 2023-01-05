function view = motionCompMutualInfInit(view,scans,frames,baseScan,baseFrame)

%    view = motionCompMutualInf(view, [scans], [frames], [baseScan], [baseFrame]); 
%
% gb 01/10/05
% 
% Runs the motion compensation algorithm based on mutual information

% Initializes arguments and variables
tic
global dataTYPES HOMEDIR INPLANE

if ieNotDefined('scans')
    scans = selectScans(view);
end

nScans = length(scans);
if nScans == 0
    msgbox('You must select at least one scan','No data');
    return
end

curDataType = viewGet(view,'currentDataType');

if ieNotDefined('frames')
    frames = 1:dataTYPES(curDataType).scanParams(scans(1)).nFrames;
end
nFrames = length(frames);
nSlices = length(dataTYPES(curDataType).scanParams(scans(1)).slices);
nVoxels = prod(dataTYPES(curDataType).scanParams(scans(1)).cropSize);

% Checking for the homogeneity in the scans (same number of slices and same
% number of frames)

for scanNum = scans(2:end)
    if dataTYPES(curDataType).scanParams(scanNum).slices ~= nSlices
        msgbox('The number of slices in the scans should be the same. Remove some scans.','Remove scans');
        return
    end
    
    if dataTYPES(curDataType).scanParams(scanNum).nFrames ~= nFrames
        msgbox('The number of frames in the scans should be the same. Remove some scans.','Remove scans');
        return
    end
    
    if prod(dataTYPES(curDataType).scanParams(scanNum).cropSize) ~= nVoxels
        msgbox('The number of voxels in the scans should be the same. Remove some scans.','Remove scans');
        return
    end
end

% Creates a reference image
if ~ieNotDefined('baseScan') & ~ieNotDefined('baseFrame')
    baseImage = motionCompLoadImages(view, baseScan, baseFrame);
else
    baseImage = motionCompMeanImage(view, scans);
end

% Creates a new data type if needed
datadir = dataDir(view);
if ~existDataType('MotionCompMI')
    duplicateDataType(view,'MotionCompMI');
    
    dir = viewGet(view,'subdir');
    subDir = dataTYPES(curDataType).name;
    
    source = fullfile(HOMEDIR,dir,subDir,'TSeries');
    destination = fullfile(HOMEDIR,dir,'MotionCompMI','TSeries');
    
    fprintf('Copying files.... This may take several minutes. \nPlease wait... ');
    copyfile(source,destination);
    fprintf('Done\n');
    
    path(path)
end
saveDir = fullfile(viewGet(view,'subdir'),'MotionCompMI','TSeries');

% Runs the motion compensation algorithm scan after scan
view = viewSet(view,'currentDataType',curDataType);
for scanIndex = 1:nScans
    scanNum = scans(scanIndex);

    tSeriesAllSlices = motionCompLoadImages(view, scanNum, frames);
    
    % Runs the motion compensation algorithm
    [coregRotMatrix, tSeriesAllSlices] = motionCompMutualInf(view, tSeriesAllSlices, baseImage, scanNum);
   
    % Writes the new time series
    scanDir = ['Scan',int2str(scanNum)];
    fileDir = fullfile(saveDir,scanDir);
    
    if ~exist('fileDir','dir')
        mkdir(saveDir,scanDir)
    end
    
    myDisp(['Write tSeries to ' fileDir]);

    for curSlice = dataTYPES(viewGet(view,'curdatatype')).scanParams(scanNum).slices;
        tSeries = tSeriesAllSlices(:,:,curSlice);
        fileName = ['tSeries',num2str(curSlice),'.mat'];
        filePath = fullfile(fileDir, fileName);
        save(filePath,'tSeries');
    end

end

% Update the data type
for i = 1:length(dataTYPES)
    if isequal(dataTYPES(i).name,'MotionCompMI')
        view = viewSet(view,'currentDataType',i);
        break
    end
end

myDisp('Done!');
fprintf('The motion compensation algorithm took %d seconds',round(toc));