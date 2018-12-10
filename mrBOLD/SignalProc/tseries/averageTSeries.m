function vw = averageTSeries(vw, scanList, typeName, annotation)
%
%  vw = averageTSeries(vw, [scanList], [typeName], [annotation])
%
% Average the time series scans specified in the parameter scanList.  The user determines
% the scans from a popup dialog box if scanListis not defined.
%
% Saves results in the 'Averages' data type with a new annotation.  It is
% possible to save in another dataType by specifying typeName.
%
% The optional 'annotation' argument specifies the annotation (the text
% that pops up for the scan in mrVista) for the scan. Default is to use
% the text 'Average of [data type] [scans] scans'.
%
% Uses the current dataType of the view to determine which tSeries
% to average.
%
% dbr,  3/99
% djh,  2/28/2001, Reimplemented for mrLoadRet-3.0
% arw,  08/28/02,  Added option to set new data type name.
% ras,  12/17/05,  Added optional new annotation.

mrGlobals

% default input args
if notDefined('typeName'),    typeName='Averages';             end
if notDefined('annotation'),
    annotation = sprintf('Average of %s scans: %s',  ...
        getDataTypeName(vw),  ...
        num2str(scanList));
end

if notDefined('scanList') || isequal(scanList, 'dialog')
    [scanList, typeName, annotation] = averageTSeriesGUI(vw, scanList, typeName, annotation);
end

checkScans(vw, scanList);

% Open a hidden vw and set its dataType to 'Averages'
switch viewGet(vw, 'View Type')
    case 'Inplane'
        hiddenView = initHiddenInplane;
    case 'Volume'
        hiddenView = initHiddenVolume;
    case 'Gray'
        hiddenView = initHiddenGray;
    case 'Flat'
        hiddenView = initHiddenFlat(viewGet(vw,'View Directory'));
end


% Set dataTYPES.scanParams so that new average scan has the same params as
% the 1st scan on scanList.
src = {viewGet(vw, 'curDataType') scanList(1)};
[hiddenView, newScanNum, ndataType] = initScan(hiddenView, typeName, [], src);
%dataTYPES(ndataType).scanParams(newScanNum).annotation = annotation;
dataTYPES(ndataType) = dtSet(dataTYPES(ndataType), 'Annotation', annotation, ...
    newScanNum);
hiddenView = selectDataType(hiddenView, typeName);

saveSession

