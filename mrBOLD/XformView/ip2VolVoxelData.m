function volData = ip2VolVoxelData(inplane,volume,roi);
%
% volData = ip2VolVoxelData(inplane,volume,roi);
%
% Problem: you want to look at tSeries ipData in the volume
% (not restricted ipData), but it's too memory-intensive:
% too many locations. You really only care about tSeries
% within a region of interest.
%
% Solution: this converts just those tSeries within your
% ROI into the volume, and saves in the voxel data directory
% for that session (see voxDataDir, er_voxelData). Also
% saves event-related info.
%
% ras, 06/06.
mrGlobals

if ieNotDefined('inplane')
    inplane = getSelectedInplane;
end

if isempty(inplane)
    inplane = initHiddenInplane;
    inplane = selectDataType(inplane,volume.curDataType);
    inplane = setCurScan(inplane,volume.curScan);
end

if ieNotDefined('roi')
    % dialog
    w = what(roiDir(volume)); 
    roiList = w.mat;
    for i = 1:length(roiList)
        roiList{i} = roiList{i}(1:end-4);
    end
    
    if volume.selectedROI > 0
        x = volume.selectedROI;
    else
        x = 1;
    end
    
    [sel, ok] = listdlg('PromptString','ROIs For Which to Xform Data?',...
        'ListSize',[400 600],'SelectionMode','multiple',...
        'ListString',roiList,'InitialValue',x,'OKString','OK');
    if ~ok  return;  end
    
    roi = roiList(sel);
    
    % check that they're all loaded
    for i = 1:length(roi)
        if findROI(volume,roi{i})==0
            volume = loadROI(volume,roi{i});
        end
    end
end

if iscell(roi) & length(roi)>1 
    % allow for many ROIs to be run, recursively:
    for i = 1:length(roi) 
        if nargout==1
            volData(i) = ip2VolVoxelData(inplane,volume,roi{i});
        else
            % the above may run out of memory
            ip2VolVoxelData(inplane,volume,roi{i});
        end
    end
    return
end

roi = tc_roiStruct(volume,roi);

nVoxels = size(roi.coords,2);

%%%%%%%%%%%%%%%%%%%%%%%%
% build inplane ROI:   %
%%%%%%%%%%%%%%%%%%%%%%%%
% the code for xforming ROI coords does supersampling,
% which doesn't guarantee that the volume and inplane
% ROIs will have corresponding columns. Since we want
% to guarantee grabbing the right location for each
% point in the volume ROI, re-do the xform, w/o supersampling:
ipRoi.name = roi.name;
ipRoi.color = roi.color;
xform = inv(mrSESSION.alignment);
ipCoords = round(xform*[roi.coords; ones(1,nVoxels)]);

% get only coords w/in inplanes
dims = viewGet(inplane,'Size');
c = ipCoords;
ok = find( c(1,:)>=1 & c(1,:)<=dims(1) & ...
            c(2,:)>=1 & c(2,:)<=dims(2) & ...
            c(3,:)>=1 & c(3,:)<=dims(3));
ipRoi.coords = ipCoords(1:3,ok);
ipRoi.viewType = 'Inplane';

% also need to select this ROI
inplane.selectedROI = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get inplane voxel data      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ipData = er_voxelData(inplane,ipRoi,[],[],1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% convert tSeries to volume:   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% init volData struct
volData.trials = ipData.trials;
volData.params = ipData.params;
volData.coords = roi.coords; 
volData.tSeries = zeros(size(ipData.tSeries,1),nVoxels);
volData.voxData = []; % will plug in later
volData.voxAmps = [];

% map:
volData.tSeries(:,ok) = ipData.tSeries;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Chop tSeries, calc amps:     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
volData.voxData = er_voxDataMatrix(volData.tSeries,volData.trials,volData.params);
volData.voxAmps = er_voxAmpsMatrix(volData.voxData,volData.params);


% save volData in the Volume voxel ipData dir
par = voxDataDir(volume);    % ensure a voxel ipData directory exists
savePath = fullfile(par,sprintf('%s-all.mat',roi.name));
tSeries = int16(volData.tSeries);
coords = volData.coords;
dataRange = [min(tSeries(:)) max(tSeries(:))];
voxData = volData.voxData;
voxAmps = volData.voxAmps;
trials = volData.trials;
params = volData.params;
save(savePath,'tSeries','coords','dataRange','voxData','voxAmps','trials','params');
fprintf('Saving concatenated volume ROI ipData in %s...\n',savePath);

return