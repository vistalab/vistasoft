function view = motionCompMutualInfMeanInit(view,srcScans,ROI,baseScan,newDataType,currentDataType,rigid,nonLinear)

%    view = motionCompMutualInfMeanInf(view, [srcScans], [ROI], [baseScan], newDataType, currentDataType, [rigid], [nonLinear]); 
%
% gb 01/10/05
% 
% Runs the motion compensation algorithm. The arguments are set with the
% function motionCompSetArgs.
%
% Input arguments:
%
%       - view: current inplane
%       - srcScans: srcScans to which the user wants to apply the transformation
%       - ROI:  the region of interest used for the rigid motion correction
%               algorithm
%       - baseScan: reference scan. If it is not defined or equal to 0, the 
%                   anatomical data is taken as a reference.
%       - newDataType: name of the new data type name
%       - currentDataType: name of the data type the original images are taken from
%       - rigid: Indicates if the program calls the rigid transformation
%                algorithm. Default: 0
%       - nonLinear: Indicates if the program calls the non linear
%                    algorithm. Default: 0

% Initializes arguments and variables
tic

printLog = '';
h = mrvWaitbar(0,'Initializing...');

global dataTYPES HOMEDIR INPLANE

cd(HOMEDIR)

if notDefined('newDataType')
    newDataType = 'MotionCompMIMean';
end
printLog = [printLog 'Datatype: ' newDataType '\n'];

if notDefined('currentDataType')
    currentDataType = 'Original';
end
printLog = [printLog 'From datatype: ' currentDataType '\n'];

% Update the data type
change = 0;
for i = 1:length(dataTYPES)
    if isequal(dataTYPES(i).name,currentDataType)
        view = viewSet(view,'currentDataType',i);
        change = 1;
        break
    end
end
if change == 0
    error('The original dataType is not valid');
end

if notDefined('rigid')
    rigid = 0;
end

if notDefined('nonLinear')
    nonLinear = 0;
end

printLog = [printLog 'Tranformation: '];

if rigid
    printLog = [printLog 'Rigid Body'];
    if nonLinear
        printLog = [printLog ' + '];
    end
end

if nonLinear
    printLog = [printLog 'Non Linear\n'];
else
    printLog = [printLog '\n'];
end
    
if rigid
    printLog = [printLog 'Caution: A ROI called ''ROIdef'' excluding the zero values of this data set is defined.\n'];
end

if notDefined('ROI')
    ROI = '';
    printLog = [printLog 'No ROI defined\n'];
else
    printLog = [printLog 'ROI: (corners)\n'];
    for slice = 1:size(ROI,3)
        if sum(sum(ROI(:,:,slice))) ~= 0
            corner1 = min(find(ROI(:,:,slice))) - 1;
            x1 = floor(corner1/size(ROI,1) + 1);
            y1 = rem(corner1,size(ROI,1)) + 1;
            
            corner2 = max(find(ROI(:,:,slice))) - 1;
            x2 = floor(corner2/size(ROI,1) + 1);
            y2 = rem(corner2,size(ROI,1)) + 1;
            
            printLog = [printLog '  - Slice ' num2str(slice) ': (' num2str(x1) ',' num2str(y1)...
                    ') -> (' num2str(x2) ',' num2str(y2) ')\n'];
        end
    end
end

if notDefined('srcScans')
    srcScans = er_selectScans(view);
end

nScans = length(srcScans);
if nScans == 0
    msgbox('You must select at least one scan','No data');
    return
end

curDataType = viewGet(view,'currentDataType');

if notDefined('frames')
    frames = 1:numberFrames(view,srcScans(1));
end
nFrames = length(frames);
nSlices = numberSlices(view,srcScans(1));
nVoxels = prod(sliceDims(view,srcScans(1)));

% Checking for the homogeneity in the srcScans (same number of slices and same
% number of frames)

% Creates a reference image
if ~notDefined('baseScan') & (baseScan ~= 0)
    baseImage = squeeze(motionCompComputeMean(view, baseScan));
    printLog = [printLog 'Reference Image : Mean map of scan ' num2str(baseScan) '\n\n'];    
else
    baseImage = double(motionCompResampleAnatomy(view));
    baseImage = reshape(baseImage, [sliceDims(view,srcScans(1)) nSlices]);
    baseScan = 0;
    printLog = [printLog 'Reference Image : Anatomy\n\n'];
end

if rigid
    pathRoi = fullfile(roiDir(view),'ROIdef.mat');
    if exist(pathRoi,'file')
        ROIdef = motionCompGetROI(view,'ROIdef');
    else
        ROIdef = ones(size(baseImage));
    end
else
    ROIdef = '';
end

% Location of the tSeries which will be saved 
% (but which are now initialized below, ras 02/06)
saveDir = fullfile(viewGet(view,'subdir'),newDataType,'TSeries');

