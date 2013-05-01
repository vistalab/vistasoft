function vw = spatialBlurTSeries(vw, scanList, kernelSize_mm, newTypeName)
% vw = spatialBlurTSeries(vw, scanList, kernelSize_mm, newTypeName)
%
% Performs spatial filtering on the time series data.
% Useful only in the inplane view.
%
% If 'dialog' is entered for the scanList argument, will pop up a dialog
% to get the parameters.
%
% Essentially an evil function that should be used only for fun. It's
% main use is for standardizing the sampling resolution across different
% sessions where the true voxel size changed for some reason.
%
% INPUTS:
% vw : mrVista view structure : default selectedInplane
% scanList : scans to filter : default all
% kernelSize_mm : FWHM of the kernel in mm : default 3mm. If a 3 element
% vector then sizes should be [x,y,z]: NOTE! Z (down the slices) is first
% newTypeName: default 'Blurred'
% ARW: 051804: Wrote it.
%
% Example:
%   spatialBlurTSeries(INPLANE{1},[1:2],3,'Blurred3mmAverages');
% .. then recompute the coranal in the new data type "Blurred3mmAverages"
%
% ras: 2005: added a dialog to get params. Don't think it's completely
% evil.

mrGlobals;

if (~exist('scanList','var') || isempty(scanList)), scanList = er_selectScans(vw); end
if (~exist('kernelSize_mm','var') || isempty(kernelSize_mm)), kernelSize_mm = 5; end
if (~exist('newTypeName','var') || isempty(newTypeName)), newTypeName='Blurred'; end

if isequal(lower(scanList), 'dialog')
    % pop up a dialog (or two)
    scanList = er_selectScans(vw, 'Select Scans to Spatially Blur');
    
    switch viewGet(vw, 'viewType')
        case 'Inplane'
            prompt={'Scan List:', 'Gaussian Kernel Size (mm):', ...
                'Name of New Data Type'};
            name='Input for Peaks function';
            defaults = {num2str(scanList), '3', 'Blurred3mm'};
        case 'Gray'
            prompt={'Scan List:', 'NumIterations Sigma:', ...
                'Name of New Data Type'};
            name='Input for Peaks function';
            defaults = {num2str(scanList), '9  0.5', 'dhkGraySmooth'};
    end
    resp = inputdlg(prompt,name, 1, defaults);
    scanList        = str2num(resp{1}); %#ok<*ST2NM>
    kernelSize_mm   = str2num(resp{2});
    newTypeName     = resp{3};
end

if ~existDataType(newTypeName), addDataType(newTypeName); end

origDataType=vw.curDataType;
srcDtName = dataTYPES(origDataType).name;


% if ~strcmp(vw.viewType,'Inplane')
%     error('This function only operates on inplane data');
% end

verbose = prefsVerboseCheck;

switch viewGet(vw, 'viewType')
    
    case 'Inplane'
        
        % Work out the size of the kernel we need in voxels
        % First find the effective voxel size:
        effectiveVoxSize_mm=mrSESSION.functionals(1).effectiveResolution(:);
        kernelSize_mm=kernelSize_mm(:);
        if (length(kernelSize_mm)~=3)
            kernelSize_mm=ones(3,1)*kernelSize_mm(1);
        end
        kernelRatio=kernelSize_mm./effectiveVoxSize_mm;
        support=kernelRatio*2;
        
        % Because we are going to have 'z' as the first dimension, rotate both
        % these vectors
        kernelRatio=kernelRatio([3 1 2]);
        support=support([3 1 2]);
        fprintf('\nKernel ratio=%d %d %d\n',kernelRatio(1),kernelRatio(2),kernelRatio(3));
        
        spatialFilter=gauss3d(support,kernelRatio);
        spatialFilter=spatialFilter./sum(spatialFilter(:));
        
        
        hiddenView = initHiddenInplane;
        
        
        % Pre-define a large matrix to hold all the data for a single scan
        % This will be nVoxels*nVoxels*nSlices*nTRs
        scanParams= dataTYPES(origDataType).scanParams(1);
        nx=scanParams.cropSize(1);
        ny=scanParams.cropSize(2);
        nSlices=length(scanParams.slices);
        
    case 'Gray'
        hiddenView = initHiddenGray;
end

hiddenView = selectDataType(hiddenView,existDataType(newTypeName));




for thisScan=1:length(scanList)
    
    % Initialize the new scan in dataTYPES.
    newScanNum = viewGet(hiddenView, 'num scans')+1;
    initScan(vw, newTypeName, newScanNum, {srcDtName scanList(thisScan)});
    
    switch viewGet(vw, 'viewType')
        case 'Inplane'
            nTR = viewGet(vw, 'NumFrames', scanList(thisScan));
            if verbose, disp('Allocating large matrix'); end
            dataArray=zeros(nTR,nx,ny,nSlices);
            
            
            % Get the tSeries directory for this dataType
            % (make the directory if it doesn't already exist).
            tseriesdir = tSeriesDir(hiddenView);
            
            % Make the Scan subdirectory for the new tSeries (if it doesn't exist)
            scandir = fullfile(tseriesdir,['Scan',num2str(newScanNum)]);
            if ~exist(scandir,'dir')
                mkdir(tseriesdir,['Scan',num2str(newScanNum)]);
            end
            
            
            % Load in the full data set for each scan
            % (nVoxelsx*nVoxelsy*nSlices*nTR)
            % Then loop through the TRs performing a spatial blur (convn) on the volume
            % at each time point.
            disp('Loading');
            for thisSlice=1:nSlices
                thisSliceData=loadtSeries(vw,scanList(thisScan),thisSlice); % Data come in as nTR*nVoxels
                dataArray(:,:,:,thisSlice)=reshape(thisSliceData,nTR,nx,ny);
            end
            
            % Now loop over TRs doing the convolution
            disp('Convolving');
            for thisTR=1:nTR
                dataArray(thisTR,:,:,:)=convn(dataArray(thisTR,:,:,:),spatialFilter,'same');
            end
            
            % Now loop over slices again, saving out the data
            disp('Saving');

            dataArray = permute(dataArray, [1 2 4 3]);
            
            savetSeries(dataArray,hiddenView,thisScan);
            
        case 'Gray'
            tSeries = loadtSeries(vw,scanList(thisScan));
            iterlambda = kernelSize_mm;
            tSeries = dhkGraySmooth(vw,tSeries,iterlambda);
            %This should be fine since we this is a 'gray' view
            savetSeries(tSeries, hiddenView,thisScan,1);
    end
    
    fprintf('\nDone scan %d\n',thisScan);
    
end % next scan


% Loop through the open views, switch their curDataType appropriately,
% and update the dataType popups
INPLANE = resetDataTypes(INPLANE);
VOLUME  = resetDataTypes(VOLUME);
FLAT    = resetDataTypes(FLAT);

% in the provided view, select the new data type
vw = selectDataType(vw, newTypeName);

return;
