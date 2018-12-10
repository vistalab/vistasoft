function [vw, MM, newDtName] = betweenScanMotComp(vw, newDtName, baseScan, scansToCorrect)
%
% [vw, M, newDtName] = betweenScanMotComp(vw, newDtName, baseScan, scansToCorrect)
%
% Robust 3D rigid body motion compensation between MEAN MAPS of different scans
%
% If you change this function make parallel changes in:
%    motionComp, inplaneMotionComp

% Edit History:
% 06/06/00 - ON
% Ress, 06/05. Added some feedback on motion magnitude, and set 0.15 voxel
% threshold to perform correction. Removed "copy scan" function because we
% now make a new dataType.
% Ress, 06/06. Now returns scan motion as second argument.
% ras, 04/08: instead of taking a second vw argument, just takes the name
% of the new data type.
% ras, 07/09: doesn't force the motion-corrected scans to have the same
% scan numbers as the source data. E.g., if you correct scans [1 2 5 6],
% the data were saved in slots [1 2 5 6] of the new data type. Now they're
% saved in [1 2 3 4].

if notDefined('baseScan'),	baseScan = 1;		end

if notDefined('newDtName')
	def = { ['MotionComp_RefScan',int2str(baseScan)] }; 
	resp = inputdlg({'Save results in what data type?'}, mfilename, 1, def);
	newDtName = resp{1};
end
verbose = prefsVerboseCheck;

% Get or compute Mean Maps.
vw = loadMeanMap(vw);
meanMap = vw.map;

% if the number of slices is too small, repeat the first and last slice
% to avoid running out of data (the derivative computation discards the
% borders in z, typically 2 slices at the begining and 2 more at the end)
for scan = 1:length(meanMap)
    if size(meanMap{scan},3)<=8
        meanMap{scan} = cat(3, meanMap{scan}(:,:,1,:), meanMap{scan}(:,:,1,:), meanMap{scan},...
            meanMap{scan}(:,:,end,:), meanMap{scan}(:,:,end,:));
    end
end


% open file for writing
[fid, err] = fopen('Between_Scan_Motion.txt', 'w');
if fid <0
    error('error cannot open file: %s....\n', err);
end

% get base mean map
baseMeanMap = meanMap{baseScan};

%% create a hidden view on the new data type
if ~existDataType(newDtName), addDataType(newDtName); end
newView = initHiddenInplane(newDtName);

% Do motion estimation/compensation for each scan.
nScans = length(scansToCorrect);
MM = zeros(4, 4, nScans);
for iScan = 1:nScans
    scan = scansToCorrect(iScan);
    slices = sliceList(vw,scan);
    nSlices = length(slices);
    nFrames = numFrames(vw,scan);
    dims = viewGet(vw, 'sliceDims',scan);

    
    % Load tSeries from all slices into one big matrix
    [~, ni] = loadtSeries(vw, scan);
    volSeries = niftiGet(ni, 'data'); clear ni;

	if verbose > 1, close(waitHandle); end

    if scan == baseScan
        totalMot = 0;
    else
        % estimate motion between mean maps
        M = estMotionIter3(baseMeanMap,meanMap{scan},3,eye(4),1,1); % rigid body, ROBUST
        MM(:, :, iScan) = M;
        midX = [dims/2 nSlices/2]';
        midXp = M(1:3, 1:3) * midX; % Rotational motion
        rotMot = sqrt(sum((midXp - midX).^2));   
        transMot = sqrt(sum(M(1:3, 4).^2)); % Translational motion
        totalMot = sqrt(rotMot^2 + transMot^2);
        
        msg = sprintf('Scan %i - motion (voxels): rot = %2.1f; trans = %2.1f; total = %2.1f', ...
                      scan, rotMot, transMot, totalMot);
        disp(msg)
        fprintf(fid, '%s \n', msg);

    end

    if totalMot > 0.15
        % compute the warped volume series according to the previously computed M
		if verbose > 1
	        waitHandle = mrvWaitbar(0, ['Warping scan ' num2str(scan) '...']);
		end
        for frame = 1:nFrames
            if verbose > 1, mrvWaitbar(frame/nFrames);  end
            % warp the volume putting an edge of 1 voxel around to avoid lost data
            volSeries(:,:,:,frame) = warpAffine3(volSeries(:,:,:,frame), M, NaN, 1);
        end
		if verbose > 1
	        close(waitHandle)
		end
    end % motion correct

	% initialize a slot for the new time series
	[newView, newScanNum] = initScan(newView, newDtName, [], {vw.curDataType scan});
	
    % Save tSeries    
    numPixels = prod(viewGet(vw, 'slice dims'));
    tSeries = zeros(nFrames, numPixels);
    dimNum = numel(size(tSeries));
    tSeriesFull = zeros([size(tSeries) length(slices)]);
	if verbose > 1,    waitHandle = mrvWaitbar(0,'Saving tSeries...');	end
    for slice=slices
        if verbose > 1, mrvWaitbar(slice/nSlices);  end
        for frame=1:nFrames
            tSeries(frame, :) = reshape(volSeries(:,:,slice,frame), [1 numPixels]);
        end
        %tSeriesFull = cat(dimNum + 1, tSeriesFull, tSeries);
        tSeriesFull(:,:,slice) = tSeries;
    end %for

    if dimNum == 3
        tSeriesFull = reshape(tSeriesFull,[1,2,4,3]);
    end %if

    
    savetSeries(tSeriesFull, newView, newScanNum);
	if verbose > 1,     close(waitHandle);  end
    clear volSeries
	
	% remember the scans in the target data type which correspond to the
	% source scans
	targetScans(iScan) = newScanNum;
end % scan LOOP

fclose(fid);

%% A final step for event-related analyses: try to be smart about scan groups.
% If the source data has event-related scan groups assigned, check whether
% it makes sense to re-group the corresponding target scans. By default,
% the groups will point back to the original data types. We re-group only
% if the whole scan group was included in the motion-corrected data.
mrGlobals;
srcParams = dataTYPES(vw.curDataType).scanParams;
scanGroups = {srcParams.scanGroup};
if any( cellfind(scanGroups) )
	% we only care about scan groups pointing to the source data type.
	pattern = [getDataTypeName(vw) ':'];
	ok = strmatch(pattern, scanGroups);
	
	% for each OK scan, check whether the scan group was in the
	% set of adjusted scans. If so, update the scan group to reflect the
	% motion-corrected data.
	for ii = ok(:)'
		scans = er_getScanGroup(vw, scan);
		if all( ismember(scans, scansToCorrect) )
			% I group in the new vw, which points to the motion-corrected
			% data.
			I = find( ismember(scansToCorrect, scans) );
			er_groupScans(newView, targetScans(I), 2, newDtName);
		end
	end
end

return