% if the reference image is the mean for a scan, copy it to the target
% data type
if exist('baseScan', 'var') & ~isempty(baseScan) & baseScan ~= 0
    groupScans(view, baseScan, newDataType);
end

view = viewSet(view,'currentDataType',curDataType);

% Runs the motion compensation algorithm scan after scan
for scanIndex = 1:nScans

    srcScan = srcScans(scanIndex);
    mrvWaitbar((scanIndex - 1)/nScans,h,['Motion compensation for scan ' num2str(srcScan)]);
    
    printLog = [printLog 'Scan ' num2str(srcScan) ':\n'];
    
    meanImage{srcScan} = motionCompComputeMean(view,srcScan);
    registeredImage{srcScan} = meanImage{srcScan};
    
    if srcScan == baseScan
        continue
    end
    
    tSeriesAllSlices = motionCompLoadImages(view, srcScan, frames);
          
    % Runs the motion compensation algorithm
    if rigid
        
        mrvWaitbar((scanIndex - 1)/nScans,h,['Motion compensation for scan ' num2str(srcScan) ': Rigid']);
        
        [coregRotMatrix, registeredImage{srcScan}, param] = ...
            motionCompMutualInf(view, registeredImage{srcScan}, baseImage, srcScan, ROI);
        
        printLog = [printLog 'Coregistration Matrix:'];
        for printCoreg = 1:length(coregRotMatrix)
            printLog = [printLog '\t' num2str(coregRotMatrix(printCoreg))];
        end
        printLog = [printLog '\n'];
        ROIdef(registeredImage{srcScan} == 0) = 0;
        
    end
    
    if nonLinear
        mrvWaitbar((scanIndex - 2/3)/nScans,h,['Motion compensation for scan ' num2str(srcScan) ': Non Linear']);
        [ux,uy,uz,err,registeredImage{srcScan}] = dtiDeformationFast2(baseImage,registeredImage{srcScan});
    end
    
    for frame = 1:nFrames

        mrvWaitbar((scanIndex - 1/3)/nScans + (frame - 1)/(6*nFrames*nScans),h,['Computing the transformation for frame ' num2str(frame)])
      
        currentImage = squeeze(tSeriesAllSlices(frame,:,:,:));
        
        if rigid
            currentImage = mrSPM_rotateFrame(currentImage, coregRotMatrix, param);
        end
        if nonLinear
            currentImage = motionCompApplyTransform(currentImage,ux,uy,uz);
        end
        tSeriesAllSlices(frame,:,:,:) = currentImage; 
    end
    
    mrvWaitbar((srcScan - 1/6)/nScans,h,'Saving the new time series...');
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Initialize a slot in the data type for the new scan, and  %
    % save out the time series                                  %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % init the slot (ras, 02/06)    
    src = {currentDataType srcScan};
    [view tgtScan] = initScan(view, newDataType, [], src);
    
    % Write the new time series
    scanDir = ['Scan' int2str(tgtScan)];
    fileDir = fullfile(saveDir, scanDir);
    
    if ~exist('fileDir','dir')
        mkdir(saveDir, scanDir)
    end
    
    myDisp(['Writing tSeries to ' fileDir]);

    for curSlice = 1:numberSlices(view);
        tSeries = uint16(tSeriesAllSlices(:,:,:,curSlice));
        tSeries = reshape(tSeries,[size(tSeries,1) (size(tSeries,2)*size(tSeries,3)) size(tSeries,4)]);
        fileName = ['tSeries',num2str(curSlice),'.mat'];
        filePath = fullfile(fileDir, fileName);
        save(filePath,'tSeries');
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    baseImageMeasure = shiftdim(baseImage,-1);
    if ~notDefined('ROI')
        printLog = [printLog '  ROI:\n'];
        
        origMeasure = motionCompMI(meanImage{srcScan},ROI,baseImageMeasure);
        finalMeasure = motionCompMI(registeredImage{srcScan},ROI,baseImageMeasure);
        printLog = [printLog '    - MI: ' num2str(origMeasure) ' -> ' num2str(finalMeasure) '\n'];
    
        origMeasure = motionCompMSE(meanImage{srcScan},ROI,baseImage);
        finalMeasure = motionCompMSE(registeredImage{srcScan},ROI,baseImage);
        printLog = [printLog '    - MSE: ' num2str(origMeasure) ' -> ' num2str(finalMeasure) '\n'];
    end
     
    printLog = [printLog '  Entire Volume:\n'];
    
    origMeasure = motionCompMI(meanImage{srcScan},ROIdef,baseImageMeasure);
    finalMeasure = motionCompMI(registeredImage{srcScan},ROIdef,baseImageMeasure);
    printLog = [printLog '    - MI: ' num2str(origMeasure) ' -> ' num2str(finalMeasure) '\n'];
    
    origMeasure = motionCompMSE(meanImage{srcScan},ROIdef,baseImage);
    finalMeasure = motionCompMSE(registeredImage{srcScan},ROIdef,baseImage);
    printLog = [printLog '    - MSE: ' num2str(origMeasure) ' -> ' num2str(finalMeasure) '\n\n'];
        
    clear tSeriesAllSlices;
