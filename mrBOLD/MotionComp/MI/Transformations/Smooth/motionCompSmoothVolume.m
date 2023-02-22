function tSeriesAllSlices = motionCompSmoothVolume(view)
%
% Computes a smoothing to the current data type of the inplane view.
% This was used to visualize the effects of smoothing on the GLM 
%
mat = [1.7188         0         0 -100.5469
         0    1.7188         0  -85.9375
         0         0    3.0000  -40.5000
         0         0         0    1.0000];
     
scale = 0.0232;

param = struct('mat',mat,'scale',scale);

global dataTYPES
newDataType = 'Smooth1';

if ~existDataType(newDataType)
    duplicateDataType(view,newDataType);
end
for i = 1:length(dataTYPES)
    if strcmp(dataTYPES(i).name,newDataType)
        newType = i;
        break
    end
end

for scan = 1:6
    scan
    view = viewSet(view,'currentdatatype',1);
    tSeriesAllSlices = motionCompLoadImages(view,scan);
    for i=1:size(tSeriesAllSlices,1)
        tSeriesAllSlices(i,:,:,:) = mrSPM_rotateFrame(squeeze(tSeriesAllSlices(i,:,:,:)),...
            [0.02 0.02 0.02 0.0001 0.0001 0.0001],param);
        i
    end
    
    view = viewSet(view,'currentdatatype',newType);
    
    scanDir = ['Scan',int2str(scan)];
    saveDir = fullfile(viewGet(view,'subdir'),newDataType,'TSeries');
    fileDir = fullfile(saveDir,scanDir);
    
    if ~exist('fileDir','dir')
        mkdir(saveDir,scanDir)
    end
    
    myDisp(['Write tSeries to ' fileDir]);

    for curSlice = dataTYPES(viewGet(view,'curdatatype')).scanParams(scan).slices;
        tSeries = uint16(tSeriesAllSlices(:,:,:,curSlice));
        tSeries = reshape(tSeries,[size(tSeries,1) prod(sliceDims(view,1))]);
        fileName = ['tSeries',num2str(curSlice),'.mat'];
        filePath = fullfile(fileDir, fileName);
        save(filePath,'tSeries');
    end
    
    
end