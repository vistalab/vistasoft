function XlateFunctionals(x, scanList)

% XlateFunctionals(x[, scanList])
%
% Translates the functional images by the given amount x, a 3-vector in the
% inplane coordinates.
% Ress, 04/05.

mrGlobals

if isempty(selectedINPLANE)
    if isempty(INPLANE{1})
        Alert('Select an INPLANE!')
        return
    else
        selectedINPLANE = 1;
    end
end

view = INPLANE{selectedINPLANE};

M = [eye(3), -x(:)];

if ~exist('scanList', 'var')
    scanList = selectScans(view);
    if isempty(scanList), return, end
end

% Set up new datatype for the translated inplanes:
hiddenView = initHiddenInplane;
if (~exist('typeName', 'var') || isempty(typeName)), typeName = 'Translated'; end
if ~existDataType(typeName), addDataType(typeName); end
hiddenView = selectDataType(hiddenView, existDataType(typeName));
ndataType = hiddenView.curDataType;
tSeriesDir = tSeriesDir(hiddenView);

for scan = scanList
    slices = sliceList(view,scan);
    nSlices = length(slices);
    nFrames = numFrames(view,scan);
    dims = sliceDims(view,scan);
    % Load tSeries from all slices into one big matrix
    volSeries = zeros([dims(1) dims(2) nSlices nFrames]);
    waitHandle = mrvWaitbar(0,'Loading tSeries from all slices.  Please wait...');
    for slice=slices
        mrvWaitbar(slice/nSlices);
        ts = loadtSeries(view,scan,slice);
        for frame=1:nFrames
            volSeries(:, :, slice, frame) = reshape(ts(frame,:),dims);
        end
    end
    close(waitHandle)
    
    % compute the warped volume series according to M
    waitHandle = mrvWaitbar(0,['Warping scan ', num2str(scan),'...']);
    for frame = 1:nFrames
        mrvWaitbar(frame/nFrames)
        % warp the volume putting an edge of 1 voxel around to avoid lost data
        volSeries(:,:,:,frame) = warpAffine3(volSeries(:,:,:,frame), M, NaN, 1);
    end
    close(waitHandle)
    
    % Save warped tSeries
    % Make the Scan subdirectory for the new tSeries (if it doesn't exist)
    waitHandle = mrvWaitbar(0,'Saving tSeries...');

    savetSeries(volSeries, hiddenView, scan);

    close(waitHandle)
    clear volSeries
    
    dataTYPES(ndataType).scanParams(scan) = dataTYPES(view.curDataType).scanParams(scan);
    dataTYPES(ndataType).blockedAnalysisParams(scan) = dataTYPES(view.curDataType).blockedAnalysisParams(scan);
    dataTYPES(ndataType).eventAnalysisParams(scan) = dataTYPES(view.curDataType).eventAnalysisParams(scan);
    dataTYPES(ndataType).scanParams(scan).annotation = ['Translated ', getDataTypeName(view)];
end % Scan loop

hiddenView = computeMeanMap(hiddenView, scanList, 1);
saveSession;