end

% Try to collect information about the MI and MSE for the log
% (but don't crash if we fail)
mrvWaitbar(1,h,'Printing Log...')
try
    printLog = [printLog '\n\n *** Overall statistics between srcScans ***\n\n'];
    printLog = [printLog '  Entire Volume:\n'];
    printLog = [printLog '\t- MI:\n'];
    tabMI = motionCompMeanMI(registeredImage,ROIdef);
    printLog = [printLog motionCompPrintTab(tabMI) '\n\n'];

    printLog = [printLog '\t- MSE:\n'];
    tabMSE = motionCompMeanMSE(registeredImage,ROIdef);
    printLog = [printLog motionCompPrintTab(tabMSE) '\n\n'];


    printLog = [printLog 'Occipital Lobes:'];
    ROIocc = zeros([sliceDims(view,1) size(view.anat,3)]);
    ROIocc(88:95,37:44,16:18) = ones(8,8,3);
    ROIocc(88:95,61:68,16:18) = ones(8,8,3);

    printLog = [printLog '\t- MI:\n'];
    tabMI = motionCompMeanMI(registeredImage,ROIocc);
    printLog = [printLog motionCompPrintTab(tabMI) '\n\n'];

    printLog = [printLog '\t- MSE:\n'];
    tabMSE = motionCompMeanMSE(registeredImage,ROIocc);
    printLog = [printLog motionCompPrintTab(tabMSE) '\n\n'];
catch
    % let the user now, via a mrvWaitbar-a-gram
    mrvWaitbar(1, h, 'Error printing log. Moving on...');
    disp('Error printing log. Moving on...')
end

if (baseScan > 0)
    if (length(meanImage) < baseScan) || isempty(meanImage{baseScan})
        meanImage{baseScan} = baseImage;
    end
    
    if (length(registeredImage) < baseScan) || isempty(registeredImage{baseScan})
        referenceImage{baseScan} = baseImage;
    end
end   

try
    % Set parameter map
    meanPath = fullfile(pwd,'Inplane',currentDataType,'meanMap.mat');
    if ~exist(meanPath, 'file') & (length(meanImage) == numScans(view))
        view = computeMeanMap(view, 0, 1); % force compute
    end

    for i = 1:length(meanImage)
        meanImage{i} = squeeze(meanImage{i});
        registeredImage{i} = squeeze(registeredImage{i});
    end
catch
    disp('Failed to save mean map.')
end

% ras 04/06: commented this out b/c of a bug; it seems to be trying to 
% show the mean map, but wouldn't it just be easier to rerun
% computeMeanMap? I will probably delete/change this shortly...
% try
%     % Set parameter map
%     meanPath = fullfile(pwd,'Inplane',currentDataType,'meanMap.mat');
%     if ~exist(meanPath, 'file') & (length(meanImage) == numScans(view))
%         delete(meanPath);
%         view = setParameterMap(view,meanImage,'meanMap');
% 
%         % Save file
%         saveParameterMap(view);
%     end
% 
%     for i = 1:length(meanImage)
%         meanImage{i} = squeeze(meanImage{i});
%         registeredImage{i} = squeeze(registeredImage{i});
%     end
% catch
%     disp('Failed to save mean map.')
% end
% 
% 
% % Set parameter map
% if exist(fullfile(pwd,'Inplane',newDataType,'meanMap.mat'))
%     delete(fullfile(pwd,'Inplane',newDataType,'meanMap.mat'))
% end
%     
% view = setParameterMap(view,registeredImage,'meanMap');
%     
% % Save file
% saveParameterMap(view);

cd(dataDir(view))
fid = fopen('dataTypeLog.txt','w');
fwrite(fid,sprintf(printLog),'uchar');
fclose(fid);

if exist('ROI') & ~isempty('ROI')
    try, motionCompSaveROI(view, ROI, ['ROI_' newDataType]);
    catch, disp('Couldn''t save ROI');
    end
end

try
    if rigid
        motionCompSaveROI(view, ROIdef, 'ROIdef');
    end
end

%%%%%clean up
% Update the data types
mrGlobals
resetDataTypes(INPLANE);
resetDataTypes(VOLUME);
resetDataTypes(FLAT);

clear meanImage
clear registeredImage


cd(HOMEDIR)
close(h)
myDisp('Done!');
fprintf('The motion compensation algorithm took %d seconds',round(toc));

return
