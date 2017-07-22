function vw = computeCorrelation2ROIMap(vw, roi, scanList, dt)
%
% vw = computeCorrelation2ROIMap(vw, [roi], [scanList],[dt])
%
% Computes the correlation between the mean time series of an ROI across
% scans and the times series of each voxel.
% The mean of all pairwise correlations for each
% voxel is put into a parameter map and calls setParameterMap to set
% vw.map = ROICorrMap.
%
% Inputs:
%   vw: mrVista view struct
%   roi: roiname - this is the seed roi to which we want to calculate the
%   correlation to;
%   if the roi is not defined uses the selectedROI from the view structure
%   scanList:
%       0 - do all scans
%       number or list of numbers - do only those scans
%       default - prompt user via selectScans dialog
%   dt: datatype number to perform this calculation; if not defined will
%   use the current data type assigned to the view
%
%  kgs 7/2012

%-------------------------------------------------------------------------

if   exist('roi','var')
    [vw,ok]=loadROI(vw,roi);
else
    % get current roi from vw
    if vw.selectedROI==0
        display('Sorry you need to specify an ROI')
        return
    else
        roi=vw.ROIs(vw.selectedROI).name;
    end
end
if notDefined('scanList'),  scanList = selectScans(vw);           end
if isempty(scanList),         error('Analysis aborted');            end
if notDefined('dt'),     dt = viewGet(vw, 'curDataType'); end

if   notDefined('forceSave'), forceSave=1; end
if   notDefined('plotFlag'), plotFlag=1; end


%-------------------------------------------------------------------------
% initalize tc from ROI

% initialize to empty cell array
nScans = length(scanList);
map = cell(1,nScans);
% if you send an roi list
for s=1:nScans
    scan=scanList(s);
    dims = viewGet(vw, 'sliceDims', scan);
    nVoxels      = dims(1)*dims(2);
    slices       = sliceList(vw,scan);
    nFrames      = numFrames(vw, scan);
    detrend      = detrendFlag(vw,scan);
    smoothFrames = detrendFrames(vw,scan);
    tmp          = zeros(1, nVoxels);
    
    map{scan} =zeros(dataSize(vw,scan));
    
    
    %     tc = tc_init(vw, roi, scan,dt);   wholeTc=tc.wholeTc'
    [wholeTc] = meanTSeries(vw, scan, roi);
    if plotFlag==1        % plot tc if opton set
        figure('color',[ 1 1 1],  'Units', 'normalized', 'Position', [.1 .2 .6 .5],'name', [  roi ' scan ' num2str(scan)]);
        plot(wholeTc);axis('tight')
        xlabel('TRs')
        ylabel ('%signal')
    end
    
    msg = sprintf('Computing scan %d correlations.  Please wait.', scan);
    waitHandle = mrvWaitbar(0,msg);
    
    % loop through slices
    for slice = slices
        
        tSeriesAllVoxels = NaN*ones(nFrames, nVoxels);
        tSeries = loadtSeries(vw,scan,slice); % uses whatever dataType is assigned to the view
        tSeriesAllVoxels(:,:) = detrendTSeries(tSeries,detrend,smoothFrames);
        
        %calculate  corr between each voxel and the ROI tc for each scan
        rho=corr(tSeriesAllVoxels, wholeTc);
        
        % reshape
        map{scan}(:,:,slice) = reshape(rho,dims);
        mrvWaitbar(slice/length(slices))
    end % loop overslice
    
    close(waitHandle);
end % loop over scans

% Set parameter map
mapname=sprintf('%sCorrMap',roi);
vw = setParameterMap(vw,map,mapname);

% Save file

pathStr = fullfile(dataDir(vw), [mapname '.mat']) ;
saveParameterMap(vw, pathStr,forceSave);

return