% Get the tSeries directory for this dataType
% (make the directory if it doesn't already exist).
tseriesdir = tSeriesDir(hiddenView);

% Make the Scan subdirectory for the new tSeries (if it doesn't exist)
scandir = fullfile(tseriesdir, ['Scan', num2str(newScanNum)]);
if ~exist(scandir, 'dir')
    mkdir(tseriesdir, ['Scan', num2str(newScanNum)]);
end

% Double loop through slices and scans in scanList
nAvg = length(scanList);
% *** check that all scans have the same slices
nSlices = length(sliceList(vw, scanList(1)));
tSeriesAvgFull = []; %Initialize

% If it's INPLANE: get the whole tseries in one read
if strcmpi('INPLANE', viewGet(vw, 'view type'))
    for iAvg=1:nAvg
        iScan = scanList(iAvg);
        [~, nii] = loadtSeries(vw,  iScan);
        tSeries = double(niftiGet(nii, 'data'));
        
        dimNum = length(size(tSeries)); %Can handle 2 and 3D tSeries
        bad = isnan(tSeries);
        tSeries(bad) = 0;
        if iAvg > 1;
            tSeriesAvg = tSeriesAvg + tSeries;
            nValid = nValid + ~bad;
        else
            tSeriesAvg = tSeries;
            nValid = ~bad;
        end
    end
    tSeriesAvg = tSeriesAvg ./ nValid;
    tSeriesAvg(nValid == 0) = NaN;
    tSeriesAvgFull = cat(dimNum + 1, tSeriesAvgFull, tSeriesAvg); %Combine together
    
    % reshape to time x pixels x slice
    dims = viewGet(vw, 'data size');
    tSeriesAvgFull = reshape(tSeriesAvgFull, prod(dims(1:2)), dims(3), []);
    tSeriesAvgFull = permute(tSeriesAvgFull, [3 1 2]);
else    
    % If it's GRAY of FLAT...
    waitHandle = mrvWaitbar(0, 'Averaging tSeries.  Please wait...');
    for iSlice = sliceList(vw, scanList(1));
        % For each slice...
        % disp(['Averaging scans for slice ',  int2str(iSlice)])
        for iAvg=1:nAvg
            iScan = scanList(iAvg);
            tSeries = loadtSeries(vw,  iScan,  iSlice);
            dimNum = length(size(tSeries)); %Can handle 2 and 3D tSeries
            bad = isnan(tSeries);
            tSeries(bad) = 0;
            if iAvg > 1;
                tSeriesAvg = tSeriesAvg + tSeries;
                nValid = nValid + ~bad;
            else
                tSeriesAvg = tSeries;
                nValid = ~bad;
            end
        end
        tSeriesAvg = tSeriesAvg ./ nValid;
        tSeriesAvg(nValid == 0) = NaN;
        tSeriesAvgFull = cat(dimNum + 1, tSeriesAvgFull, tSeriesAvg); %Combine together
        mrvWaitbar(iSlice/nSlices);
    end %for
    
    close(waitHandle);

    % Now we need to reshape to have slices be the 3rd dimension. But only if we
    % have a total of 4 dimensions now, i.e. dimNum == 3
    
    if dimNum == 3
        tSeriesAvgFull = permute(tSeriesAvgFull,[1,2,4,3]);
    end %if
end


savetSeries(tSeriesAvgFull, hiddenView, newScanNum);

verbose = prefsVerboseCheck;  % only pop up if we prefer it
if verbose
    % This could be displayed more beautifully (turned off msgbox -ras)
    str = sprintf('Averaged tSeries saved with annotation: %s\n', annotation);
    str = [str, sprintf('Data are saved in %s data type\n', typeName)];
    % msgbox(str);
    disp(str)
end

% Loop through the open views,  switch their curDataType appropriately,
% and update the dataType popups
INPLANE = resetDataTypes(INPLANE, ndataType);
VOLUME  = resetDataTypes(VOLUME, ndataType);
FLAT    = resetDataTypes(FLAT, ndataType);

disp('Done Averaging tSeries.')

return;
% /-----------------------------------------------------------/ %




% /-----------------------------------------------------------/ %
function checkScans(vw, scanList)
%
% Check that all scans in scanList have the same slices,  numFrames,  cropSizes
for iscan = 2:length(scanList)
    if find(sliceList(vw, scanList(1)) ~= sliceList(vw, scanList(iscan)))
        myErrorDlg('Can not average these scans; they have different slices.');
    end
    if (viewGet(vw, 'numFrames', scanList(1)) ~= viewGet(vw, 'numFrames', scanList(iscan)))
        myErrorDlg('Can not average these scans; they have different numFrames.');
    end
    if find(viewGet(vw, 'sliceDims', scanList(1)) ~= viewGet(vw, 'sliceDims', scanList(iscan)))
        myErrorDlg('Can not average these scans; they have different cropSizes.');
    end
end
return;
% /-----------------------------------------------------------/ %




% /-----------------------------------------------------------/ %
function [scans, typeName, str] = averageTSeriesGUI(vw, scans, typeName, str)
% Dialog to get the scan selection and type name for averageTSeries
for ii = 1:viewGet(vw, 'numScans')
    scanList{ii} = sprintf('(%i) %s', ii, viewGet(vw, 'annotation', ii));
end

dlg(1).fieldName = 'scans';
dlg(end).style = 'listbox';
dlg(end).string = 'Average which scans together?';
dlg(end).list = scanList;
dlg(end).value = scans;

dlg(end+1).fieldName = 'typeName';
dlg(end).style = 'edit';
dlg(end).string = 'Name of new data type?';
dlg(end).value = typeName;

dlg(end+1).fieldName = 'annotation';
dlg(end).style = 'edit';
dlg(end).string = 'Annotation for average scan?';
dlg(end).value = str;

resp = generalDialog(dlg, 'Average Time Series');

[~, scans] = intersect(scanList, resp.scans);
typeName = resp.typeName;
str = resp.annotation;

return
