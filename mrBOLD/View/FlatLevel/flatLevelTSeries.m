function tMat = flatLevelTSeries(flat,scan,recomputeFlag);
% tMat = flatLevelTSeries(flat,[scan,recomputeFlag]);
%
% For Flat multi-level views:
% 
% Create a 4D array of size x by y by slices by time,
% with the values from the tSeries interpolated across
% the (unmasked) flat mesh for each slice/time point.
% Also compute the mean image across levels for each
% hemisphere/time point.
%
% flat: flat view
%
% tSeries: tSeries for the flat view. If not
% entered, gets it from the view.
%
% scan: number of scan for tSeries. Defaults to
% current scan.
%
% recomputeFlag: if 1, will recompute even if a saved 
% file already exists with the data. (Otherwise, will
% check and load existing files rather than recomputing.)
%
% Will also save a file 'interpolatedTSeries' in 
% the scan's tSeries directory with the 4D matrix,
% as well as the appropriate coords/indices for
% mapping back and forth between the measured
% points on the flat map (in the normal tSeries
% files) and the interpolated image (same format
% as anat/amp/co/ph/map).
%
% ras, 10/2004
tic

if ieNotDefined('scan')
    scan = getCurScan(flat);
end

if ieNotDefined('recomputeFlag')
    recomputeFlag = 0;
end

% params
imageSize = flat.ui.imSize;
nSlices = 2 + sum(flat.numLevels);
nFrames = numFrames(flat,scan);
numLevels = flat.numLevels;
mask = flat.ui.mask;
savePath = fullfile(tSeriesDir(flat),sprintf('Scan%i',scan),'interpolatedTSeries.mat');

% check if the file already exists
% -- if so, load it and skip the computation:
if recomputeFlag==0 & exist(savePath,'file')
    fprintf('Loading %s ...\n',savePath);
    load(savePath,'tMat');
    return
end

% combine coords across hemispheres,
% get indices for going the reverse direction
coords = flat.coords;
indices = flat.indices;

% initialize the 4D array -- if there are memory
% constraints, this will hopefully give a hint:
% tMat = zeros(imageSize(1),imageSize(2),nSlices,nFrames);

% (There are --- making it a uint16 to reduce the load):
for i = 1:nFrames
    tMat(:,:,:,i) = uint16(zeros(imageSize(1),imageSize(2),nSlices));
end

%% get the min and max value for uint8 scaling ;(
%minVal = min(tSeries(find(tSeries)))
%maxVal = max(tSeries(find(tSeries)))

skipSlices = [];

waitHandle = mrvWaitbar(0,'Computing mean tSeries across gray levels...');
set(waitHandle,'Units','Normalized');
pos = get(waitHandle,'Position');
set(waitHandle,'Position',pos+[0 .1 0 0]);

for slice = 1:nSlices
    % load the tSeries slice
    tData = loadtSeries(flat,scan,slice);

        % need to figure out the hemisphere for this slice
        if slice==1 | (slice>2 & slice<=2+numLevels(1))
            h = 1;
        else
            h = 2;
        end

        % get coordinates from this slice
        subCoords = coords{slice}(1:2,:);

    if size(subCoords,2) < 10
        skipSlices = [skipSlices slice];
    else

    
        % interpolate each frame in tMat
        sliceWait = mrvWaitbar(0,'Interpolating slice across frames...');
        for t = 1:nFrames
            vals = tData(t,:);

            % The operator .' is the NON-CONJUGATE transpose.  Very important.
            tMat(:,:,slice,t) = myGriddata(subCoords,vals.',mask(:,:,h));

            mrvWaitbar(t/nFrames,sliceWait);
        end
    close(sliceWait);

    end

    mrvWaitbar(slice/nSlices,waitHandle);
end

close(waitHandle);

% % remove skipped slices
% tMat = tMat(:,:,setdiff(1:nSlices,skipSlices),:);

% save the 4D matrix
save(savePath,'tMat','coords','indices'); %,'minVal','maxVal');
fprintf('Saved %s. \n',savePath);

toc

return



% % % if arg out is specified, sample
% % % the mean tSeries at the data points
% % % measured (specified in coords/indices):
%  if nargout > 0
%  	waitHandle = mrvWaitbar(0,'Grabbing the mean tSeries...');
%      
%  	for h = 1:2
%          % find coordinates of mean tSeries for this hemi
%          subCoords = find(coords(3,:)==h);
%          
%         % get the indices for measured points for this hemi
%         measured = indices(find(indices(:,:,h)));
%         
%         % error check: subCoords and measured should
%         % represent the same voxels:
%         [size(subCoords) size(measured)]
%         if size(subCoords)~=size(measured)
%             error('Logical error -- size mismatch b/w subCoords & measured.')
%         end
%         
%         % I'll attempt to do a (fast) one-shot re-indexing,
%         % across time, but this requires that the indices be 
%         % specified correctly. Replicate the 2D row/column
%         % specifications to run across frames, then get a 
%         % single index into the big 4D matrix:
%         [x y] = ind2sub([imageSize(1) imageSize(2)],measured);
%         x = repmat(x,[1 nFrames]);
%         y = repmat(y,[1 nFrames]);
%         z = repmat(h,size(x));
%         t = repmat(1:nFrames,[length(measured) 1])';
%         t = t(:);
%         subIndices = sub2ind(size(tMat),x,y,z,t);
%         
%         % assign the tSeries from the measured points
%         % (first convert back from uint8 to double)
%         subData = tMat(subIndices);
%         subData = minVal + maxVal .* double(subData);
%         tSeries(:,subCoords) = subData; % check for inaccuracies 
%         
%         mrvWaitbar(h/2,waitHandle);
%     end
%     
%     close(waitHandle);
% end


